//
//  padluaAppDelegate.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-08.
//  Copyright Third Cog Software 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShellController.h"


@interface padluaAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet ShellController *shell;
}
@end

