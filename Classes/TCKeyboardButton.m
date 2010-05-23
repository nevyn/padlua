//
//  TCKeyboardButton.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-23.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "TCKeyboardButton.h"

static SystemSoundID clickSound = 0;

static void TCCGContextAddRoundRect(CGContextRef context, CGRect rect, float ovalWidth,float ovalHeight) 
{ 
  if (ovalWidth == 0 || ovalHeight == 0) { 
    CGContextAddRect(context, rect); 
    return; 
  } 
  
  CGContextSaveGState(context); 
  CGContextTranslateCTM (context, CGRectGetMinX(rect), 
                         CGRectGetMinY(rect)); 
  CGContextScaleCTM (context, ovalWidth, ovalHeight); 
  float fw = CGRectGetWidth (rect) / ovalWidth;
  float fh = CGRectGetHeight (rect) / ovalHeight; 
  CGContextMoveToPoint(context, fw, fh/2); 
  CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1); 
  CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); 
  CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); 
  CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); 
  CGContextClosePath(context); 
  CGContextRestoreGState(context); 
} 


@implementation TCKeyboardButton
+(void)initialize;
{
	AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"click_off" ofType:@"wav"]isDirectory:NO],&clickSound);
}
@synthesize tint;
-(void)setTint:(UIColor *)tint_;
{
	[tint_ retain];
  [tint retain];
  tint = tint_;
  [self setNeedsDisplay];
}

-(id)initWithFrame:(CGRect)frame {
  if (![super initWithFrame:frame]) return nil;
  
  self.titleLabel.font = [UIFont systemFontOfSize:22];
  self.tint = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
  
  
	return self;
}
-(void)dealloc {
	[tint release];
  [super dealloc];
}

-(void)setHighlighted:(BOOL)_;
{
	[super setHighlighted:_];
  [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGRect inset = CGRectInset(rect, 6, 6);
  CGRect stroke = CGRectInset(CGRectIntegral(inset), 0.5, 0.5);
  
  CGContextSaveGState(ctx);
  CGContextSetShadow(ctx, CGSizeMake(0, 1), 2);
  TCCGContextAddRoundRect(ctx, inset, 6, 6);
  CGContextFillPath(ctx);
  CGContextRestoreGState(ctx);
  
  CGContextSaveGState(ctx);
  
  TCCGContextAddRoundRect(ctx, inset, 6, 6);
	CGContextClip(ctx);
  
  CGFloat t[4] = {1};
  const CGFloat *t0 = CGColorGetComponents(self.tint.CGColor);
  memcpy(t, t0, sizeof(CGFloat)*CGColorGetNumberOfComponents(self.tint.CGColor));
  if(self.highlighted)
  	for(int i = 0; i < 4; i++)
    	t[i] *= 0.6;
  
  CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef grad = CGGradientCreateWithColors(cspace, (CFArrayRef)[NSArray arrayWithObjects:
    (id)[UIColor colorWithRed:.882*t[0] green:.882*t[1] blue:.890*t[2] alpha:1].CGColor,
    (id)[UIColor colorWithRed:.737*t[0] green:.737*t[1] blue:.757*t[2] alpha:1].CGColor,
    nil
  ], (CGFloat[]){0,1});
  
  CGContextDrawLinearGradient(ctx, grad, CGPointMake(0, 0), CGPointMake(0, rect.size.height), 0);
  
  CGColorSpaceRelease(cspace);
  CGGradientRelease(grad);
  
  CGContextRestoreGState(ctx);
  
  TCCGContextAddRoundRect(ctx, stroke, 6, 6);
  CGContextStrokePath(ctx);

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
 	AudioServicesPlaySystemSound(clickSound);
	[super touchesBegan:touches withEvent:event];
}
@end
