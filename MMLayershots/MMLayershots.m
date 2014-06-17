//
//  MMLayershots.m
//  MMLayershots
//
//  Created by Vinh Phuc Dinh on 16/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "MMLayershots.h"
#import "SFPSDWriter.h"
#import "CALayer+MMLayershots.h"
#import "UIScreen+MMLayershots.h"
#import "SFPSDWriter+MMLayershots.h"
#import "UIWindow+SimulatorKeyHandler.h"

static MMLayershots *_sharedInstance;

@interface MMLayershots()<UIAlertViewDelegate>
@property (nonatomic, strong) NSMutableArray *layers;

// loading indicator
@property (nonatomic, strong) UIWindow *hudWindow;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign, getter = isInProgress) BOOL inProgress;
@end

// Private methods
#if (DEBUG)
@interface UIWindow()
+ (NSArray *)allWindowsIncludingInternalWindows:(BOOL)includeInternalWindows onlyVisibleWindows:(BOOL)visibleOnly forScreen:(UIScreen *)screen;
@end
#endif

@implementation MMLayershots

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [MMLayershots new];
        _sharedInstance.inProgress = NO;
    });
    return _sharedInstance;
}

- (void)setDelegate:(id<MMLayershotsDelegate>)delegate {
    if (_delegate!=nil && delegate==nil) {
        [self unregisterNotification];
    } else if (_delegate==nil && delegate!=nil) {
        [self registerNotification];
    }
    _delegate = delegate;
}

- (void)dealloc {
    [self unregisterNotification];
}


#pragma mark - Notifications

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}

- (void)unregisterNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)userDidTakeScreenshot {
    dispatch_async(dispatch_get_main_queue(),  ^{
        if (self.isInProgress) {
            // ignore screenshots and don't show alert view while psd is generated
            return;
        }
        if ([self.delegate respondsToSelector:@selector(shouldCreateLayershotForScreen:)]) {
            MMLayershotsCreatePolicy policy = [self.delegate shouldCreateLayershotForScreen:[self defaultScreen]];
            if (policy==MMLayershotsCreateNeverPolicy) {
                return;
            } else if (policy==MMLayershotsCreateOnUserRequestPolicy) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Layershots", @"User query popup title")
                                            message:NSLocalizedString(@"Do you want to create a layered psd with the screenshot?", @"User query popup message")
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"No", @"User query popup cancel button")
                                  otherButtonTitles:NSLocalizedString(@"Yes", @"User query popup ok button"), nil] show];
            } else if (policy==MMLayershotsCreateNowPolicy) {
                [self createLayershotAndCallDelegate];
            }
        }
    });
}

- (void)showHUDWindowAnimated:(BOOL)animated {
    UIWindow *hudWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    hudWindow.backgroundColor = [UIColor clearColor];
    hudWindow.windowLevel = UIWindowLevelStatusBar;
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.backgroundColor = [UIColor blackColor];
    activityIndicator.frame = hudWindow.bounds;
    [hudWindow addSubview:activityIndicator];
    activityIndicator.alpha = 0.0;
    [activityIndicator startAnimating];
    hudWindow.hidden = NO;
    [UIView animateWithDuration:(animated?1.0:0.0) animations:^{
        activityIndicator.alpha = 1.0;
    }];
    self.hudWindow = hudWindow;
    self.activityIndicator = activityIndicator;
}

- (void)hideHUDWindowAnimated:(BOOL)animated {
    [UIView animateWithDuration:(animated?0.3:0.0) animations:^{
        self.activityIndicator.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.hudWindow.hidden = YES;
        self.hudWindow = nil;
    }];
}

- (void)createLayershotAndCallDelegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isInProgress) { // serialized on main queue
            // ignore screenshots while psd is generated to prevent parallel execution
            return;
        } else {
            self.inProgress = YES;
        }
        if ([self.delegate respondsToSelector:@selector(willCreateLayershotForScreen:)]) {
            [self.delegate willCreateLayershotForScreen:[self defaultScreen]];
        }
        [self showHUDWindowAnimated:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [self layershotForScreen:[self defaultScreen]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideHUDWindowAnimated:YES];
                self.inProgress = NO;
                if ([self.delegate respondsToSelector:@selector(didCreateLayershotForScreen:data:)]) {
                    [self.delegate didCreateLayershotForScreen:[self defaultScreen] data:data];
                }
            });
        });
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    enum {
        NoButtonIndex = 0,
        YesButtonIndex
    };
    if (buttonIndex==YesButtonIndex) {
        [self createLayershotAndCallDelegate];
    }
}

- (UIScreen *)defaultScreen {
    return [UIScreen mainScreen];
}


#pragma mark - Workhorses

- (NSData *)layershotForScreen:(UIScreen *)screen {
    // Initial setup
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGSize size = [screen sizeForInterfaceOrientation:orientation];
    size.width = size.width * screen.scale;
    size.height = size.height * screen.scale;
    
    SFPSDWriter * psdWriter = [[SFPSDWriter alloc] initWithDocumentSize:size];

    NSArray *allWindows = [[UIApplication sharedApplication] windows];
    
#if (DEBUG)
    // Starting with iOS7 system windows including status bar and alert views aren't part of the
    // [UIApplication sharedApplication].windows array anymore. In debug mode, we add those in
    // again using a private method. For release, only user windows are reported.
    if ([[UIWindow class] respondsToSelector:@selector(allWindowsIncludingInternalWindows:onlyVisibleWindows:forScreen:)]) {
        allWindows = [UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:YES forScreen:screen];
    }
#endif

    // Only parse windows that are part of the requested screen
    allWindows = [allWindows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"screen == %@ AND self != %@", screen, self.hudWindow]];

    for (UIWindow *window in allWindows) {
        [window.layer beginHidingSublayers];
        [psdWriter addImagesForLayer:window.layer renderedToRootLayer:window.layer];
        [window.layer endHidingSublayers];
    }
    NSData *psdData = [psdWriter createPSDData];
    return psdData;
}

@end
