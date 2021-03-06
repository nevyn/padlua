    //
//  ShellController.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "ShellController.h"
#import "EditorController.h"
#import "LuaOS.h"
#import "TCKeyboardButton.h"
#import "TCGradientView.h"

@interface ShellController ()
@property (retain) NSString *savedCommand;
-(void)load;
-(void)save;

-(void)dumpStackIndex:(int)idx repr:(BOOL)repr;
-(void)dumpStackDownTo:(int)downTo repr:(BOOL)repr prefix:(NSString*)prefix;

-(void)scrollToBottom;
@end

static ShellController *singleton = NULL;

void printfunc(lua_State *L, const char *output)
{
	[singleton output:[NSString stringWithUTF8String:output]];
}

int LuaNSDataWriter(lua_State *L, const void* p, size_t sz, void* ud)
{
	NSMutableData *d = (NSMutableData*)ud;
	[d appendBytes:p length:sz];
	return 0;
}

struct DataReaderTemp {
	NSData *d;
	BOOL done;
};
const char * LuaNSDataReader(lua_State *L, void *ud, size_t *sz)
{
	struct DataReaderTemp *d = (struct DataReaderTemp *)ud;
	if(!d->done) {
		d->done = YES;
		*sz = [d->d length];
		return [d->d bytes];
	} else {
		*sz = 0;
		return NULL;
	}
}


@implementation ShellController
@synthesize savedCommand;
+(id)shellController;
{
	return singleton;
}
#pragma mark 
#pragma mark Init/teardown
#pragma mark -

-(UIView*)keyboardAccessory;
{
	NSArray *row0 = [NSArray arrayWithObjects:
  	@"Run", @"Help", @"Add", @"{", @"}", @"(", @")", @"[", @"]", @"<", @">", nil
  ];
	NSArray *row1 = [NSArray arrayWithObjects:
		@"↑", @"-", @"+", @"*", @"=", @"/", @"|", @"\\", @"\"", @";", @":", nil
	];
	NSArray *row2 = [NSArray arrayWithObjects:
		@"↓", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", nil
	];
	NSArray *rows = [NSArray arrayWithObjects:row0, row1, row2, nil];
	static const float buttonHeight = 64;
	CGRect scr = [UIScreen mainScreen].bounds;
	TCGradientView *keyboardAccessory = [[[TCGradientView alloc] initWithFrame:CGRectMake(
		0, 0, scr.size.width, rows.count*buttonHeight + 3
	)] autorelease];
  keyboardAccessory.colors = [NSArray arrayWithObjects:
  	[UIColor colorWithRed:.712 green:.708 blue:.751 alpha:1],
    [UIColor colorWithRed:.439 green:.443 blue:.471 alpha:1],
    nil
  ];
  UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scr.size.width, 1)];
  line1.backgroundColor = [UIColor blackColor];
  UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(0, 1, scr.size.width, 1)];
  line2.backgroundColor = [UIColor colorWithWhite:0.749 alpha:1];
  [keyboardAccessory addSubview:line1]; [keyboardAccessory addSubview:line2];
  
	
	
	CGRect pen = CGRectMake(4, -buttonHeight, 0, buttonHeight);
	for(int i = 0; i < [rows count]; i++) {
		NSArray *row = [rows objectAtIndex:i];
		pen.origin.y += pen.size.height;
		pen.origin.x = 0;
		pen.size.width = ceil((scr.size.width-5)/[row count]);
		for(int j = 0; j < [row count]; j++) {
			NSString *title = [row objectAtIndex:j];
			TCKeyboardButton *button = [[TCKeyboardButton alloc] initWithFrame:pen];
			if([title isEqual:@"Run"])
				[button addTarget:self action:@selector(runCurrent:) forControlEvents:UIControlEventTouchUpInside];
			else if([title isEqual:@"↑"])
				[button addTarget:self action:@selector(olderCommand:) forControlEvents:UIControlEventTouchUpInside];
			else if([title isEqual:@"↓"])
				[button addTarget:self action:@selector(newerCommand:) forControlEvents:UIControlEventTouchUpInside];
			else if([title isEqual:@"⌘"])
				[button addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
			else if([title isEqual:@"Help"])
				[button addTarget:self action:@selector(showHelp:) forControlEvents:UIControlEventTouchUpInside];
			else
				[button addTarget:self action:@selector(insertCharacter:) forControlEvents:UIControlEventTouchUpInside];
			[button setTitleColor:[UIColor blackColor] forState:0];
			if(title.length > 1 || [title characterAtIndex:0] > 255)
				button.tint = [UIColor colorWithRed:.85 green:.85 blue:.95 alpha:1];
			[button setTitle:title forState:0];
			
			[keyboardAccessory addSubview:button];
			pen.origin.x += pen.size.width;
		}
	}
	
	return keyboardAccessory;
}
-(void)commonInit;
{
	singleton = self;
	commandHistory = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"commandHistory"] mutableCopy];
	commandIndex = -1;
	
	NSString *libDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"lib"];
	
	NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *userLibDir = [[docDirs objectAtIndex:0] stringByAppendingPathComponent:@"lib"];
	NSString *newEnv = [NSString stringWithFormat:@"%@/?.lua;%@/?.lua;;", userLibDir, libDir];
	setenv(LUA_PATH, [newEnv UTF8String], YES);
	
	[[NSFileManager defaultManager] changeCurrentDirectoryPath:[docDirs objectAtIndex:0]];
	
	L = lua_open();
	G(L)->printfunc = printfunc;
	luaL_openlibs(L);
	[LuaCanvas2D publishModuleInState:L];
  [EditorController publishModuleInState:L];
  [LuaOS publishModuleInState:L];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	if (![super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
		return nil;
	
	[self commonInit];
	
	return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder;
{
	if(![super initWithCoder:aDecoder]) return nil;
	
	[self commonInit];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(save) 
												 name:UIApplicationWillTerminateNotification
											   object:nil];
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	in.inputAccessoryView = [self keyboardAccessory];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"canvas.shown"])
		[canvas show:NO];
	else
		[canvas hide:NO];
	
	in.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"inHistory"];
	out.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"outHistory"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	NSArray *loadedLibs = [NSArray array];
	for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"lua" inDirectory:@"lib"]) {
		BOOL success = luaL_loadfile(L, [path UTF8String]) == 0;
		if(success)
			success = lua_pcall(L, 0, 0, 0) == 0;
		if(success)
			loadedLibs = [loadedLibs arrayByAddingObject:[path lastPathComponent]];
		else {
			[self output:[NSString stringWithFormat:@"Error loading %@: ", [path lastPathComponent]]];
			[self dumpStackIndex:-1 repr:NO];
			lua_pop(L, 1);
		}

	}
	//[self output:[NSString stringWithFormat:@"Loaded libraries %@; functions ", [loadedLibs componentsJoinedByString:@", "]]];
	
	[self load];
	
	[self scrollToBottom];	
	[in becomeFirstResponder];	
}

- (void)didReceiveMemoryWarning;
{
    [super didReceiveMemoryWarning];
		lua_gc(L, LUA_GCCOLLECT, 0);
}


- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.;
	[container release]; container = nil;
	[in release]; in = nil;
	[out release]; out = nil;
}

- (void)dealloc {
	lua_close(L); L = NULL;
	[commandHistory release]; commandHistory = nil;
	self.savedCommand = nil;
	
	[container release];
		[outContainer release];
			[out release];
			[canvas release];
		[in release];
		
	[settings release];
	
	[helpController release];
	
	[super dealloc];
}


-(NSString *)dumpsPath;
{
	NSArray *appSupports = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *appSupport = [appSupports objectAtIndex:0];
	NSString *dumps = [appSupport stringByAppendingPathComponent:@"dumps"];
	return dumps;
}

-(void)save;
{
	[[NSUserDefaults standardUserDefaults] setObject:in.text forKey:@"inHistory"];
	[[NSUserDefaults standardUserDefaults] setObject:out.text forKey:@"outHistory"];
	[[NSUserDefaults standardUserDefaults] setObject:commandHistory forKey:@"commandHistory"];
	
	NSString *dumps = [self dumpsPath];
	[[NSFileManager defaultManager] removeItemAtPath:dumps error:nil];
	[[NSFileManager defaultManager] createDirectoryAtPath:dumps withIntermediateDirectories:YES attributes:nil error:nil];

	for (NSString *funcname in [[NSUserDefaults standardUserDefaults] arrayForKey:@"functionsToSave"]) {
		lua_getglobal(L, [funcname UTF8String]);
		NSMutableData *d = [NSMutableData data];
		int status = lua_dump(L, LuaNSDataWriter, d);
		if(status != 0) {
			[self output:[NSString stringWithFormat:@"Error dumping %@: %d\n", funcname, status]];
		} else {
			[self output:[NSString stringWithFormat:@"Dumped %@\n", funcname]];
			NSString *funcdumpPath = [dumps stringByAppendingPathComponent:funcname];
			[d writeToFile:funcdumpPath atomically:NO];
		}

		lua_pop(L, 1);
	}
}
-(void)load;
{
	NSString *dumps = [self dumpsPath];
	NSArray *successfulLoads = [NSArray array];

	for (NSString *funcname in [[NSFileManager defaultManager] directoryContentsAtPath:dumps]) {
		NSString *fullPath = [dumps stringByAppendingPathComponent:funcname];
		struct DataReaderTemp dataTemp;
		dataTemp.done = NO;
		dataTemp.d = [NSData dataWithContentsOfFile:fullPath];
		if(!dataTemp.d) continue;
		
		int status = lua_load(L, LuaNSDataReader, &dataTemp, [funcname UTF8String]);
		if(status != 0) {
			[self output:[NSString stringWithFormat:@"Error loading function %@: ", funcname, status]];
			[self dumpStackIndex:-1 repr:NO];
			lua_pop(L, 1);
		} else {
			lua_setglobal(L, [funcname UTF8String]);
			successfulLoads = [successfulLoads arrayByAddingObject:funcname];
		}
	}
	//[self output:[[successfulLoads componentsJoinedByString:@", "] stringByAppendingString:@"\n"]];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

-(void)scrollToBottom;
{
  if(out.text.length > 0)
		[out scrollRangeToVisible:NSMakeRange(out.text.length, 1)];
}

#pragma mark 
#pragma mark Shell commands
#pragma mark -

-(void)dumpStackIndex:(int)idx repr:(BOOL)repr;
{
	if(repr) {
		// If the object at idx has __tostring in its metatable, use that instead of serialize
		int before = lua_gettop(L);
		luaL_getmetafield(L, idx, "__tostring");
		BOOL foundToString = lua_gettop(L) != before;
		
		if(!foundToString)
			lua_getglobal(L, "serialize");
			
		lua_pushvalue(L, idx);
		lua_call(L, 1, 1);
	}
	
	size_t l;
	const char *c = lua_tolstring(L, -1, &l);
	if(c) {
		NSString *n = [[[NSString alloc] initWithBytes:c length:l encoding:NSUTF8StringEncoding] autorelease];
		if([n componentsSeparatedByString:@"\n"].count > 1)
			[self output:@"\n"];
		[self output:n];
		[self output:@"\n"];
	}
	if(repr)
		lua_pop(L, 1);
}

-(void)dumpStackDownTo:(int)downTo repr:(BOOL)repr prefix:(NSString*)prefix;
{
	for(int i = lua_gettop(L); i > downTo; i--) {
		[self output:[NSString stringWithFormat:@"%@%d: ", prefix, i]];
		[self dumpStackIndex:i repr:repr];
	}
}

-(IBAction)insertCharacter:(UIButton*)sender;
{
	NSMutableString *newIn = [[in.text mutableCopy] autorelease];
	NSRange selRange = in.selectedRange;
	[newIn insertString:sender.currentTitle atIndex:NSMaxRange(selRange)];
	in.text = newIn;
	in.selectedRange = NSMakeRange(selRange.location+[sender currentTitle].length, 0);
}
-(IBAction)runCurrent:(UIButton*)sender;
{
	[self runCommand:in.text saveToHistory:YES];
	in.text = @"";
}
-(void)runCommand:(NSString*)command saveToHistory:(BOOL)save;
{
	if(save) {
	  [self output:[NSString stringWithFormat:@"> %@\n", command]];
		[commandHistory insertObject:command atIndex:0];
		if([commandHistory count] > 50)
			[commandHistory removeLastObject];
		commandIndex = -1;
  }
	
	const int stacktop = lua_gettop(L);
	
	NSString *withReturnPrefix = [@"return " stringByAppendingString:command];
	
	BOOL successfulParse = luaL_loadstring(L, [withReturnPrefix UTF8String]) == 0;
	if(!successfulParse) {
		lua_pop(L, 1); // Remove the error
		successfulParse = luaL_loadstring(L, [in.text UTF8String]) == 0;
	}
	if(!successfulParse) {
		[self dumpStackDownTo:stacktop repr:NO prefix:@"Parse error "];
	} else {
		BOOL runError = lua_pcall(L, 0, LUA_MULTRET, 0) != 0;
		if(runError)
			[self dumpStackDownTo:stacktop repr:!runError prefix:@"Run error "];
		else {
			for(int i = stacktop+1; i <= lua_gettop(L); i++) {
				NSString *retname = [NSString stringWithFormat:@"ret%d", i];

				lua_pushvalue(L, i);
				lua_setglobal(L, [retname UTF8String]);

				[self output:[NSString stringWithFormat:@"%@: ", retname]];
				[self dumpStackIndex:i repr:YES];

			}
		}
	}
	
	lua_pop(L, lua_gettop(L)-stacktop);
}

-(IBAction)olderCommand:(id)sender;
{
	int newIndex = commandIndex + 1;
	if(newIndex > (int)([commandHistory count]-1))
		return;
	
	if(commandIndex == -1)
		self.savedCommand = in.text;
	commandIndex = newIndex;
	
	in.text = [commandHistory objectAtIndex:commandIndex];
}
-(IBAction)newerCommand:(id)sender;
{
	int newIndex = commandIndex - 1;
	if(newIndex < -1)
		return;
	commandIndex = newIndex;
	
	if(commandIndex == -1) {
		in.text = self.savedCommand;
		self.savedCommand = nil;
	} else {
		in.text = [commandHistory objectAtIndex:commandIndex];
	}		
}

static const int kMaxLinesOfScrollback = 100;

-(void)output:(NSString *)output;
{
	NSString *newOut = [out.text stringByAppendingString:output];
	NSArray *lines = [newOut componentsSeparatedByString:@"\n"];
	if(lines.count > kMaxLinesOfScrollback) {
		NSArray *newLines = [lines subarrayWithRange:NSMakeRange(lines.count-kMaxLinesOfScrollback, kMaxLinesOfScrollback)];
		newOut = [newLines componentsJoinedByString:@"\n"];
	}
	out.text = newOut;
	[self scrollToBottom];
}
-(IBAction)showSettings:(UIButton*)sender;
{
	UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:settings];
	popover.delegate = self;
	popover.popoverContentSize = settings.container.frame.size;
	CGRect buttonRect = [sender convertRect:[sender frame] toView:self.view.window];
	buttonRect.origin.x -= 50;
	buttonRect.size = CGSizeMake(0,0);
	[popover presentPopoverFromRect:buttonRect
													 inView:self.view.window
				 permittedArrowDirections:UIPopoverArrowDirectionDown
												 animated:YES];
}
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popover;
{
	[popover release];
}

-(IBAction)showHelp:(UIButton*)sender;
{
	if(!helpController) {
		UIViewController *vc = [[[UIViewController alloc] init] autorelease];
		UIWebView *web = [[[UIWebView alloc] initWithFrame:vc.view.frame] autorelease];
		vc.view = web;
		vc.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalViewControllerAnimated:)] autorelease]; 
		vc.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:web action:@selector(goBack)] autorelease]; 

		vc.title = @"Lua Reference Manual";
		helpController = [[UINavigationController alloc] initWithRootViewController:vc];
		[web loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"manual" ofType:@"html"]]]];
	}
	[self presentModalViewController:helpController animated:YES];
}


#pragma mark
#pragma mark Responding to keyboard events
#pragma mark -

- (void)keyboardWillShow:(NSNotification *)notification {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */

    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];

    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = self.view.bounds;
    newTextViewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    container.frame = newTextViewFrame;

    [UIView commitAnimations];
}
- (void)keyboardDidShow:(NSNotification*)notif;
{
	[self scrollToBottom];
}


- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary* userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    container.frame = self.view.bounds;
    
    [UIView commitAnimations];
}

@end
