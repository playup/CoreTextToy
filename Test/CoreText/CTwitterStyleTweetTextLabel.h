//
//  CTwitterStyleTweetTextLabel.h
//  CoreText
//
//  Created by Jonathan Wight on 10/27/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CCoreTextLabel.h"

@interface CTwitterStyleTweetTextLabel : CCoreTextLabel

@property (readonly, nonatomic, retain) NSArray *linkRanges;
@property (readwrite, nonatomic, assign) NSInteger selectedLinkIndex;

@end
