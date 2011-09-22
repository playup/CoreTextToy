//
//  CMarkupValueTransformer.h
//  CoreText
//
//  Created by Jonathan Wight on 07/15/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMarkupValueTransformer : NSValueTransformer

@property (readwrite, nonatomic, retain) UIFont *standardFont;

- (id)transformedValue:(id)value error:(NSError **)outError;

- (void)resetStyles;
- (void)addStandardStyles;
- (void)addStyleAttributes:(NSDictionary *)inAttributes forTagSet:(NSSet *)inTagSet;

@end

#pragma mark -

@interface NSAttributedString (NSAttributedString_MarkupExtensions)

+ (NSAttributedString *)attributedStringWithMarkup:(NSString *)inMarkup error:(NSError **)outError;

@end