//
//  UIScreen+MMLayershots.m
//  MMLayershots
//
//  Created by Vinh Phuc Dinh on 02/06/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "UIScreen+MMLayershots.h"

@implementation UIScreen (MMLayershots)

- (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGSize size;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        size = self.bounds.size;
    } else {
        size = CGSizeMake(self.bounds.size.height, self.bounds.size.width);
    }
    
    return size;
}

@end
