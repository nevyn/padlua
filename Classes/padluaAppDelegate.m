//
//  padluaAppDelegate.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-08.
//  Copyright Third Cog Software 2010. All rights reserved.
//

#import "padluaAppDelegate.h"

@implementation padluaAppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
	[window makeKeyAndVisible];
	[window addSubview:shell.view];
	
	return YES;
}
- (void)dealloc {
	[window release];
	[super dealloc];
}
@end
