//
//  HelperFunctions.m
//  PlutoHelperAgent
//
//  Created by David Allison on 08/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import "HelperFunctions.h"

@implementation HelperFunctions

+ (NSString *) getLatestVersion:(NSArray *)versionsArray {
    NSMutableArray *processedVersionsArray = [NSMutableArray new];
    for (id version in versionsArray) {
        NSString *versionForProcessing = version;
        NSUInteger numberOfOccurrencesInVersion = [[versionForProcessing componentsSeparatedByString:@"."] count] - 1;
        if (numberOfOccurrencesInVersion == 0) {
            versionForProcessing = [NSString stringWithFormat:@"%@00", versionForProcessing];
        } else if (numberOfOccurrencesInVersion == 1) {
            versionForProcessing = [NSString stringWithFormat:@"%@0", versionForProcessing];
        }
        NSUInteger versionStringLength = [versionForProcessing length];
        if (versionStringLength == 5) {
            versionForProcessing = [NSString stringWithFormat:@"0%@", versionForProcessing];
        }
        [processedVersionsArray addObject:versionForProcessing];
    }
    NSArray *sortedProcessedVersionsArray = [processedVersionsArray sortedArrayUsingComparator:
                                ^NSComparisonResult(id obj1, id obj2){
                                    return [obj2 compare:obj1];
                                }];
    NSString *requiredVersion = sortedProcessedVersionsArray[0];
    if ([[requiredVersion substringToIndex:1] isEqualTo:@"0"]) {
        requiredVersion = [requiredVersion substringFromIndex:1];
    }
    return requiredVersion;
}

+ (NSMutableDictionary *)parseURLQueryToDictionary:(NSString *)url {
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSRange range = [url rangeOfString:@"?"];
    if (range.location == NSNotFound) {
        return queryStringDictionary;
    }
    url = [url substringFromIndex:(range.location + 1)];
    range = [url rangeOfString:@"#"];
    if (range.location != NSNotFound) {
        url = [url substringToIndex:(range.location)];
    }
    NSArray *urlComponents = [url componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        if ([key length] == 0) {
            continue;
        }
        [queryStringDictionary setObject:value forKey:key];
    }
    return queryStringDictionary;
}

@end
