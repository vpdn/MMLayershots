//
//  SFPSDWriter+MMLayershots.h
//  MMLayershots
//
//  Created by Vinh Phuc Dinh on 02/06/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import "SFPSDWriter.h"

@interface SFPSDWriter (MMLayershots)

- (void)addImagesForView:(UIView *)view renderedToRootView:(UIView *)rootView;

@end
