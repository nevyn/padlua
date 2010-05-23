//
//  LuaOS.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "LuaOS.h"

static int ls(lua_State *L)
{
  if(lua_gettop(L) > 1) {
		lua_pushstring(L, "usage: os.ls([path])\n");
		return 1;
	}
  NSString *path = @".";
  if(lua_gettop(L) == 1)
	  path = [NSString stringWithUTF8String:lua_tostring(L, -1)];
  lua_pop(L, 1);
  
  NSError *err = nil;
  NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
  if(!paths) {
		lua_pushstring(L, [[err localizedDescription] UTF8String]);
		return 1;
  }
  
  lua_createtable(L, paths.count, 0);
  int i = 1;
  for (NSString *path in paths) {
  	lua_pushinteger(L, i++);
    lua_pushlstring(L, [path UTF8String], [path length]);
    lua_settable(L, -3);
  }

	return 1;
}

static const luaL_Reg osMethods[] = {
	"ls", ls,
	
	NULL, NULL
};

@implementation LuaOS
+(void)publishModuleInState:(lua_State*)state;
{
	luaL_register(state, "os", osMethods);
}

@end