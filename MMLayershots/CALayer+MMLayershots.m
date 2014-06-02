//
//  CALayer+MMLayershots.m
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 17/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import <objc/runtime.h>
#import "CALayer+MMLayershots.h"

static char kAssociatedObjectHiddenState;

@implementation CALayer (MMLayershots)

- (void)beginHidingSublayers {
        NSAssert(objc_getAssociatedObject(self, &kAssociatedObjectHiddenState)==nil,
                 @"Layer already has a visibility state attached. Restore state first before hiding again.");

    objc_setAssociatedObject(self, &kAssociatedObjectHiddenState, [NSNumber numberWithBool:self.hidden], OBJC_ASSOCIATION_RETAIN);
    self.hidden = YES;
    
    if (self.sublayers.count>0) {
        [self.sublayers makeObjectsPerformSelector:@selector(beginHidingSublayers)];
    }
}

- (void)endHidingSublayers {
    if (objc_getAssociatedObject(self, &kAssociatedObjectHiddenState) == nil) {
        NSLog(@"Following CALayer doesn't have a visibility state attached. This could happen because it was added while the psd was generated, i.e. after [CALayer beginHidingSublayers] was called.\n%@", self);
    }
    
    NSNumber *hidden = objc_getAssociatedObject(self, &kAssociatedObjectHiddenState);
    self.hidden = [hidden boolValue];
    objc_setAssociatedObject(self, &kAssociatedObjectHiddenState, nil, OBJC_ASSOCIATION_ASSIGN);
    
    if (self.sublayers.count>0) {
        [self.sublayers makeObjectsPerformSelector:@selector(endHidingSublayers)];
    }
}

- (BOOL)hiddenBeforeHidingSublayers {
    NSNumber *hidden = objc_getAssociatedObject(self, &kAssociatedObjectHiddenState);
    NSAssert(hidden!=nil, @"Can't determine original visibility. This call only makes sense within an executeBlockAfterHidingSublayers block.");
    return [hidden boolValue];
}

- (UIImage *)imageRepresentation {
    if ([[UIScreen screens] count]>1) {
        NSLog(@"Warning: For multiple screens, the scale of the main screen is currently used.");
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (!UIInterfaceOrientationIsPortrait(orientation) && ![self.delegate isKindOfClass:NSClassFromString(@"UIStatusBarWindow")]) {
        image = [self applyTransformsToImage:image forInterfaceOrientation:orientation];
    }
    
    return image;
}


#pragma mark - Helper

- (UIImage *)applyTransformsToImage:(UIImage *)image forInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [self sizeForInterfaceOrientation:orientation];
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIInterfaceOrientationLandscapeRight) {
        CGContextTranslateCTM(context, 0, size.height);
        CGContextRotateCTM (context, -M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        CGContextTranslateCTM(context, size.width, 0);
        CGContextRotateCTM (context, M_PI_2);
    }
    
    [image drawAtPoint:CGPointMake(0, 0)];
    UIImage *transformedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return transformedImage;
}


- (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGSize size;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        size = [UIScreen mainScreen].bounds.size;
    } else {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    
    return size;
}

@end
