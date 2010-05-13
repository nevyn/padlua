//
//  LuaCanvas2D.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "LuaCanvas2D.h"

static LuaCanvas2D *singleton = nil;

@implementation LuaCanvas2D

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
	
	self.contentMode = UIViewContentModeTopLeft;
	
//	self.clipsToBounds = YES;
	
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

- (void)willRedraw;
{
	self.image = nil;
}
- (void)didRedraw;
{
	self.image = [UIImage imageWithCGImage:(CGImageRef)[(id)CGBitmapContextCreateImage(ctx) autorelease]];
}

- (void)dealloc {
	CGContextRelease(ctx);
	[super dealloc];
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
		
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canvas2d.shown"];
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
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"canvas2d.shown"];
}
@end

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

// clear(Color color)
static int clear(lua_State *L)
{
	if(lua_gettop(L) != 1) {
		lua_pushstring(L, "usage: canvas2d.clear(color)\n");
		return 1;
	}
	[singleton willRedraw];
	
	UIColor *c = colorFromLuaColor(L, lua_gettop(L));
	lua_pop(L, 1);
	
	CGContextSetFillColorWithColor(singleton->ctx, c.CGColor);
	CGContextFillRect(singleton->ctx, CGRectMake(0, 0, singleton.frame.size.width, singleton.frame.size.height));
	
	[singleton didRedraw];
	return 0;
}

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

static const luaL_Reg canvasMethods[] = {
	"clear", clear,
	"show", show,
	"hide", hide,
	
	NULL, NULL
};

@implementation LuaCanvas2D (LuaExtensions)

+(void)publishModuleInState:(lua_State*)state;
{
	luaL_register(state, "canvas2d", canvasMethods);
}

@end
