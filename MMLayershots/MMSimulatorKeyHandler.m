//
//  MMSimulatorKeyHandler.m
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 16/06/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "MMSimulatorKeyHandler.h"

static MMSimulatorKeyHandler *_sharedInstance;

@implementation MMSimulatorKeyHandler

+ (void)attachHandlerToWindow:(UIWindow *)window {
    if (_sharedInstance==nil) {
        _sharedInstance = [MMSimulatorKeyHandler new];
    }
    [window addSubview:_sharedInstance];
    [_sharedInstance becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    // save on ⇧⌘+S
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(didRequestPSDCreationFromCurrentViewState)];
    return @[command];
}

- (void)didRequestPSDCreationFromCurrentViewState {
    // simulate a screenshot notification
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    });
}

@end
