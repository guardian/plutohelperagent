//
//  WhiteListProcessor.m
//  PlutoHelperAgent
//
//  Created by David Allison on 21/02/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import "WhiteListProcessor.h"

@implementation WhiteListProcessor

+ (bool) checkIsInWhitelist:(NSString *)thing whiteListName:(NSString *)whiteListName prefix:(BOOL)prefix
{
  return [WhiteListProcessor checkIsInWhitelistCustom:thing whiteListName:whiteListName prefix:prefix defaults:[NSUserDefaults standardUserDefaults]];
}

+ (bool)checkIsInWhitelistCustom:(NSString *)thing whiteListName:(NSString *)whiteListName prefix:(BOOL)prefix defaults:(NSUserDefaults *)defaults
{
    NSArray *whiteListArray = [defaults arrayForKey:whiteListName];
    for (id item in whiteListArray) {
        if ([item[@"string"] isEqualTo:@""]) continue;
        if (prefix) {
            if ([thing hasPrefix:item[@"string"]]) {
                return true;
            }
        } else {
            NSArray *parts = [thing componentsSeparatedByString:@"?"];
            NSString *partZero = [parts objectAtIndex:0];
            if ([partZero hasSuffix:item[@"string"]]) {
                return true;
            }
        }
    }
    return false;
}
@end
