//
//  MMLayershots.m
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 16/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "MMLayershots.h"
#import "CALayer+MMLayershots.h"
#import "PSDWriter.h"

static MMLayershots *_sharedInstance;

@interface MMLayershots()
@property (nonatomic, strong) NSMutableArray *layers;
@end

@interface UIWindow()
+ (NSArray *)allWindowsIncludingInternalWindows:(BOOL)a onlyVisibleWindows:(BOOL)v forScreen:(UIScreen *)s;
@end

@implementation MMLayershots

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [MMLayershots new];
    });
    return _sharedInstance;
}

- (void)setDelegate:(id<MMLayershotsDelegate>)delegate {
    if (_delegate && !delegate) {
        [self unregisterNotification];
    } else if (!_delegate && delegate) {
        [self registerNotification];
    }
    _delegate = delegate;
}

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}

- (void)unregisterNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    self.delegate = nil;
}

- (void)userDidTakeScreenshot {
    if ([self.delegate respondsToSelector:@selector(shouldCreatePSDDataAfterDelay)]) {
        CGFloat delay = [self.delegate shouldCreatePSDDataAfterDelay];
        if (delay>=0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
               dispatch_get_main_queue(), ^{
                   [self.delegate willCreatePSDDataForScreen:[UIScreen mainScreen]];
                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                       NSData *data = [self psdRepresentationForScreen:[UIScreen mainScreen]];
                       dispatch_async(dispatch_get_main_queue(), ^{
                           [self.delegate didCreatePSDDataForScreen:[UIScreen mainScreen] data:data];
                       });
                   });
               });
        }
    }
}

- (NSData *)psdRepresentationForScreen:(UIScreen *)screen {
    // Initial setup
    CGSize size = [self sizeForInterfaceOrientation];
    size.width = size.width * [UIScreen mainScreen].scale;
    size.height = size.height * [UIScreen mainScreen].scale;
    
    PSDWriter * psdWriter = [[PSDWriter alloc] initWithDocumentSize:size];

    NSArray *allWindows;
    if ([[UIWindow class] respondsToSelector:@selector(allWindowsIncludingInternalWindows:onlyVisibleWindows:forScreen:)]) {
        allWindows = [UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:YES forScreen:[UIScreen mainScreen]];
    } else {
        allWindows = [[UIApplication sharedApplication] windows];
    }

    for (UIWindow *window in allWindows) {
        NSArray *layerImages = [self imagesFromLayerHierarchy:window.layer];

        for (UIImage *layerImage in layerImages) {
            // TODO: Would be cool to put sublayers into psd groups
            // TODO: Rename "Layer" to something more meaningful:
            // - Use layer.name if set
            // - If not set, fall back to auto incrementing counter (like "Layer 1.2.1")
            //   - If layer.delegate is set, name PSD layer based on class name (e.g. "ImageView 1.2.1")
            [psdWriter addLayerWithCGImage:layerImage.CGImage andName:@"Layer" andOpacity:1.0 andOffset:CGPointZero];
        }
    }
    NSData *psdData = [psdWriter createPSDData];
    return psdData;
}

- (NSArray *)imagesFromLayerHierarchy:(CALayer *)layer {
    NSMutableArray *images = [NSMutableArray new];
    [layer beginHidingSublayers];
    [images addObjectsFromArray:[self buildImagesForLayer:layer rootLayer:layer]];
    [layer endHidingSublayers];
    return images;
}

- (NSArray *)buildImagesForLayer:(CALayer *)layer rootLayer:(CALayer *)rootLayer {
    NSMutableArray *images = [NSMutableArray new];
    if (layer.hiddenBeforeHidingSublayers==NO) {
        layer.hidden = NO;
        if (layer.sublayers.count>0) {
            // add self
            [images addObject:[self imageFromLayer:rootLayer]];
            
            // hide own visuals while rendering children
            CGColorRef layerBgColor = layer.backgroundColor;
            layer.backgroundColor = [UIColor clearColor].CGColor;
            CGColorRef layerBorderColor = layer.borderColor;
            layer.borderColor = [UIColor clearColor].CGColor;
            CGColorRef layerShadowColor = layer.shadowColor;
            layer.shadowColor = [UIColor clearColor].CGColor;
            
            [layer.sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [images addObjectsFromArray:[self buildImagesForLayer:obj rootLayer:rootLayer]];
            }];
            
            // reset layer colors
            layer.borderColor = layerBorderColor;
            layer.backgroundColor = layerBgColor;
            layer.shadowColor = layerShadowColor;
        } else {
            // base case
            [images addObject:[self imageFromLayer:rootLayer]];
        }
        layer.hidden = YES;
    }
    return images;
}

- (UIImage *)imageFromLayer:(CALayer *)layer {
    CGSize size = [self sizeForInterfaceOrientation];
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // if interface is in landscape, apply transforms to context for layers that need transform
    if (![self isInterfaceInPortrait] && CATransform3DIsIdentity(layer.transform)) {
        CGContextTranslateCTM(ctx, 0, size.height);
        CGContextRotateCTM(ctx, -M_PI_2);
    }
    
    [layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (CGSize)sizeForInterfaceOrientation {
    CGSize size;
    if ([self isInterfaceInPortrait]) {
        size = [UIScreen mainScreen].bounds.size;
    } else {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    
    return size;
}

- (BOOL)isInterfaceInPortrait {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsPortrait(orientation);
}

@end
