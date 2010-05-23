//
//  LuaOS.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "lua.h"
#import "lauxlib.h"


@interface LuaOS : NSObject
+(void)publishModuleInState:(lua_State*)state;
@end
