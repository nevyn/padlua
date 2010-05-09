//
//  padluaAppDelegate.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-08.
//  Copyright Third Cog Software 2010. All rights reserved.
//

#import "padluaAppDelegate.h"

@interface padluaAppDelegate ()
@property (retain) NSString *savedCommand;
@end



static padluaAppDelegate *singleton = NULL;

void printfunc(lua_State *L, const char *output)
{
	[singleton output:[NSString stringWithUTF8String:output]];
}

@implementation padluaAppDelegate
@synthesize savedCommand;

- (void)dealloc {
	[window release];
	[super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
	singleton = self;
	
	[window makeKeyAndVisible];
	
	commandHistory = [NSMutableArray new];
	
	
	NSArray *row1 = [NSArray arrayWithObjects:
		@"↑", @"-", @"+", @"*", @"=", @"/", @"|", @"\\", @"\"", @"(", @")", @"[", @"]", @":", @"_", nil
	];
	NSArray *row2 = [NSArray arrayWithObjects:
		@"↓", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", @"{", @"}", @";", @"Run", nil
	];
	NSArray *rows = [NSArray arrayWithObjects:row1, row2, nil];
	
	CGRect scr = [UIScreen mainScreen].bounds;
	UIView *keyboardAccessory = [[[UIView alloc] initWithFrame:CGRectMake(
		0, 0, scr.size.width, rows.count*50 + rows.count
	)] autorelease];
	
	
	CGRect pen = CGRectMake(0, -50, 0, 50);
	for(int i = 0; i < [rows count]; i++) {
		NSArray *row = [rows objectAtIndex:i];
		pen.origin.y += pen.size.height + 1;
		pen.origin.x = 0;
		pen.size.width = scr.size.width/[row count] - 1;
		for(int j = 0; j < [row count]; j++) {
			NSString *title = [row objectAtIndex:j];
			UIButton *button = [[UIButton alloc] initWithFrame:pen];
			if([title isEqual:@"Run"])
				[button addTarget:self action:@selector(runCurrent:) forControlEvents:UIControlEventTouchUpInside];
			else if([title isEqual:@"↑"])
				[button addTarget:self action:@selector(olderCommand:) forControlEvents:UIControlEventTouchUpInside];
			else if([title isEqual:@"↓"])
				[button addTarget:self action:@selector(newerCommand:) forControlEvents:UIControlEventTouchUpInside];			
			else
				[button addTarget:self action:@selector(insertCharacter:) forControlEvents:UIControlEventTouchUpInside];
			[button setTitleColor:[UIColor blackColor] forState:0];
			[button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
			if([title isEqual:@"Run"] || [title isEqual:@"↑"] || [title isEqual:@"↓"])
				button.backgroundColor = [UIColor colorWithRed:.8 green:.92 blue:.8 alpha:1.];
			else
				button.backgroundColor = [UIColor whiteColor];
			[button setTitle:title forState:0];
			
			[keyboardAccessory addSubview:button];
			pen.origin.x += pen.size.width + 1;
		}
	}
	in.inputAccessoryView = keyboardAccessory;
	
	[in becomeFirstResponder];
	
	L = lua_open();
	G(L)->printfunc = printfunc;
	luaL_openlibs(L);
	luaL_dofile(L, [[[NSBundle mainBundle] pathForResource:@"repr" ofType:@"lua"] UTF8String]);
	
	return YES;
}

-(void)dumpStackIndex:(int)idx repr:(BOOL)repr;
{
	if(repr) {
		lua_getglobal(L, "serialize");
		lua_pushvalue(L, idx);
		lua_call(L, 1, 1);
	}
	size_t l;
	const char *c = lua_tolstring(L, -1, &l);
	if(c) {
		NSString *n = [[[NSString alloc] initWithBytes:c length:l encoding:NSUTF8StringEncoding] autorelease];
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
	out.text = [out.text stringByAppendingFormat:@"> %@\n", in.text];
	[commandHistory insertObject:in.text atIndex:0];
	if([commandHistory count] > 50)
		[commandHistory removeLastObject];
	commandIndex = -1;
	
	int stacktop = lua_gettop(L);
	
	NSString *withReturnPrefix = [@"return " stringByAppendingString:in.text];
	
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
	
	in.text = @"";
}
-(IBAction)olderCommand:(id)sender;
{
	int newIndex = commandIndex + 1;
	if(newIndex > [commandHistory count]-1)
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

-(void)output:(NSString *)output;
{
	out.text = [out.text stringByAppendingString:output];
}

@end
