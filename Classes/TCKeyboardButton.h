//
//  TCKeyboardButton.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>


@interface TCKeyboardButton : UIButton {
	UIColor *tint;
}
@property (retain) UIColor *tint;
@end
