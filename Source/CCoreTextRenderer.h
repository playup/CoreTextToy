//
//  CCoreTextRenderer.h
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCoreTextRenderer : NSObject

@property (readwrite, nonatomic, strong) NSAttributedString *text;
@property (readwrite, nonatomic, assign) CGSize size;

+ (CGSize)sizeForString:(NSAttributedString *)inString ThatFits:(CGSize)size;

- (CGSize)sizeThatFits:(CGSize)inSize;
- (void)draw;
- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint;

@end
