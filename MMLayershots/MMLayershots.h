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

@interface MMLayershots : NSObject

/**
 * When the delegate is set, Layershots shows a pop up when the user takes a screenshot on the device,
 * asking where the user wants to capture a psd.
 */
@property (nonatomic, weak) id<MMLayershotsDelegate> delegate;

+ (instancetype)sharedInstance;

// Generates a psd from all visible UIWindows
- (NSData *)psdRepresentationForScreen:(UIScreen *)screen;

@end


@protocol MMLayershotsDelegate <NSObject>

/**
 */
- (CGFloat)shouldCreatePSDDataAfterDelay;

/** Called just before the psd generation starts. Use this method to show a progress indicator to the user.
 */
- (void)willCreatePSDDataForScreen:(UIScreen *)screen;

/** Called after the psd has been generated.
 */
- (void)didCreatePSDDataForScreen:(UIScreen *)screen data:(NSData *)data;

@end
