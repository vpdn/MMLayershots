//
//  UIWindow+MMSimulatorKeyHandler.m
//  MMLayershots
//
//  Created by Vinh Phuc Dinh on 17/06/14.
//
//

#import "UIWindow+MMSimulatorKeyHandler.h"
#import <objc/runtime.h>

#if (TARGET_IPHONE_SIMULATOR)

@implementation UIWindow (MMSimulatorKeyHandler)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIWindow swizzleKeyCommands];
        [UIWindow swizzleCanBecomeFirstResponder];
    });
}

#pragma mark - Method swizzling

+ (void)swizzleOriginalSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(self.class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)swizzleCanBecomeFirstResponder {
    SEL originalSelector = @selector(canBecomeFirstResponder);
    SEL swizzledSelector = @selector(_Layershots_canBecomeFirstResponder);
    
    [self swizzleOriginalSelector:originalSelector withSelector:swizzledSelector];
}

+ (void)swizzleKeyCommands {
    SEL originalSelector = @selector(keyCommands);
    SEL swizzledSelector = @selector(_Layershots_keyCommands);
    [self swizzleOriginalSelector:originalSelector withSelector:swizzledSelector];
}


#pragma mark - Swizzled methods

- (BOOL)_Layershots_canBecomeFirstResponder {
    return YES;
}

- (NSArray *)_Layershots_keyCommands {
    // save on ⇧⌘+S
    NSArray *keyCommands = [self _Layershots_keyCommands];
    if (keyCommands==nil) {
        keyCommands = @[];
    }
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(didRequestPSDCreationFromCurrentViewState)];
    return [keyCommands arrayByAddingObject:command];
}


#pragma - Notification trigger

- (void)didRequestPSDCreationFromCurrentViewState {
    // simulate a screenshot notification
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    });
}
@end
#endif
