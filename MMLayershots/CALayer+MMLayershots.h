//
//  CALayer+MMLayershots.h
//  LayershotsDemo
//
//  Created by Vinh Phuc Dinh on 17/05/14.
//  Copyright (c) 2014 Mocava Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (MMLayershots)

/** Returns the visibility of the CALayer, before the context
 */
- (BOOL)hiddenBeforeHidingSublayers;

- (void)beginHidingSublayers;
- (void)endHidingSublayers;

- (UIImage *)imageRepresentation;

@end
