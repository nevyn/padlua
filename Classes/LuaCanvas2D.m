//
//  LuaCanvas2D.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "LuaCanvas2D.h"

static LuaCanvas2D *singleton = nil;

@interface LuaCanvas2D ()
@property (retain) UIColor *strokeColor;
@property (retain) UIColor *fillColor;
@property float lineWidth;
-(void)load;
-(void)save;
@end


@implementation LuaCanvas2D
@synthesize strokeColor, fillColor, lineWidth;

- (id)commonInit;
{
	singleton = self;
	CGRect frame = self.frame;
	
	CGColorSpaceRef colorSpace = (void*)[(id)CGColorSpaceCreateDeviceRGB() autorelease];
	
	ctx = CGBitmapContextCreate(
		NULL, //bitmapData
		frame.size.width, frame.size.height, //pixelsWide/high
		8, // bits per component
		frame.size.width*4, // bytes per row
		colorSpace, 
		kCGImageAlphaPremultipliedFirst
	);
	
	CGContextScaleCTM(ctx, 1, -1);
	CGContextTranslateCTM(ctx, 0, -frame.size.height);
	
	self.contentMode = UIViewContentModeTopLeft;
	
	self.clipsToBounds = YES;
	
	self.strokeColor = [UIColor blackColor];
	self.fillColor = [UIColor blackColor];
	lineWidth = 1.;
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(save) 
												 name:UIApplicationWillTerminateNotification
											   object:nil];
	[self load];
	
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	if(![super initWithFrame:frame]) return nil;
	return [self commonInit];
}
- (id)initWithCoder:(NSCoder *)aDecoder;
{
	if(![super initWithCoder:aDecoder]) return nil;
	return [self commonInit];
}

- (void)dealloc {
	CGContextRelease(ctx);
	self.strokeColor = self.fillColor = nil;
	[super dealloc];
}

-(NSString *)dumpPath;
{
	NSArray *appSupports = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *appSupport = [appSupports objectAtIndex:0];
	NSString *dumps = [appSupport stringByAppendingPathComponent:@"canvas.png"];
	return dumps;
}

-(void)load;
{
	self.image = [UIImage imageWithContentsOfFile:self.dumpPath];
  CGContextDrawImage(ctx, (CGRect){.size=self.image.size}, self.image.CGImage);
}
-(void)save;
{
	[UIImagePNGRepresentation(self.image) writeToFile:self.dumpPath atomically:NO];
}

- (void)willRedraw;
{
	self.image = nil;
}
- (void)didRedraw;
{
	self.image = [UIImage imageWithCGImage:(CGImageRef)[(id)CGBitmapContextCreateImage(ctx) autorelease]];
}


-(void)show:(BOOL)animated;
{
	if(animated)
		[UIView beginAnimations:@"canvas" context:NULL];
	
	UIView *outContainer = [self superview];
	UIView *out = nil;
	for (UIView *other in outContainer.subviews) {
		if(other != self) {
			out = other;
			break;
		}
	}
	
	CGRect r = outContainer.frame;
	r.size.width /= 2.;
	
	r.origin.x = r.size.width + 1;
	self.frame = r;

	r.origin.x = 0;
	r.size.width -= 1;
	out.frame = r;
	
	
	if(animated)
		[UIView commitAnimations];
		
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canvas.shown"];
}

-(void)hide:(BOOL)animated;
{
	if(animated)
		[UIView beginAnimations:@"canvas" context:NULL];
	
	UIView *outContainer = [self superview];
	UIView *out = nil;
	for (UIView *other in outContainer.subviews) {
		if(other != self) {
			out = other;
			break;
		}
	}
	
	CGRect r = outContainer.frame;

	r.origin.x = 0;
	out.frame = r;

	r.origin.x = r.size.width;
	self.frame = r;
	
	
	if(animated)
		[UIView commitAnimations];
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"canvas.shown"];
}
@end


#pragma mark Helpers
static UIColor *colorFromLuaColor(lua_State *L, int tableI)
{
	float components[4] = {0,0,0,1};
	for(int i = 1; i <= 4; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, tableI);
		components[i-1] = lua_tonumber(L, -1);
		lua_pop(L, 1);
	}
	return [UIColor colorWithRed:components[0]
												 green:components[1]
													blue:components[2]
												 alpha:components[3]];
}

static int luaColorFromColor(lua_State *L, UIColor *color)
{
	lua_getglobal(L, "color"); // To be called later
	
	// Create the value table for the color to be created
	lua_createtable(L, 4, 0);
	int tableI = lua_gettop(L);
	
	const float *components = CGColorGetComponents(color.CGColor);
	
	for(int i = 1, c = CGColorGetNumberOfComponents(color.CGColor); i <= c; i++) {
		lua_pushinteger(L, i);
		lua_pushnumber(L, components[i-1]);
		lua_settable(L, tableI);
	}
	
	// Call color constructor
	if(!lua_pcall(L, 1, 1, 0)) {
		lua_pop(L, 1); // pop the error message. TODO: error handling :P
		return 0;
	}
	
	return 1;
}

static CGPoint pointFromLuaVector(lua_State *L, int vecI)
{
	float components[2] = {0,0};
	for(int i = 1; i <= 2; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, vecI);
		components[i-1] = lua_tonumber(L, -1);
		lua_pop(L, 1);
	}
	return CGPointMake(components[0], components[1]);
}

#pragma mark Meta
static int show(lua_State *L)
{
	[singleton show:YES];
	return 0;
}

static int hide(lua_State *L)
{
	[singleton hide:YES];
	return 0;
}

#pragma mark Drawing
// clear(Color color)
static int clear(lua_State *L)
{
	if(lua_gettop(L) != 1) {
		lua_pushstring(L, "usage: canvas.clear(color)\n");
		return 1;
	}
	[singleton willRedraw];
	
	UIColor *c = colorFromLuaColor(L, lua_gettop(L));
	lua_pop(L, 1);
	CGContextSaveGState(singleton->ctx);
	CGContextSetFillColorWithColor(singleton->ctx, c.CGColor);
	CGContextFillRect(singleton->ctx, CGRectMake(0, 0, singleton.frame.size.width, singleton.frame.size.height));
	CGContextRestoreGState(singleton->ctx);
	
	[singleton didRedraw];
	return 0;
}


// move(vector{x,y})
static int move(lua_State *L)
{

	CGPoint p;
  if(lua_gettop(L) == 1)
		p = pointFromLuaVector(L, lua_gettop(L));
  else if(lua_gettop(L) == 2) {
  	p.x = lua_tonumber(L, -2);
    p.y = lua_tonumber(L, -1);
  } else {
		lua_pushstring(L, "usage: canvas.move(vector{x,y})\n"
			"\tMoves the pen to the given point without drawing anything\n");
		return 1;
	}
	lua_pop(L, lua_gettop(L));
	CGContextMoveToPoint(singleton->ctx, p.x, p.y);
	
	return 0;
}

// lineTo(vector{x,y})
static int lineTo(lua_State *L)
{
	CGPoint p;
  if(lua_gettop(L) == 1)
		p = pointFromLuaVector(L, lua_gettop(L));
  else if(lua_gettop(L) == 2) {
  	p.x = lua_tonumber(L, -2);
    p.y = lua_tonumber(L, -1);
  } else {
      lua_pushstring(L, "usage: canvas.lineTo(vector{x,y})\n"
			"\tMoves the pen to the given point, and adds a straight line to the current\n"
			"\t path on the way there.\n");
		return 1;
  }
	lua_pop(L, lua_gettop(L));
	CGContextAddLineToPoint(singleton->ctx, p.x, p.y);
	
	return 0;
}

// strokeColor([color])
static int getSetStrokeColor(lua_State *L)
{
	if(lua_gettop(L) == 0) {
		return luaColorFromColor(L, singleton.strokeColor);
	} else if(lua_gettop(L) == 1) {
		UIColor *c = colorFromLuaColor(L, lua_gettop(L));
		lua_pop(L, 1);
		singleton.strokeColor = c;
		CGContextSetStrokeColorWithColor(singleton->ctx, c.CGColor);
		return 0;
	} else {
		lua_pushstring(L, "usage: canvas.strokeColor([color])\n"
			"\tGets color used to stroke paths with if called without arguments,\n"
			"\tor sets it if called with one argument.\n"
		);
		return 1;	
	}
}

// fillColor([color])
static int getSetFillColor(lua_State *L)
{
	if(lua_gettop(L) == 0) {
		return luaColorFromColor(L, singleton.fillColor);
	} else if(lua_gettop(L) == 1) {
		UIColor *c = colorFromLuaColor(L, lua_gettop(L));
		lua_pop(L, 1);
		singleton.fillColor = c;
		CGContextSetFillColorWithColor(singleton->ctx, c.CGColor);
		return 0;
	} else {
		lua_pushstring(L, "usage: canvas.fillColor([color])\n"
			"\tGets color used to fill paths with if called without arguments,\n"
			"\tor sets it if called with one argument.\n"
		);
		return 1;	
	}
}

// color([color])
static int getSetColor(lua_State *L)
{
	if(lua_gettop(L) == 0) {
		return luaColorFromColor(L, singleton.fillColor);
	} else if(lua_gettop(L) == 1) {
		UIColor *c = colorFromLuaColor(L, lua_gettop(L));
		lua_pop(L, 1);
		singleton.fillColor = c;
		singleton.strokeColor = c;
		CGContextSetStrokeColorWithColor(singleton->ctx, c.CGColor);
		CGContextSetFillColorWithColor(singleton->ctx, c.CGColor);
		return 0;
	} else {
		lua_pushstring(L, "usage: canvas.color([color])\n"
			"\tGets color used to stroke and fill paths with if called\n"
			"\twithout arguments, or sets it if called with one argument.\n"
		);
		return 1;	
	}
}

// lineWidth([number])
static int getSetLineWidth(lua_State *L)
{
	if(lua_gettop(L) == 0) {
		lua_pushnumber(L, singleton.lineWidth);
		return 1;
	} else if(lua_gettop(L) == 1) {
		float l = lua_tonumber(L, -1);
		lua_pop(L, 1);
		singleton.lineWidth = l;
		CGContextSetLineWidth(singleton->ctx, l);
		return 0;
	} else {
		lua_pushstring(L, "usage: canvas.lineWidth([width])\n"
			"\tGets width used to stroke paths with if called\n"
			"\twithout arguments, or sets it if called with one argument.\n"
		);
		return 1;	
	}
}


// stroke()
static int stroke(lua_State *L)
{
	if(lua_gettop(L) != 0) {
		lua_pushstring(L, "usage: canvas.stroke()\n"
			"\tStrokes the current path with the current color.\n"
		);
		return 1;
	}
	[singleton willRedraw];
	CGContextStrokePath(singleton->ctx);
	[singleton didRedraw];
	return 0;
}

// fill()
static int fill(lua_State *L)
{
	if(lua_gettop(L) != 0) {
		lua_pushstring(L, "usage: canvas.fill()\n"
			"\tFills the current path with the current color.\n"
		);
		return 1;
	}
	[singleton willRedraw];
	CGContextFillPath(singleton->ctx);
	[singleton didRedraw];
	return 0;
}




#pragma mark Setup

static const luaL_Reg canvasMethods[] = {
	"clear", clear,
	"show", show,
	"hide", hide,
	"move", move,
	"lineTo", lineTo,
	"strokeColor", getSetStrokeColor,
	"fillColor", getSetFillColor,
	"color", getSetColor,
	"lineWidth", getSetLineWidth,
	"stroke", stroke,
	"fill", fill,
	
	NULL, NULL
};

@implementation LuaCanvas2D (LuaExtensions)

+(void)publishModuleInState:(lua_State*)state;
{
	luaL_register(state, "canvas", canvasMethods);
}

@end
