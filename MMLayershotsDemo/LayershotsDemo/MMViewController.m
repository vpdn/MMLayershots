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
@end

@implementation MMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSampleView];
    [MMLayershots sharedInstance].delegate = self;
}

- (void)setupSampleView {
    self.view.backgroundColor = [UIColor lightGrayColor];
    
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
    [self.view addSubview:box];

    // orange box in box
    UIView *box2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    box2.backgroundColor = [UIColor orangeColor];
    box2.layer.cornerRadius = 5.0;
    box2.layer.borderWidth = 2.0;
    box2.layer.borderColor = [UIColor blackColor].CGColor;
    box2.center = (CGPoint){CGRectGetMidX(box.bounds), CGRectGetMidY(box.bounds)};
    [box addSubview:box2];
    
#if TARGET_IPHONE_SIMULATOR
    // simulate a screenshot notification
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    });
#endif
}

#pragma mark - MMLayershotsDelegate

- (CGFloat)shouldCreatePSDDataAfterDelay {
    NSLog(@"Will start assembling psd in 3 seconds...");
    return 3.0;
}

- (void)willCreatePSDDataForScreen:(UIScreen *)screen {
    NSLog(@"Creating psd now...");
}

+ (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (void)didCreatePSDDataForScreen:(UIScreen *)screen data:(NSData *)data {
#if TARGET_IPHONE_SIMULATOR
    
    NSString *dataPath = [[[self class] documentsDirectory] stringByAppendingPathComponent:@"layershots.psd"];
    [data writeToFile:dataPath atomically:NO];
    NSLog(@"Saving psd to %@", dataPath);
    
#else
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailVC = [MFMailComposeViewController new];
        [mailVC addAttachmentData:data mimeType:@"image/vnd.adobe.photoshop" fileName:@"layershots.psd"];
        mailVC.delegate = self;
        [self presentViewController:mailVC animated:YES completion:nil];
    }
#endif
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
