//
//  SFPSDWriter+MMLayershots.m
//  MMLayershots
//
//  Created by Vinh Phuc Dinh on 02/06/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "SFPSDWriter+MMLayershots.h"
#import "CALayer+MMLayershots.h"
@implementation SFPSDWriter (MMLayershots)

// Currently all layers are named "Layer".
// See https://github.com/vpdn/MMLayershots/issues/2 for improvement suggestions.

- (void)addImagesForLayer:(CALayer *)layer renderedToRootLayer:(CALayer *)rootLayer {
    if (layer.hiddenBeforeHidingSublayers==NO) {
        layer.hidden = NO;
        if (layer.sublayers.count>0) {
            // add self
            UIImage *image = [rootLayer imageRepresentation];
            [self addLayerWithCGImage:image.CGImage andName:@"Layer" andOpacity:1.0 andOffset:CGPointZero];
            
            // hide own layer visuals while rendering children
            NSMutableDictionary *layerProperties = [NSMutableDictionary new];
            
            if (layer.backgroundColor) {
                layerProperties[@"backgroundColor"] = (__bridge id)(layer.backgroundColor);
                layer.backgroundColor = nil;
            }
            if (layer.borderColor) {
                layerProperties[@"borderColor"] = (__bridge id)(layer.borderColor);
                layer.borderColor = nil;
            }
            if (layer.shadowColor) {
                layerProperties[@"shadowColor"] = (__bridge id)(layer.shadowColor);
                layer.shadowColor = nil;
            }
            
//            // create layer group
//            [self openGroupLayerWithName:@"Group"];
            
            // render children
            [[layer.sublayers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self addImagesForLayer:obj renderedToRootLayer:rootLayer];
            }];
            
            // reset layer colors
            for (NSString *layerProperty in layerProperties) {
                [layer setValue:layerProperties[layerProperty] forKey:layerProperty];
            }
            
            // close layer group
//            NSError *error = nil;
//            [self closeCurrentGroupLayerWithError:&error];
//            if (error) {
//                NSLog(@"%@ - %@", error.localizedDescription, error.localizedRecoveryOptions);
//            }
        } else {
            // base case
            [self addLayerWithCGImage:[rootLayer imageRepresentation].CGImage andName:@"Layer" andOpacity:1.0 andOffset:CGPointZero];
        }
        layer.hidden = YES;
    }
}

@end
