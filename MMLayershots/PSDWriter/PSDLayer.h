//
//  PSDLayer.h
//  PSDWriterLibrary
//
//  Created by Ben Gotow on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface PSDLayer : NSObject

/** The name of the layer. I believe this must be 16 characters or less. */

@property (nonatomic, retain) NSString * name;
/** The image data in RGBA or RGB format, depending on whether the PSDWriter.layerChannelCount
is set to 4 or 3, respectively.*/
@property (nonatomic, retain) NSData * imageData;

/** The opacity of the layer between 0 and 1. */
@property (nonatomic, assign) float opacity;

/** The rectangle the layer should be placed within in the PSD. Note that scaling is not currently
supported, so you should really only adjust the origin of this rect to move the imageData around
within the PSD. 
*/
@property (nonatomic, assign) CGRect rect;

@end
