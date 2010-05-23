//
//  EditorController.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "EditorController.h"
#import "ShellController.h"

@implementation EditorController
@synthesize editor, titleLabel;
- (void)dealloc {
	self.editor = nil;
  self.title = nil;
  [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}
-(void)viewWillAppear:(BOOL)animated;
{
	[editor becomeFirstResponder];
}

+(id)pushEditorForFile:(NSString*)path on:(UIViewController*)modalParent;
{
	EditorController *editor = [[[EditorController alloc] initWithNibName:NSStringFromClass(self) bundle:nil] autorelease];
  [modalParent presentModalViewController:editor animated:YES];
  editor->_modalParent = modalParent;
  editor.titleLabel.text = path;
  return editor;
}
-(IBAction)done:(id)sender;
{
	[_modalParent dismissModalViewControllerAnimated:YES];
}
@end

#pragma mark 
#pragma mark Setup

static int edit(lua_State *L)
{
  if(lua_gettop(L) != 1) {
		lua_pushstring(L, "usage: editor.edit(filename)\n");
		return 1;
	}
  
  NSString *path = [NSString stringWithUTF8String:lua_tostring(L, -1)];
  lua_pop(L, 1);
  [EditorController pushEditorForFile:path on:[ShellController shellController]];

	return 0;
}

static const luaL_Reg canvasMethods[] = {
	"edit", edit,
	
	NULL, NULL
};

@implementation EditorController (LuaExtensions)

+(void)publishModuleInState:(lua_State*)state;
{
	luaL_register(state, "editor", canvasMethods);
}

@end