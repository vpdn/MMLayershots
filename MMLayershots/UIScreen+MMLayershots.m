//
//  UIScreen+MMLayershots.m
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 19/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "UIScreen+MMLayershots.h"
#import "MMLayershots.h"

@implementation UIScreen (MMLayershots)

- (NSData *)psdRepresentation {
    return [[MMLayershots sharedInstance] psdRepresentationForScreen:self];
}

@end
