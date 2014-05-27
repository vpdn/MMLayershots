//
//  MMLayershots.m
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 16/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "MMLayershots.h"
#import "CALayer+MMLayershots.h"
#import "PSDWriter.h"

static MMLayershots *_sharedInstance;

@interface MMLayershots()<UIAlertViewDelegate>
@property (nonatomic, strong) NSMutableArray *layers;
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
}

- (void)createLayershotAndCallDelegate {
    if ([self.delegate respondsToSelector:@selector(willCreateLayershotForScreen:)]) {
        [self.delegate willCreateLayershotForScreen:[self defaultScreen]];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self layershotForScreen:[self defaultScreen]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(didCreateLayershotForScreen:data:)]) {
                [self.delegate didCreateLayershotForScreen:[self defaultScreen] data:data];
            }
        });
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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
    CGSize size = screen.bounds.size;
    size.width = size.width * screen.scale;
    size.height = size.height * screen.scale;
    PSDWriter * psdWriter = [[PSDWriter alloc] initWithDocumentSize:size];

    NSArray *allWindows = [[UIApplication sharedApplication] windows];
    // Only parse windows that are part of the requested screen
    allWindows = [allWindows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"screen == %@", screen]];
    
#if (DEBUG)
    // Starting with iOS7 system windows including status bar and alert views aren't part of the
    // [UIApplication sharedApplication].windows array anymore. In debug mode, we add those in
    // again using a private method. For release, only user windows are reported.
    if ([[UIWindow class] respondsToSelector:@selector(allWindowsIncludingInternalWindows:onlyVisibleWindows:forScreen:)]) {
        allWindows = [UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:YES forScreen:screen];
    }
#endif

    for (UIWindow *window in allWindows) {
        NSMutableArray *layerImages = [NSMutableArray new];
        [window.layer beginHidingSublayers];
        [layerImages addObjectsFromArray:[self buildImagesForLayer:window.layer renderedToRootLayer:window.layer]];
        [window.layer endHidingSublayers];

        for (UIImage *layerImage in layerImages) {
            // Currently all layers are named "Layer".
            // See https://github.com/vpdn/MMLayershots/issues/2 for improvement suggestions.
            [psdWriter addLayerWithCGImage:layerImage.CGImage andName:@"Layer" andOpacity:1.0 andOffset:CGPointZero];
        }
    }
    NSData *psdData = [psdWriter createPSDData];
    return psdData;
}

- (NSArray *)buildImagesForLayer:(CALayer *)layer renderedToRootLayer:(CALayer *)rootLayer {
    NSMutableArray *images = [NSMutableArray new];
    if (layer.hiddenBeforeHidingSublayers==NO) {
        layer.hidden = NO;
        if (layer.sublayers.count>0) {
            // add self
            [images addObject:[self imageFromLayer:rootLayer]];
            
            // hide own layer visuals while rendering children
            CGColorRef layerBgColor = layer.backgroundColor;
            layer.backgroundColor = [UIColor clearColor].CGColor;
            CGColorRef layerBorderColor = layer.borderColor;
            layer.borderColor = [UIColor clearColor].CGColor;
            CGColorRef layerShadowColor = layer.shadowColor;
            layer.shadowColor = [UIColor clearColor].CGColor;
            
            [layer.sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [images addObjectsFromArray:[self buildImagesForLayer:obj renderedToRootLayer:rootLayer]];
            }];
            
            // reset layer colors
            layer.borderColor = layerBorderColor;
            layer.backgroundColor = layerBgColor;
            layer.shadowColor = layerShadowColor;
        } else {
            // base case
            [images addObject:[self imageFromLayer:rootLayer]];
        }
        layer.hidden = YES;
    }
    return images;
}

- (UIImage *)imageFromLayer:(CALayer *)layer {
    if ([[UIScreen screens] count]>1) {
        NSLog(@"Warning: For multiple screens, the scale of the main screen is currently used.");
    }
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, [self defaultScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
