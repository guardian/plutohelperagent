//
//  WhiteListProcessorTests.m
//  PlutoHelperAgentTests
//
//  Created by David Allison on 22/02/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WhiteListProcessor.h"
#import "CCTestingUserDefaults.h"

@interface WhiteListProcessorTests : XCTestCase
@property (nonatomic, strong) CCTestingUserDefaults* defaults;
@end

@implementation WhiteListProcessorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testWhiteListProcessor {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"/Volumes/Test"},@{@"string":@"/Test"},@{@"string":@"/Check"}] forKey:@"test_list"];
    BOOL pathGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Volumes/Test" whiteListName:@"test_list" prefix:true defaults:defaults];
    XCTAssertEqual(pathGood, true);
}

- (void)testWhiteListProcessorReturnsFalse {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"/Volumes/Test"},@{@"string":@"/Test"},@{@"string":@"/Check"}] forKey:@"test_list"];
    BOOL pathGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Text" whiteListName:@"test_list" prefix:true defaults:defaults];
    XCTAssertEqual(pathGood, false);
}

- (void)testWhiteListProcessorTwoLists {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"/Volumes/Test"},@{@"string":@"/Test"},@{@"string":@"/Check"}] forKey:@"test_list"];
    [defaults setObject:@[@{@"string":@"/Volumes/Check"},@{@"string":@"/Word"},@{@"string":@"/Something"}] forKey:@"check_list"];
    BOOL pathGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Volumes/Test" whiteListName:@"test_list" prefix:true defaults:defaults];
    XCTAssertEqual(pathGood, true);
}

- (void)testWhiteListProcessorTwoListsReturnsFalse {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"/Volumes/Test"},@{@"string":@"/Test"},@{@"string":@"/Check"}] forKey:@"test_list"];
    [defaults setObject:@[@{@"string":@"/Volumes/Check"},@{@"string":@"/Word"},@{@"string":@"/Something"}] forKey:@"check_list"];
    BOOL pathGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Volumes/Test" whiteListName:@"check_list" prefix:true defaults:defaults];
    XCTAssertEqual(pathGood, false);
}

- (void)testWhiteListProcessorSuffix {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"jpeg"},@{@"string":@"zip"},@{@"string":@"prproj"}] forKey:@"test_list"];
    BOOL extensionGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Test/Test.prproj" whiteListName:@"test_list" prefix:false defaults:defaults];
    XCTAssertEqual(extensionGood, true);
}

- (void)testWhiteListProcessorSuffixReturnsFalse {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"jpeg"},@{@"string":@"zip"},@{@"string":@"prproj"}] forKey:@"test_list"];
    BOOL extensionGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Bad Things/DeleteEverything.exe" whiteListName:@"test_list" prefix:false defaults:defaults];
    XCTAssertEqual(extensionGood, false);
}

- (void)testWhiteListProcessorSuffixNotPrefix {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"/Something"},@{@"string":@"/Word"},@{@"string":@"/Volumes/Test"}] forKey:@"test_list"];
    BOOL extensionGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Volumes/Test/Test.prproj" whiteListName:@"test_list" prefix:false defaults:defaults];
    XCTAssertEqual(extensionGood, false);
}

- (void)testWhiteListProcessorPrefixNotSuffix {
    NSUserDefaults *defaults = [NSUserDefaults transientDefaults];
    [defaults setObject:@[@{@"string":@"zip"},@{@"string":@"tar"},@{@"string":@"prproj"}] forKey:@"test_list"];
    BOOL pathGood = [WhiteListProcessor checkIsInWhitelistCustom:@"/Volumes/Test/Test.prproj" whiteListName:@"test_list" prefix:true defaults:defaults];
    XCTAssertEqual(pathGood, false);
}

@end
