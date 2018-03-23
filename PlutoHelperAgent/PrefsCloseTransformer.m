//
//  PrefsCloseTransformer.m
//  PlutoHelperAgent
//
//  Created by Local Home on 23/03/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrefsCloseTransformer: NSValueTransformer {}
@end

@implementation PrefsCloseTransformer

+ (Class) transformedValueClass{
    return [NSString class];
}

+ (BOOL) allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    NSNumber *hasChanged = (NSNumber *)value;
    if([hasChanged boolValue]){
        return @"Save";
    } else {
        return @"Close";
    }
}
@end