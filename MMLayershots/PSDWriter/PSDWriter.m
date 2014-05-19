//
//  PSDWriter.m
//  PSDWriter
//
//  Created by Ben Gotow on 5/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PSDWriter.h"
#import "NSDataPSDAdditions.h"
#import "PSDLayer.h"

@interface PSDWriter()
@property (nonatomic, assign) CGContextRef flattenedContext;
@end

@implementation PSDWriter

- (id)init
{
    self = [super init];
    if (self){
        self.layerChannelCount = 4;
        self.shouldFlipLayerData = NO;
        self.shouldUnpremultiplyLayerData = NO;
        self.flattenedContext = NULL;
        self.flattenedData = nil;
        self.layers = [[NSMutableArray alloc] init];
    }
    return self;    
}

- (id)initWithDocumentSize:(CGSize)s
{
    self = [self init];
    if (self){
        self.documentSize = s;
    }
    return self;
}

- (void)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name andOpacity:(float)opacity andOffset:(CGPoint)offset
{
    PSDLayer * l = [[PSDLayer alloc] init];
    CGRect imageRegion = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
    CGRect screenRegion = CGRectMake(offset.x, offset.y, imageRegion.size.width, imageRegion.size.height);
    CGRect drawRegion = CGRectMake(offset.x, offset.y, imageRegion.size.width, imageRegion.size.height);
    
    if (screenRegion.origin.x + screenRegion.size.width > self.documentSize.width)
        imageRegion.size.width = screenRegion.size.width = self.documentSize.width - screenRegion.origin.x;
    if (screenRegion.origin.y + screenRegion.size.height > self.documentSize.height)
        imageRegion.size.height = screenRegion.size.height = self.documentSize.height - screenRegion.origin.y;
    if (screenRegion.origin.x < 0) {
        imageRegion.origin.x = abs(screenRegion.origin.x);
        screenRegion.origin.x = 0;
        screenRegion.size.width = imageRegion.size.width = imageRegion.size.width - imageRegion.origin.x;
    }
    if (screenRegion.origin.y < 0) {
        imageRegion.origin.y = abs(screenRegion.origin.y);
        screenRegion.origin.y = 0;
        screenRegion.size.height = imageRegion.size.height = imageRegion.size.height - imageRegion.origin.y;
    }
    
    [l setImageData: CGImageGetData(image, imageRegion)];
    [l setOpacity: opacity];
    [l setRect: screenRegion];
    [l setName: name];
    [self.layers addObject: l];
    
    if (self.flattenedData == nil) {
        if ((self.documentSize.width == 0) || (self.documentSize.height == 0))
            @throw [NSException exceptionWithName:NSGenericException reason:@"You must specify a non-zero documentSize before calling addLayer:" userInfo:nil];

        if (self.flattenedContext == NULL) {
            self.flattenedContext = CGBitmapContextCreate(NULL, self.documentSize.width, self.documentSize.height, 8, 0, CGImageGetColorSpace(image), kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
            CGContextSetRGBFillColor(self.flattenedContext, 1, 1, 1, 1);
            CGContextFillRect(self.flattenedContext, CGRectMake(0, 0, self.documentSize.width, self.documentSize.height));
        }   
        drawRegion.origin.y = self.documentSize.height - (drawRegion.origin.y + drawRegion.size.height);
        CGContextSetAlpha(self.flattenedContext, opacity);
        CGContextDrawImage(self.flattenedContext, drawRegion, image);
        CGContextSetAlpha(self.flattenedContext, opacity);
    }
}
    
/* Generates an NSData object representing a PSD image. LayerData should contain an array of NSData
 objects representing the RGBA layer data (8 bits per component) and a width and height of size. 
 flatData should contain the RGBA data of a single image made by flattening all of the layers. */

- (void)dealloc
{
    if (self.flattenedContext != NULL) {
        CGContextRelease(self.flattenedContext);
        self.flattenedContext = nil;
    }
}

- (void)preprocess
{	
    // do we have a flattenedContext that needs to become flattenedData?
    if (self.flattenedData == nil) {
        if (self.flattenedContext) {
            CGImageRef i = CGBitmapContextCreateImage(self.flattenedContext);
            self.flattenedData = CGImageGetData(i, CGRectMake(0, 0, self.documentSize.width, self.documentSize.height));
            CGImageRelease(i);
        }
    }
    if (self.flattenedContext) {
        CGContextRelease(self.flattenedContext);
        self.flattenedContext = nil;

    }
    
	if ((self.shouldFlipLayerData == NO) && (self.shouldUnpremultiplyLayerData == NO))
		return;
	
    for (PSDLayer * layer in self.layers)
	{
        NSData *d = [layer imageData];
        
		// sketchy? yes. fast? oh yes.
		UInt8 *data = (UInt8 *)[d bytes];
		unsigned long length = [d length];
		
		if (self.shouldUnpremultiplyLayerData) {
			// perform unpremultiplication
			for(long i = 0; i < length; i+=4) {
				float a = ((float)data[(i + 3)]) / 255.0;
				data[(i+0)] = (int) fmax(0, fmin((float)data[(i+0)] / a, 255));
				data[(i+1)] = (int) fmax(0, fmin((float)data[(i+1)] / a, 255));
				data[(i+2)] = (int) fmax(0, fmin((float)data[(i+2)] / a, 255));
			}
		}
		
		if (self.shouldFlipLayerData) {
			// perform flip over vertical axis
			for (int x = 0; x < self.documentSize.width; x++) {
				for (int y = 0; y < self.documentSize.height/2; y++) {
					int top_index = (x+y*self.documentSize.width) * 4;
					int bottom_index = (x+(self.documentSize.height-y-1)*self.documentSize.width) * 4;
					char saved;
					
					for (int a = 0; a < 4; a++) {
						saved = data[top_index+a];
						data[top_index+a] = data[bottom_index+a];
						data[bottom_index+a] = saved;
					}
				}
			}
		}
	}
}

- (NSData *)createPSDData
{
	char signature8BPS[4] = {'8','B','P','S'};
	char signature8BIM[4] = {'8','B','I','M'};
	
	NSMutableData *result = [NSMutableData data];
	
	// make sure the user has provided everything we need
	if ((self.layerChannelCount < 3) || ([self.layers count] == 0))
        @throw [NSException exceptionWithName:NSGenericException reason:@"Please provide layer data, flattened data and set layer channel count to at least 3." userInfo:nil];

	
	// modify the input data if necessary
	[self preprocess];
	
	// FILE HEADER SECTION
	// -----------------------------------------------------------------------------------------------
	// write the signature
	[result appendBytes:&signature8BPS length:4];
	
	// write the version number
	[result appendValue:1 withLength:2];
	
	// write reserved blank space
	[result appendValue:0 withLength:6];
	
	// write number of channels
	[result appendValue:self.layerChannelCount withLength:2];
	
	// write height then width of the image in pixels
	[result appendValue:self.documentSize.height withLength:4];
	[result appendValue:self.documentSize.width withLength:4];
	
	// write number of bits per channel
	[result appendValue:8 withLength:2];
	
	// write color mode (3 = RGB)
	[result appendValue:3 withLength:2];
	
	// COLOR MODE DATA SECTION
	// -----------------------------------------------------------------------------------------------
	// write color mode data section
	[result appendValue:0 withLength:4];
	
	// IMAGE RESOURCES SECTION
	// -----------------------------------------------------------------------------------------------
	// write images resources section. This is used to store things like current layer.
	NSMutableData *imageResources = [[NSMutableData alloc] init];
	
	/*
	 // Naming the alpha channels isn't necessary, but here's how:
	 // Apparently those bytes contain 2 pascal strings? I think the last one is zero chars.
	 [imageResources appendBytes:&signature8BIM length:4];
	 [imageResources appendValue:1006 withLength:2];
	 [imageResources appendValue:0 withLength:2];
	 [imageResources appendValue:19 withLength:4];
	 Byte nameBytes[20] = {0x0C,0x54,0x72,0x61,0x6E,0x73,0x70,0x61,0x72,0x65,0x6E,0x63,0x79,0x05,0x45,0x78,0x74,0x72,0x61,0x00};
	 [imageResources appendBytes:&nameBytes length:20];
	 */
	
	// write the resolutionInfo structure. Don't have the definition for this, so we 
	// have to just paste in the right bytes.
	[imageResources appendBytes:&signature8BIM length:4];
	[imageResources appendValue:1005 withLength:2];
	[imageResources appendValue:0 withLength:2];
	[imageResources appendValue:16 withLength:4];
	Byte resBytes[16] = {0x00, 0x48, 0x00, 0x00,0x00,0x01,0x00,0x01,0x00,0x48,0x00,0x00,0x00,0x01,0x00,0x01};
	[imageResources appendBytes:&resBytes length:16];
	
	// write the current layer structure
	[imageResources appendBytes:&signature8BIM length:4];
	[imageResources appendValue:1024 withLength:2];
	[imageResources appendValue:0 withLength:2];
	[imageResources appendValue:2 withLength:4];
	[imageResources appendValue:0 withLength:2]; // current layer = 0
	
	[result appendValue:[imageResources length] withLength:4];
	[result appendData:imageResources];
	
	// This is for later when we write the transparent top and bottom of the shape
	int transparentRowSize = sizeof(Byte) * (int)ceilf(self.documentSize.width * 4);
	Byte *transparentRow = malloc(transparentRowSize);
	memset(transparentRow, 0, transparentRowSize);
	
	NSData *transparentRowData = [NSData dataWithBytesNoCopy:transparentRow length:transparentRowSize freeWhenDone:NO];
	NSData *packedTransparentRowData = [transparentRowData packedBitsForRange:NSMakeRange(0, transparentRowSize) skip:4];
	
	// LAYER + MASK INFORMATION SECTION
	// -----------------------------------------------------------------------------------------------
	// layer and mask information section. contains basic data about each layer (its mask, its channels,
	// its layer effects, its annotations, transparency layers, wtf tons of shit.) We need to actually
	// create this.

	@autoreleasepool {
        NSMutableData *layerInfo = [[NSMutableData alloc] init];
        NSMutableArray *layerChannels = [NSMutableArray array];
        NSUInteger layerCount = [self.layers count];
        
        // write the layer count
        [layerInfo appendValue:layerCount withLength:2];
        for (int layer = 0; layer < layerCount; layer++)
        {
            @autoreleasepool {
                NSData *imageData = [[self.layers objectAtIndex:0] imageData];
                CGRect bounds = [(PSDLayer*)[self.layers objectAtIndex:0] rect];
                bounds.origin.x = floorf(bounds.origin.x);
                bounds.origin.y = floorf(bounds.origin.y);
                bounds.size.width = floorf(bounds.size.width);
                bounds.size.height = floorf(bounds.size.height);
                
                // Check the bounds
                if (bounds.origin.x < 0 || bounds.origin.y < 0) {
                    @throw [NSException exceptionWithName:@"LayerOutOfBounds"
                                                   reason:[NSString stringWithFormat:@"Layer %i's x or y origin is negative, which is unsupported", layer]
                                                 userInfo:nil];
                }
                if (bounds.origin.x + bounds.size.width > self.documentSize.width ||
                    bounds.origin.y + bounds.size.height > self.documentSize.height) {
                    @throw [NSException exceptionWithName:@"LayerOutOfBounds"
                                                   reason:[NSString stringWithFormat:@"Layer %i's bottom-right corner is beyond the edge of the canvas, which is unsupported", layer]
                                                 userInfo:nil];
                }
                
                int imageRowBytes = bounds.size.width * 4;
                
                // too much padding is going on here
                
                NSRange leftPackRange = NSMakeRange(0, (int)bounds.origin.x * 4);
                NSData *packedLeftOfShape = [transparentRowData packedBitsForRange:leftPackRange skip:4];
                NSRange rightPackRange = NSMakeRange(0, (int)(self.documentSize.width - bounds.origin.x - bounds.size.width) * 4);
                NSData *packedRightOfShape = [transparentRowData packedBitsForRange:rightPackRange skip:4];
                
                for (int channel = 0; channel < self.layerChannelCount; channel++)
                {
                    NSMutableData *byteCounts = [[NSMutableData alloc] initWithCapacity:self.documentSize.height * self.layerChannelCount * 2];
                    NSMutableData *scanlines = [[NSMutableData alloc] init];
                    
                    for (int row = 0; row < self.documentSize.height; row++)
                    {
                        // If it's above or below the shape's bounds, just write black with 0-alpha
                        if (row < (int)bounds.origin.y || row >= (int)(bounds.origin.y + bounds.size.height)) {
                            [byteCounts appendValue:[packedTransparentRowData length] withLength:2];
                            [scanlines appendData:packedTransparentRowData];
                        } else {
                            int byteCount = 0;
                            
                            if (bounds.origin.x > 0.01) {
                                // Append the transparent portion to the left of the shape
                                [scanlines appendData:packedLeftOfShape];
                                byteCount += [packedLeftOfShape length];
                            }
                            
                            NSRange packRange = NSMakeRange((row - (int)bounds.origin.y) * imageRowBytes + channel, imageRowBytes);
                            NSData *packed = [imageData packedBitsForRange:packRange skip:4];
                            [scanlines appendData:packed];
                            byteCount += [packed length];
                            
                            if (bounds.origin.x + bounds.size.width < self.documentSize.width) {
                                // Append the transparent portion to the right of the shape
                                [scanlines appendData:packedRightOfShape];
                                byteCount += [packedRightOfShape length];
                            }
                            
                            [byteCounts appendValue:byteCount withLength:2];
                        }
                    }
                    NSMutableData *channelData = [[NSMutableData alloc] init];
                    // write channel compression format
                    [channelData appendValue:1 withLength:2];
                    // write channel byte counts
                    [channelData appendData:byteCounts];
                    // write channel scanlines
                    [channelData appendData:scanlines];
                    
                    // add completed channel data to channels array
                    [layerChannels addObject:channelData];
                }
                
                // print out top left bottom right 4x4
                [layerInfo appendValue:0 withLength:4];
                [layerInfo appendValue:0 withLength:4];
                [layerInfo appendValue:self.documentSize.height withLength:4];
                [layerInfo appendValue:self.documentSize.width withLength:4];
                
                // print out number of channels in the layer
                [layerInfo appendValue:self.layerChannelCount withLength:2];
                
                // print out data about each channel
                for (int c = 0; c < 3; c++) {
                    [layerInfo appendValue:c withLength:2];
                    [layerInfo appendValue:[[layerChannels objectAtIndex:c + layer * 4] length] withLength:4];
                }
                
                // for some reason, the alpha channel is number -1, not 3...
                Byte b[2] = {0xFF, 0xFF};
                [layerInfo appendBytes:&b length:2];
                [layerInfo appendValue:[[layerChannels objectAtIndex:3 + layer * 4] length] withLength:4];
                
                // print out blend mode signature
                [layerInfo appendBytes:&signature8BIM length:4];
                
                // print out blend type
                char blendModeKey[4] = {'n','o','r','m'};
                [layerInfo appendBytes:&blendModeKey length:4];
                
                // print out opacity
                int opacity = ceilf([[self.layers objectAtIndex:0] opacity] * 255.0f);
                [layerInfo appendValue:opacity withLength:1];
                
                // print out clipping
                [layerInfo appendValue:0 withLength:1];
                
                // print out flags. I think we're making the layer invisible
                [layerInfo appendValue:1 withLength:1];
                [layerInfo appendValue:0 withLength:1];
                
                // print out extra data length
                [layerInfo appendValue:4+4+16 withLength:4];
                
                // print out extra data (mask info, layer name)
                [layerInfo appendValue:0 withLength:4];
                [layerInfo appendValue:0 withLength:4];
                //		char layerName[15] = {'L','a','y','e','r','s',' ','P','S','D',' ','1','2','3','4'};
                //		[layerInfo appendValue:15 withLength:1];
                //		[layerInfo appendBytes:&layerName length:15];
                
                //		NSString *layerNameString = [[layerNames objectAtIndex:layer] stringByAppendingString:@" "];
                //		[layerNameString getCString:layerName maxLength:15 encoding:NSStringEncodingConversionAllowLossy];
                
                NSString *layerName = [[[self.layers objectAtIndex:0] name] stringByAppendingString:@" "];
                layerName = [layerName stringByPaddingToLength:15 withString:@" " startingAtIndex:0];
                const char *layerNameCString = [layerName cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
                [layerInfo appendValue:[layerName length] withLength:1];
                [layerInfo appendBytes:layerNameCString length:[layerName length]];
                
                [self.layers removeObjectAtIndex:0];
            }
        }
        
        free(transparentRow);
        
        // write the channel image data for each layer
        while([layerChannels count] > 0) {
            [layerInfo appendData:[layerChannels objectAtIndex:0]];
            [layerChannels removeObjectAtIndex:0];
        }

        // round to length divisible by 2.
        if ([layerInfo length] % 2 != 0)
            [layerInfo appendValue:0 withLength:1];
        
        // write length of layer and mask information section
        [result appendValue:[layerInfo length]+4 withLength:4];
        
        // write length of layer info
        [result appendValue:[layerInfo length] withLength:4];
        
        // write out actual layer info
        [result appendData:layerInfo];
    }
	
	// This should be required. I'm not sure why it works without it.
	// write out empty global layer section (globalLayerMaskLength == 0)
	// [self writeValue:0 toData:result withLength:4];
	
	// IMAGE DATA SECTION
	// -----------------------------------------------------------------------------------------------
	// write compression format = 1 = RLE
	[result appendValue:1 withLength:2];
	
	// With RLE compression, the image data starts with the byte counts for all of the scan lines (rows * channels)
	// with each count stored as a 2-byte value. The RLE compressed data follows with each scan line compressed
	// separately. Same as the TIFF standard.
	
	// in 512x512 image w/ no alpha, there are 3072 scan line bytes. At 2 bytes each, that means 1536 byte counts.
	// 1536 = 512 rows * three channels.
	
	NSMutableData *byteCounts = [NSMutableData dataWithCapacity:self.documentSize.height * self.layerChannelCount * 2];
	NSMutableData *scanlines = [NSMutableData data];
	
	int imageRowBytes = self.documentSize.width * 4;
	
	for (int channel = 0; channel < self.layerChannelCount; channel++) {
        @autoreleasepool {
            for (int row = 0; row < self.documentSize.height; row++) {
                NSRange packRange = NSMakeRange(row * imageRowBytes + channel, imageRowBytes);
                NSData * packed = [self.flattenedData packedBitsForRange:packRange skip:4];
                [byteCounts appendValue:[packed length] withLength:2];
                [scanlines appendData:packed];
            }
        }
	}
	
	// chop off the image data from the original file
	[result appendData:byteCounts];
	[result appendData:scanlines];
	
	return result;
}

@end


NSData *CGImageGetData(CGImageRef image, CGRect region)
{
	// Create the bitmap context
	CGContextRef	context = NULL;
	void *			bitmapData;
	int				bitmapByteCount;
	int				bitmapBytesPerRow;
	
	// Get image width, height. We'll use the entire image.
	int width = region.size.width;
	int height = region.size.height;
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow = (width * 4);
	bitmapByteCount	= (bitmapBytesPerRow * height);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	//	bitmapData = malloc(bitmapByteCount);
	bitmapData = calloc(width * height * 4, sizeof(Byte));
	if (bitmapData == NULL)
	{
		return nil;
	}
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	//	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
	context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow,
									colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	//	CGColorSpaceRelease(colorspace);
	
	if (context == NULL)
		// error creating context
		return nil;
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextSaveGState(context);
	
	//	CGContextTranslateCTM(context, -region.origin.x, -region.origin.y);
	//	CGContextDrawImage(context, region, image);
	
	// Draw the image without scaling it to fit the region
	CGRect drawRegion;
	drawRegion.origin = CGPointZero;
	drawRegion.size.width = CGImageGetWidth(image);
	drawRegion.size.height = CGImageGetHeight(image);
	CGContextTranslateCTM(context,
						  -region.origin.x + (drawRegion.size.width - region.size.width),
						  -region.origin.y - (drawRegion.size.height - region.size.height));
	CGContextDrawImage(context, drawRegion, image);
	CGContextRestoreGState(context);
	
	// When finished, release the context
	CGContextRelease(context);
	
	// Now we can get a pointer to the image data associated with the bitmap context.
	
	NSData *data = [NSData dataWithBytes:bitmapData length:bitmapByteCount];
	free(bitmapData);
	
	return data;
}
