//
//  UIWindow+MMSimulatorKeyHandler.h
//  Pods
//
//  Created by Vinh Phuc Dinh on 17/06/14.
//
//

#import <UIKit/UIKit.h>

/**
 * The iPhone simulator doesn't generate a UIApplicationUserDidTakeScreenshotNotification
 * when the screen is saved with ⌘+s. We simulate the notification by making UIWindow hook
 * into the responder chain and listening to key commands whenever ⇧⌘+s is pressed.
 */

@interface UIWindow (MMSimulatorKeyHandler)

@end
