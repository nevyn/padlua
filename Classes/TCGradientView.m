//
//  TCGradientLayer.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "TCGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TCGradientView
- (id)initWithFrame:(CGRect)frame {
  if (![super initWithFrame:frame]) return nil;
  
  gradient = [CAGradientLayer layer];
  gradient.frame = (CGRect){.size=frame.size};
  gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor whiteColor] CGColor], nil];
  [self.layer insertSublayer:gradient atIndex:0];
  
  return self;
}
- (void)dealloc {
  [super dealloc];
}

-(NSArray*)colors;
{
	NSMutableArray *uicolors = [NSMutableArray array];
  for (id cgcolor in gradient.colors)
    [uicolors addObject:[UIColor colorWithCGColor:(CGColorRef)cgcolor]];
  return uicolors;
}
-(void)setColors:(NSArray *)colors;
{
	NSMutableArray *cgColors = [NSMutableArray array];
  for (UIColor *uicolor in colors)
    [cgColors addObject:(id)uicolor.CGColor];
  gradient.colors = cgColors;
}
@end
