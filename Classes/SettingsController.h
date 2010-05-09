//
//  SettingsController.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsController : UIViewController {
	IBOutlet UIView *container;
	IBOutlet UITextView *functionsToSave;
}
@property (readonly, retain) UIView *container;
@end
