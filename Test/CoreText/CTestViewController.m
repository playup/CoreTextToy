//
//  CTestViewController.m
//  CoreText
//
//  Created by Jonathan Wight on 1/18/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CTestViewController.h"

#import "CCoreTextLabel.h"
#import "CCoreTextLabel_HTMLExtensions.h"

@interface CTestViewController ()
@property (readonly, nonatomic, strong) IBOutlet CCoreTextLabel *label;
@end

#pragma mark -

@implementation CTestViewController

@synthesize label;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

- (void)viewDidLoad
    {
    [super viewDidLoad];
    
    self.label.markup = @"<b>Hello world</b> <a href=\"http://apple.com\">link!</a>";
    }

@end
