//
//  EditorController.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "lua.h"
#import "lauxlib.h"


@interface EditorController : UIViewController {
	id _modalParent;
  UITextView *editor;
  UILabel *titleLabel;
}
@property (retain) IBOutlet UITextView *editor;
@property (retain) IBOutlet UILabel *titleLabel;
+(id)pushEditorForFile:(NSString*)path on:(UIViewController*)modalParent;

-(IBAction)done:(id)sender;
@end

@interface EditorController (LuaExtensions)
+(void)publishModuleInState:(lua_State*)state;
@end
