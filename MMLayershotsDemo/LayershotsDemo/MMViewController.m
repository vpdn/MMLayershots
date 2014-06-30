//
//  MMViewController.m
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 19/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "MMViewController.h"
#import "MMLayershots.h"

@interface MMViewController()<MMLayershotsDelegate, MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) UIDocumentInteractionController *documentController;
@end

@implementation MMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSampleView];
    [MMLayershots sharedInstance].delegate = self;
}

- (void)setupSampleView {
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scrollView];
    
    // white box
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    box.backgroundColor = [UIColor whiteColor];
    box.layer.cornerRadius = 5.0;
    box.layer.borderWidth = 2.0;
    box.layer.borderColor = [UIColor blackColor].CGColor;
    box.center = (CGPoint){CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)};
    box.clipsToBounds = NO;
    box.layer.shadowColor = [UIColor blackColor].CGColor;
    box.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    box.layer.shadowRadius = 2.0;
    box.layer.shadowOpacity = 0.5;
    [scrollView addSubview:box];

    // orange box in box
    UIView *box2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    box2.backgroundColor = [UIColor orangeColor];
    box2.layer.cornerRadius = 5.0;
    box2.layer.borderWidth = 2.0;
    box2.layer.borderColor = [UIColor blackColor].CGColor;
    box2.center = (CGPoint){CGRectGetMidX(box.bounds), CGRectGetMidY(box.bounds)};
    [box addSubview:box2];
    
#if TARGET_IPHONE_SIMULATOR
    [[[UIAlertView alloc] initWithTitle:@"Note" message:@"The simulator doesn't trigger screenshot notifications when a screenshot is saved. Use ⇧⌘+S to trigger a simulated screenshot notification." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
;
#endif
}

#pragma mark - MMLayershotsDelegate

- (MMLayershotsCreatePolicy)shouldCreateLayershotForScreen:(UIScreen *)screen {
    MMLayershotsCreatePolicy policy = MMLayershotsCreateNeverPolicy;
#if (DEBUG)
    policy = MMLayershotsCreateOnUserRequestPolicy;
#endif
    return policy;
}

- (void)willCreateLayershotForScreen:(UIScreen *)screen {
    NSLog(@"Creating psd now...");
    
}

- (void)didCreateLayershotForScreen:(UIScreen *)screen data:(NSData *)data {
    NSString *filePath = [[[self class] documentsDirectory] stringByAppendingPathComponent:@"layershots.psd"];
    [data writeToFile:filePath atomically:NO];
    NSLog(@"Saving psd to %@", filePath);
#if (TARGET_IPHONE_SIMULATOR)
    [[[UIAlertView alloc] initWithTitle:@"Done" message:@"File has been generated and saved. See log output for location." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#else
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    [self.documentController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
#endif
}

+ (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSAssert(documentsDirectory!=nil, @"Can't determine document directory");
    return documentsDirectory;
}

@end
