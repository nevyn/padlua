//
//  EditorController.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "EditorController.h"
#import "ShellController.h"

@interface EditorController ()
@property (retain) NSURL *path;
-(void)save;
@end

@implementation EditorController
@synthesize editor, titleLabel, path;
-(id)initWithPath:(NSString*)path_;
{
	if(![super initWithNibName:NSStringFromClass(self.class) bundle:nil]) return nil;
  
	self.path = [[NSURL fileURLWithPath:path_] absoluteURL];
  
  NSArray *docss = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docs = [docss objectAtIndex:0];
	NSString *absDocs = [[[[NSURL fileURLWithPath:docs] absoluteURL] absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost/var/" withString:@"file://localhost/private/var/"];
	
  if(![[self.path absoluteString] hasPrefix:absDocs]) {
  	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't edit outside of Documents" message:@"You are not allowed to edit documents outside of your Documents folder" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self release];
    return nil;
  }
  
  return self;
}
- (void)dealloc {
	self.editor = nil;
  self.titleLabel = nil;
  self.path = nil;
  [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}
-(void)viewDidLoad;
{
	self.titleLabel.text = [[self.path path] lastPathComponent];
  self.editor.text = [NSString stringWithContentsOfURL:self.path encoding:NSUTF8StringEncoding error:nil];
}
-(void)viewWillAppear:(BOOL)animated;
{
	[editor becomeFirstResponder];
}

+(id)pushEditorForFile:(NSString*)path on:(UIViewController*)modalParent;
{
	EditorController *editor = [[[EditorController alloc] initWithPath:path] autorelease];
  if(!editor) return nil;
  
  [modalParent presentModalViewController:editor animated:YES];
  editor->_modalParent = modalParent;
  return editor;
}
-(IBAction)done:(id)sender;
{
	[self save];
	[_modalParent dismissModalViewControllerAnimated:YES];
}
-(IBAction)runAndClose:(id)sender;
{
	[self save];
	NSString *cmd = [NSString stringWithFormat:@"dofile(\"%@\")", [path path]];
	[[ShellController shellController] runCommand:cmd saveToHistory:NO];
	[_modalParent dismissModalViewControllerAnimated:YES];
}

-(void)save;
{
	[editor.text writeToURL:self.path atomically:YES encoding:NSUTF8StringEncoding error:nil];
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