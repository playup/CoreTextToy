//
//  CTwitterStyleTweetTextLabel.m
//  CoreText
//
//  Created by Jonathan Wight on 10/27/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CTwitterStyleTweetTextLabel.h"

#import <QuartzCore/QuartzCore.h>

#import "CMarkupValueTransformer.h"

@interface CTwitterStyleTweetTextLabel ()
@property (readwrite, nonatomic, retain) CALayer *selectionLayer;
@end

#pragma mark -

@implementation CTwitterStyleTweetTextLabel

@synthesize linkRanges;
@synthesize selectedLinkIndex;

@synthesize selectionLayer;

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
        
        selectedLinkIndex = NSNotFound;
        }
    return(self);
    }

- (void)setFrame:(CGRect)inFrame
    {
    [super setFrame:inFrame];
    
    self.selectedLinkIndex = NSNotFound;
    [self.selectionLayer removeFromSuperlayer];
    self.selectionLayer = NULL;
    }

- (NSArray *)linkRanges
    {
    if (linkRanges == NULL)
        {
        NSMutableArray *theRanges = [NSMutableArray array];
        [self.text enumerateAttribute:kMarkupLinkAttributeName inRange:(NSRange){ .length = self.text.length } options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value != NULL)
                {
                [theRanges addObject:[NSValue valueWithRange:range]];
                }
            }];
        
        linkRanges = [theRanges copy];
        }
    return(linkRanges);
    }

- (IBAction)tap:(id)sender
    {
    if (self.selectedLinkIndex == NSNotFound)
        {
        self.selectedLinkIndex = 0;
        }
    else
        {
        self.selectedLinkIndex += 1;
        self.selectedLinkIndex %= self.linkRanges.count;
        }
    
    NSRange theLinkRange = [[self.linkRanges objectAtIndex:self.selectedLinkIndex] rangeValue];
    CGRect theRect = [[[self rectsForRange:theLinkRange] objectAtIndex:0] CGRectValue];
    if (self.selectionLayer == NULL)
        {
        self.selectionLayer = [CALayer layer];
        self.selectionLayer.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5].CGColor;
        [self.layer addSublayer:self.selectionLayer];
        }

    self.selectionLayer.frame = theRect;
    }


@end
