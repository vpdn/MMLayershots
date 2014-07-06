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
#pragma mark - Layer generation
- (void)addImagesForLayer:(CALayer *)layer renderedToRootLayer:(CALayer *)rootLayer
{
    if (layer.hiddenBeforeHidingSublayers == NO)
    {
        layer.hidden = NO;

        if (layer.sublayers.count>0)
        {
            // add self
            UIImage *image = [rootLayer imageRepresentation];

            // Compute layer name
            NSString *layerName = [self computeNameForLayer:layer];
            [self addLayerWithCGImage:image.CGImage
                              andName:layerName
                           andOpacity:1.0
                            andOffset:CGPointZero];

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

            // Close layer group
//            NSError *error = nil;
//            [self closeCurrentGroupLayerWithError:&error];
//            if (error) {
//                NSLog(@"%@ - %@", error.localizedDescription, error.localizedRecoveryOptions);
//            }
        }
        else
        {
            // base case
            NSString *layerName = [self computeNameForLayer:layer];
            [self addLayerWithCGImage:[rootLayer imageRepresentation].CGImage
                              andName:layerName
                           andOpacity:1.0
                             andOffset:CGPointZero];
        }

        layer.hidden = YES;
    }
}

#pragma mark - Layer naming
- (NSString *)computeNameForLayer:(CALayer *)alayer
{
    // If no delegate, class name will be used
    if (!alayer.delegate)
        return [[alayer class] description];

    // If delegate, but not UIView subclass, use class description too
    if (![alayer.delegate isKindOfClass:[UIView class]])
        return [[alayer.delegate class] description];

    // Extract view to determine name
    UIView *view = (UIView *)alayer.delegate;
    NSString *viewName = view.accessibilityLabel;
    if (viewName)
        return viewName;

    // Check for text attribute (UILabel / UITextView)
    if ([view respondsToSelector:@selector(text)])
    {
        id viewText = [view performSelector:@selector(text)];
        if ([viewText isKindOfClass:[NSString class]])
        {
            if ([(NSString *)viewText length])
                return viewText;
        }
    }

    // Check for attributedText (UILabel / UITextView / UITextField)
    if ([view respondsToSelector:@selector(attributedText)])
    {
        id viewText = [view performSelector:@selector(attributedText)];
        if ([viewText isKindOfClass:[NSAttributedString class]])
        {
            if ([(NSAttributedString *)viewText length])
                return [(NSAttributedString *)viewText string];
        }
    }

    // Check for UIButton
    if ([view isKindOfClass:[UIButton class]])
    {
        // Normal title
        NSString *viewText = [(UIButton *)view currentTitle];
        if (viewText.length > 0)
            return viewText;
        
        // Attributed title
        viewText = [[(UIButton *)view currentAttributedTitle] string];
        if (viewText.length > 0)
            return viewText;
    }

    // No text found, Add more tests ?
    return [[view class] description];
}
@end
