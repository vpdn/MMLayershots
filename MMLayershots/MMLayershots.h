//
//  MMLayershots.h
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 12/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIScreen+MMLayershots.h"

@protocol MMLayershotsDelegate;

typedef NS_ENUM(NSUInteger, MMLayershotsCreatePolicy) {
    MMLayershotsCreateNeverPolicy,          // Don't create a layershot and don't ask user
    MMLayershotsCreateOnUserRequestPolicy,  // Show a popup to user asking whether a layershot should be created
    MMLayershotsCreateNowPolicy             // Create a layershot without querying the user
};

@interface MMLayershots : NSObject

/**
 * To use layershots, the delegate must be set. Use the delegate methods to control
 * whether a psd is generated, whether the user should be asked an where the resulting
 * data should go.
 */
@property (nonatomic, weak) id<MMLayershotsDelegate> delegate;

+ (instancetype)sharedInstance;

/**
 * Generates a layershot directly, without any user interaction. Delegate methods
 * are not called when you use this method. You are responsible for notifying the
 * user yourself. This method is a blocking call and must not be called on the
 * main thread.
 */
- (NSData *)layershotForScreen:(UIScreen *)screen;

@end


@protocol MMLayershotsDelegate <NSObject>

/**
 * Whenever a screenshot is made, the delegate is asked whether a layershot should be
 * generated. Queries the delegate whenever a screenshot is made. Depending on the policy
 * returned, a layershot is generated right away, after querying the user (and only
 * generating one when the user desires) or cancel without generating a layershot.
 * To disable layershots in production, you can return MMLayershotsCreateNeverPolicy by
 * default and wrap one of the other policies in a '#ifdef (DEBUG)' statement.
 *
 * @param  screen The screen of which the layershot will be generated.
 * @return Policy to apply for the screenshot the user just took.
 * @see MMLayershotsCreatePolicy.
 */
- (MMLayershotsCreatePolicy)shouldCreateLayershotForScreen:(UIScreen *)screen;


@optional

/** 
 * Called right before the psd generation starts and the progress indicator is shown to
 * the user. You can use this callback e.g. to mask out sensitive areas before the the
 * psd is generated.
 *
 * @param screen The screen of which the layershot will be generated. Currently the screen
 * is always the main screen. If you want to capture an external screen, use the
 * layershotForScreen: method directly.
 */
- (void)willCreateLayershotForScreen:(UIScreen *)screen;

/**
 * Called after the layershot with the psd data is generated. It's your job to present
 * the data to the user. This could happen in many ways, such as:
 * - Show a UIDocumentInteractionController or UIActivityViewController and let the user
 *   select what app to send the data to (such as Dropbox, Email, Messages.app etc)
 * - Show a MFMailComposeViewController with a preset recipients list
 * - Automatically send to a server and show a UIAlertView to the user.
 *
 * @param screen The screen of which the layershot was produced.
 * @param data   The content of the layershot as a Photoshop (PSD) file.
 */
- (void)didCreateLayershotForScreen:(UIScreen *)screen data:(NSData *)data;

@end
