//
//  LuaCanvas2D.h
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "lua.h"
#import "lauxlib.h"

@interface LuaCanvas2D : UIView {

}
@end

@interface LuaCanvas2D (LuaExtensions)
+(void)publishModuleInState:(lua_State*)state;
@end