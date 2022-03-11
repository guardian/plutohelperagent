//
//  WhiteListProcessor.h
//  PlutoHelperAgent
//
//  Created by David Allison on 21/02/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WhiteListProcessor : NSObject

+ (bool) checkIsInWhitelist:(NSString *)thing whiteListName:(NSString *)whiteListName prefix:(BOOL)prefix;

+ (bool) checkIsInWhitelistCustom:(NSString *)thing whiteListName:(NSString *)whiteListName prefix:(BOOL)prefix defaults:(NSUserDefaults *)defaults;

@end

NS_ASSUME_NONNULL_END
