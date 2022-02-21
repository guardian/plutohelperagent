//
//  WhiteListProcessor.m
//  PlutoHelperAgent
//
//  Created by David Allison on 21/02/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import "WhiteListProcessor.h"

@implementation WhiteListProcessor

+ (bool)checkIsInWhitelist:(NSString *)thing whiteListName:(NSString *)whiteListName prefix:(BOOL)prefix
{
    NSArray *whiteListArray = [[NSUserDefaults standardUserDefaults] arrayForKey:whiteListName];
    for (id item in whiteListArray) {
        if ([item[@"string"] isNotEqualTo:@""]) {
            if (prefix) {
                if ([thing hasPrefix:item[@"string"]]) {
                    return true;
                }
            } else {
                if ([thing hasSuffix:item[@"string"]]) {
                    return true;
                }
            }
        }
    }
    return false;
}
@end
