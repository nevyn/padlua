//
//  ShellController.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "lua.h"
#import "lauxlib.h"
#import "lualib.h"
#import "lstate.h"


@interface ShellController : UIViewController {
	IBOutlet UIView *container;
	IBOutlet UITextView *out;
	IBOutlet UITextView *in;
	lua_State *L;
	NSMutableArray *commandHistory;
	int commandIndex;
	NSString *savedCommand;
}
-(IBAction)insertCharacter:(UIButton*)sender;
-(IBAction)runCurrent:(UIButton*)sender;
-(IBAction)olderCommand:(id)sender;
-(IBAction)newerCommand:(id)sender;

-(void)output:(NSString*)output;
-(void)save;
@end
