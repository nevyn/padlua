//
//  ShellController.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsController.h"
#import "LuaCanvas2D.h"

#import "lua.h"
#import "lauxlib.h"
#import "lualib.h"
#import "lstate.h"


@interface ShellController : UIViewController 
<UIPopoverControllerDelegate>
{
	IBOutlet UIView *container;
		IBOutlet UIView *outContainer;
			IBOutlet UITextView *out;
			IBOutlet LuaCanvas2D *canvas;
		IBOutlet UITextView *in;
	lua_State *L;
	NSMutableArray *commandHistory;
	int commandIndex;
	NSString *savedCommand;
	
	IBOutlet SettingsController *settings;
	
	UINavigationController *helpController;
}
+(id)shellController;
-(IBAction)insertCharacter:(UIButton*)sender;
-(IBAction)runCurrent:(UIButton*)sender;
-(IBAction)olderCommand:(id)sender;
-(IBAction)newerCommand:(id)sender;
-(IBAction)showSettings:(UIButton*)sender;

-(void)output:(NSString*)output;

@end
