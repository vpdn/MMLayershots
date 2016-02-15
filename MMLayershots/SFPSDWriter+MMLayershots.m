//
//  SFPSDWriter+MMLayershots.m
//  MMLayershots
//
//  Created by Vinh Phuc Dinh on 02/06/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import <objc/runtime.h>
#import "SFPSDWriter+MMLayershots.h"
#import "CALayer+MMLayershots.h"

#define PSD_MAX_GROUP_DEPTH 10
static void *currentGroupDepthKey;

@implementation SFPSDWriter (MMLayershots)

#pragma mark - Layer generation
- (void)addImagesForLayer:(CALayer *)layer renderedToRootLayer:(CALayer *)rootLayer {
    if (layer.hiddenBeforeHidingSublayers == NO) {
        layer.hidden = NO;

        if (layer.sublayers.count > 0) {
            // add self
            UIImage *image = [layer imageRepresentation];

            // Compute layer name
            NSString *layerName = [self computeNameForLayer:layer];
            [self addLayerWithCGImage:image.CGImage
                              andName:[layerName stringByAppendingString:@"-Content"]
                           andOpacity:1.0
                            andOffset:[layer convertPoint:CGPointZero toLayer:nil]];

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

            // create layer group
            BOOL newGroupAdded = NO;
            if (self.currentGroupDepth<PSD_MAX_GROUP_DEPTH) {
                // A New group was added
                newGroupAdded = YES;

                [self incrementCurrentGroupDepth];
                [self openGroupLayerWithName:layerName];
            }

            // render children
            [[layer.sublayers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self addImagesForLayer:obj renderedToRootLayer:rootLayer];
            }];

            // reset layer colors
            for (NSString *layerProperty in layerProperties) {
                [layer setValue:layerProperties[layerProperty] forKey:layerProperty];
            }

            // Close layer group if needed
            if (newGroupAdded) {
                NSError *error = nil;
                [self closeCurrentGroupLayerWithError:&error];
                [self decrementCurrentGroupDepth];
                if (error) {
                    NSLog(@"%@ - %@", error.localizedDescription, error.localizedRecoveryOptions);
                }
            }
        } else {
            // Base case
            NSString *layerName = [self computeNameForLayer:layer];
            [self addLayerWithCGImage:[layer imageRepresentation].CGImage
                              andName:layerName
                           andOpacity:1.0
                             andOffset:[layer convertPoint:CGPointZero toLayer:nil]];
        }

        layer.hidden = YES;
    }
}

- (void)showLayersInSubtree:(CALayer *)layer {
    if (!layer.hiddenBeforeHidingSublayers) {
        layer.hidden = NO;
        for (CALayer *sublayer in layer.sublayers) {
            [self showLayersInSubtree:sublayer];
        }
    }
}

#pragma mark - Layer naming
- (NSString *)computeNameForLayer:(CALayer *)layer {
    
    // If no delegate, class name will be used
    if (!layer.delegate) {
        return [[layer class] description];
    }

    // If delegate, but not UIView subclass, use class description too
    if (![layer.delegate isKindOfClass:[UIView class]]) {
        return [[layer.delegate class] description];
    }

    // Extract view to determine name
    UIView *view = (UIView *) layer.delegate;
    NSAssert([view isKindOfClass:[UIView class]], @"Layer delegate is not a UIView");
    NSString *viewName = view.accessibilityLabel;
    if (viewName.length>0) {
        return viewName;
    }

    // Check for text attribute (UILabel / UITextView)
    if ([view respondsToSelector:@selector(text)]) {
        id viewText = [view performSelector:@selector(text)];
        if ([viewText isKindOfClass:[NSString class]]) {
            if ([(NSString *)viewText length]) {
                return viewText;
            }
        }
    }

    // Check for UIButton
    if ([view isKindOfClass:[UIButton class]]) {
        // According to docs: If both, title and attributed title are set,
        // the attributed title is preferred. We conform to that order.

        // Attributed title
        NSString *viewText = [[(UIButton *)view currentAttributedTitle] string];
        if (viewText.length > 0) {
            return viewText;
        }

        // Normal title
        viewText = [(UIButton *)view currentTitle];
        if (viewText.length > 0) {
            return viewText;
        }
        
    }

    return [[view class] description];
}

- (int)currentGroupDepth {
    NSNumber *currentGroupDepth = nil;
    currentGroupDepth = objc_getAssociatedObject(self, &currentGroupDepthKey);
    if (currentGroupDepth != nil) {
        return currentGroupDepth.intValue;
    }
    return 0;
}

- (void)incrementCurrentGroupDepth {
    NSNumber *currentGroupDepth = nil;
    currentGroupDepth = objc_getAssociatedObject(self, &currentGroupDepthKey);
    int currentGroupDepthValue = 0;
    if (currentGroupDepth != nil) {
        currentGroupDepthValue = [currentGroupDepth intValue];
    }
    currentGroupDepthValue++;
    objc_setAssociatedObject(self, &currentGroupDepthKey, @(currentGroupDepthValue), OBJC_ASSOCIATION_COPY);
    if (currentGroupDepthValue> PSD_MAX_GROUP_DEPTH) {
        NSLog(@"Current group depth (%d) is above PSDs maximum of %d!", currentGroupDepthValue, PSD_MAX_GROUP_DEPTH);
    }
}

- (void)decrementCurrentGroupDepth {
    NSNumber *currentGroupDepth = nil;
    currentGroupDepth = objc_getAssociatedObject(self, &currentGroupDepthKey);
    int currentGroupDepthValue = 0;
    if (currentGroupDepth != nil) {
        currentGroupDepthValue = [currentGroupDepth intValue];
        currentGroupDepthValue--;
        if (currentGroupDepthValue>0) {
            objc_setAssociatedObject(self, &currentGroupDepthKey, @(currentGroupDepthValue), OBJC_ASSOCIATION_COPY);
        } else {
            //remove
            objc_setAssociatedObject(self, &currentGroupDepthKey, nil, OBJC_ASSOCIATION_COPY);
        }
    } else {
        NSLog(@"Can't decrement current group value because it is not set.");
    }
}

@end
