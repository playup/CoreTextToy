# CoreTextToy

This is a small test project for iOS CoreText related experimentation.

### CMarkupValueTransformer

A value transformer capable of converting _simple_ HTML into a NSAttributedString.
At the moment it only supports "b" and "i" tags (in any valid, nested combinations) but that is quite easy to expand. Each tag combination can have their set of attributes.

### UIFont_CoreTextExtensions

Extension on UIFont to get a CTFont and to get bold/italic, etc versions of the font. Scans the font name to work out the attributes of a particular font. This code is crude and effective - but needs to be tested on _all_ iOS font names (esp. the weirder ones).

### CCoreTextLabel

Beginning of a UILabel workalike that uses CoreTest to render NSAttributedString objects.

## FAQ

### Why does this even exist? Why not just use UIWebView?

UIWebViews are expensive to create and are pretty much overkill when all you need is a simple UILabel type class that shows static styled text.


### So how do I get HTML into CCoreTextLabel?

The quick way:

    NSString *theMarkup = @"<b>Hello world</b>";
    NSError *theError = NULL;
    NSString *theAttributedString = [NSAttributedString attributedStringWithMarkup:theMarkup error:&theError];
    // Error checking goes here.
    self.label.text = theAttributedString;

For the long way see "How do I add custom styles?"

### How do I add custom styles?

    // Here's the markup we want to put into our. Note the custom <username> tag
    NSString *theMarkup = [NSString stringWithFormat:@"<username>%@</username> %@", theUsername, theBody];

    NSError *theError = NULL;
    
    // Create a transformer and give it a default font.
    CMarkupValueTransformer *theTransformer = [[CMarkupValueTransformer alloc] init];
    theTransformer.standardFont = [UIFont systemFontOfSize:13];
    
    // Create custom attributes for our new "username" tag
    NSDictionary *theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor blueColor].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
        (__bridge id)[theTransformer.standardFont boldFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [theTransformer addStyleAttributes:theAttributes forTagSet:[NSSet setWithObject:@"username"]];
    
    // Transform the markup into a NSAttributedString
    NSAttributedString *theAttributedString = [theTransformer transformedValue:theMarkup error:&theError];

    // Give the attributed string to the CCoreTextLabel.
    self.label.text = theAttributedString;

## TODO

* Add more things to TODO list

## TODO (DONE)

* Support _basic_ CSS styling (changing colour of text perhaps)
* Support links
* Support tags like "p" & <s>"br"</s> that don't style the text but do control flow <ins>(br is now implemented)</ins>
* Support HTML entities
* Support tags with attributes. This is important for the "a" tag.
