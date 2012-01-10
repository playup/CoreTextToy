//
//  CCoreTextRenderer.h
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>

extern NSString *const kShadowColorAttributeName;
extern NSString *const kShadowOffsetAttributeName;
extern NSString *const kShadowBlurRadiusAttributeName;

@interface CCoreTextRenderer : NSObject

@property (readonly, nonatomic, strong) NSAttributedString *text;
@property (readonly, nonatomic, assign) CGSize size;

+ (CGSize)sizeForString:(NSAttributedString *)inString thatFits:(CGSize)size;

- (id)initWithText:(NSAttributedString *)inText size:(CGSize)inSize;

- (void)addPrerendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
- (void)addPostRendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;

- (CGSize)sizeThatFits:(CGSize)inSize;
- (void)drawInContext:(CGContextRef)inContext;

- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint;

- (NSArray *)rectsForRange:(NSRange)inRange;

@end
