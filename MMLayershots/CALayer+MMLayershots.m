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
    
  for (CALayer *layer in [[rootLayer.sublayers copy] autorelease]) {
    [layer removeFromSuperlayer];
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

@end
