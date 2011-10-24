//
//  CCoreTextRenderer.h
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>

@interface CCoreTextRenderer : NSObject

@property (readonly, nonatomic, strong) NSAttributedString *text;
@property (readonly, nonatomic, assign) CGSize size;
@property (readonly, nonatomic, assign) UITextAlignment textAlignment; // default is UITextAlignmentLeft
@property (readonly, nonatomic, assign) UILineBreakMode lineBreakMode; // default is UILineBreakModeTailTruncation. used for single and multiple lines of text


+ (CGSize)sizeForString:(NSAttributedString *)inString ThatFits:(CGSize)size;

- (id)initWithText:(NSAttributedString *)inText size:(CGSize)inSize textAlignment:(UITextAlignment)inTextAlignment lineBreakMode:(UILineBreakMode)inLineBreakMode;

- (void)addPrerendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
- (void)addPostRendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;

- (CGSize)sizeThatFits:(CGSize)inSize;
- (void)draw;
- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint;

@end
