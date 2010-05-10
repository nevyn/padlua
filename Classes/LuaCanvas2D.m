//
//  LuaCanvas2D.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "LuaCanvas2D.h"


@implementation LuaCanvas2D


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}

@end


static int printHello(lua_State *L)
{
	NSLog(@"Hello world!");
	lua_pushstring(L, "Hello world\n");
	return 1;
}

static const luaL_Reg canvasMethods[] = {
	"printHello", printHello,
	
	NULL, NULL
};

@implementation LuaCanvas2D (LuaExtensions)

+(void)publishModuleInState:(lua_State*)state;
{
	luaL_register(state, "canvas2d", canvasMethods);
}

@end
