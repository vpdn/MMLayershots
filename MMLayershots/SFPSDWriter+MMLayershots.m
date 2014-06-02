//
//  SFPSDWriter+MMLayershots.m
//  LayershotsDemo
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
            [self addLayerWithCGImage:[rootLayer imageRepresentation].CGImage andName:@"Layer" andOpacity:1.0 andOffset:CGPointZero];
            
            // hide own layer visuals while rendering children
            CGColorRef layerBgColor = layer.backgroundColor;
            layer.backgroundColor = [UIColor clearColor].CGColor;
            CGColorRef layerBorderColor = layer.borderColor;
            layer.borderColor = [UIColor clearColor].CGColor;
            CGColorRef layerShadowColor = layer.shadowColor;
            layer.shadowColor = [UIColor clearColor].CGColor;
            
            // create layer group
            [self openGroupLayerWithName:@"Group"];
            
            // render children
            [[layer.sublayers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self addImagesForLayer:obj renderedToRootLayer:rootLayer];
            }];
            
            // close layer group
            [self closeCurrentGroupLayer];
            
            // reset layer colors
            layer.borderColor = layerBorderColor;
            layer.backgroundColor = layerBgColor;
            layer.shadowColor = layerShadowColor;
        } else {
            // base case
            [self addLayerWithCGImage:[rootLayer imageRepresentation].CGImage andName:@"Layer" andOpacity:1.0 andOffset:CGPointZero];
        }
        layer.hidden = YES;
    }
}

@end
