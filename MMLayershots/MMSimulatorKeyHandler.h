//
//  MMSimulatorKeyHandler.h
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 16/06/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//
//  Idea to attach a view to UIWindow to capture keys by Erica Sadun

#import <UIKit/UIKit.h>

/**
 * The iPhone simulator doesn't generate a UIApplicationUserDidTakeScreenshotNotification
 * when the screen is saved with ⌘+s. The MMSimulatorKeyHandler simulates the notification
 * whenever ⇧⌘+s is pressed instead.
 */
@interface MMSimulatorKeyHandler : UIView

+ (void)attachHandlerToWindow:(UIWindow *)window;

@end
