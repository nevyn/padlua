    //
//  SettingsController.m
//  padlua
//
//  Created by Joachim Bengtsson on 2010-05-09.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "SettingsController.h"

@interface SettingsController ()
@property (readwrite, retain) UIView *container;

@end


@implementation SettingsController
@synthesize container;
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


-(void)viewWillAppear:(BOOL)animated;
{
	NSArray *funcsave = [[NSUserDefaults standardUserDefaults] arrayForKey:@"functionsToSave"];
	functionsToSave.text = [funcsave componentsJoinedByString:@" "];
}
-(void)viewWillDisappear:(BOOL)animated;
{
	NSArray *funcsave = [functionsToSave.text componentsSeparatedByString:@" "];
	[[NSUserDefaults standardUserDefaults] setObject:funcsave
																						forKey:@"functionsToSave"];
}

@end
