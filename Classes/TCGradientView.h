//
//  TCGradientLayer.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TCGradientView : UIView {
	CAGradientLayer *gradient;
}
@property (retain) NSArray *colors;
@end
