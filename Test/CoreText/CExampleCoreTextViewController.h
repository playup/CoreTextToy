//
//  CExampleCoreTextViewController.h
//  CoreText
//
//  Created by Jonathan Wight on 10/23/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CCoreTextLabel;

@interface CExampleCoreTextViewController : UIViewController

@property (readwrite, nonatomic, retain) IBOutlet CCoreTextLabel *label1;
@property (readwrite, nonatomic, retain) IBOutlet CCoreTextLabel *label2;
@property (readwrite, nonatomic, retain) IBOutlet CCoreTextLabel *label3;
@property (readwrite, nonatomic, retain) IBOutlet CCoreTextLabel *label4;

@end
