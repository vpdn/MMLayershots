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
- (void)addImagesForView:(UIView *)view renderedToRootView:(UIView *)rootView
{
    if (view.layer.hiddenBeforeHidingSublayers==NO) {
        view.layer.hidden = NO;
        if (view.layer.sublayers.count>0) {
            // add self
            UIImage *image = [rootView.layer imageRepresentation];

            // Prevent from adding empty images
            CGImageRef cgImage = image.CGImage;
            if (![self isImageEmpty:cgImage])
            {
                // Compute layer name
                NSString *layerName = [self computeNameForView:view];
                
                // Add computed image
                [self addLayerWithCGImage:cgImage andName:layerName andOpacity:1.0 andOffset:CGPointZero];
                
                // hide own layer visuals while rendering children
                NSMutableDictionary *layerProperties = [NSMutableDictionary new];
                
                if (view.layer.backgroundColor) {
                    layerProperties[@"backgroundColor"] = (__bridge id)(view.layer.backgroundColor);
                    view.layer.backgroundColor = nil;
                }
                if (view.layer.borderColor) {
                    layerProperties[@"borderColor"] = (__bridge id)(view.layer.borderColor);
                    view.layer.borderColor = nil;
                }
                if (view.layer.shadowColor) {
                    layerProperties[@"shadowColor"] = (__bridge id)(view.layer.shadowColor);
                    view.layer.shadowColor = nil;
                }
                
                NSString *groupName = nil;
                if ([view isKindOfClass:[UIScrollView class]]               ||
                    [view isKindOfClass:[UITableViewCell class]]            ||
                    [view isKindOfClass:[UICollectionViewCell class]]       ||
                    [view isKindOfClass:[UICollectionReusableView class]]   ||
                    [view isKindOfClass:[UITableViewHeaderFooterView class]])
                {
                    // Compute group name
                    groupName = [[view class] description];
                    
                    // create layer group
                    [self openGroupLayerWithName:groupName];
                }
                
                // render children
                [[view.subviews copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [self addImagesForView:obj renderedToRootView:rootView];
                }];
                
                // reset layer colors
                for (NSString *layerProperty in layerProperties) {
                    [view.layer setValue:layerProperties[layerProperty] forKey:layerProperty];
                }
                
                // close layer group
                if (groupName)
                {
                    NSError *error = nil;
                    [self closeCurrentGroupLayerWithError:&error];
                    if (error)
                        NSLog(@"%@ - %@", error.localizedDescription, error.localizedRecoveryOptions);
                }
            }
        }
        else
        {
            // Prevent from adding empty images
            CGImageRef cgImage = [rootView.layer imageRepresentation].CGImage;
            if (![self isImageEmpty:cgImage])
            {
                // base case
                NSString *layerName = [self computeNameForView:view];
                [self addLayerWithCGImage:cgImage
                                  andName:layerName
                               andOpacity:1.0
                                andOffset:CGPointZero];
            }
        }

        view.layer.hidden = YES;
    }
}

- (NSString *)computeNameForView:(UIView *)aView
{
    NSString *viewName = aView.accessibilityLabel;
    if (viewName)
        return viewName;

    // Check for text attribute (UILabel / UITextView)
    if ([aView respondsToSelector:@selector(text)])
    {
        id viewText = [aView performSelector:@selector(text)];
        if ([viewText isKindOfClass:[NSString class]])
        {
            if ([(NSString *)viewText length])
                return viewText;
        }
    }

    // Check for attributedText (UILabel / UITextView / UITextField)
    if ([aView respondsToSelector:@selector(attributedText)])
    {
        id viewText = [aView performSelector:@selector(attributedText)];
        if ([viewText isKindOfClass:[NSAttributedString class]])
        {
            if ([(NSAttributedString *)viewText length])
                return [(NSAttributedString *)viewText string];
        }
    }

    // Check for UIButton
    if ([aView isKindOfClass:[UIButton class]])
    {
        // Normal title
        NSString *viewText = [(UIButton *)aView currentTitle];
        if (viewText.length > 0)
            return viewText;
        
        // Attributed title
        viewText = [[(UIButton *)aView currentAttributedTitle] string];
        if (viewText.length > 0)
            return viewText;
    }

    // No text found, Add more tests ?
    return [[aView class] description];
}

#pragma mark - Utils
- (BOOL)isImageEmpty:(CGImageRef)anImage
{
    // TODO Add test to check is imageRef content is all transparent ?
    return NO;
}


// Old implementation for reference. Now browing throught View instead of layers.
/*
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
*/
@end
