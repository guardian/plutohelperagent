//
//  HelperFunctionsTests.m
//  PlutoHelperAgentTests
//
//  Created by David Allison on 07/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../PlutoHelperAgent/HelperFunctions.h"

@interface HelperFunctionsTests : XCTestCase

@end

@implementation HelperFunctionsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetLatestVersion {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",nil];
    NSString *outputVersion = [HelperFunctions getLatestVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"2.0.0");
}

- (void)testGetLatestVersionWithFourVersions {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",@"15.2.1",@"15.2.2",nil];
    NSString *outputVersion = [HelperFunctions getLatestVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"15.2.2");
}

- (void)testGetLatestVersionWithFiveVersions {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",@"15.2.1",@"15.2.2",@"16.1.0",nil];
    NSString *outputVersion = [HelperFunctions getLatestVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"16.1.0");
}

- (void)testGetLatestVersionWithSixVersions {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",@"15.2.1",@"15.2.2",@"16.1.0",@"18.0.0",nil];
    NSString *outputVersion = [HelperFunctions getLatestVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"18.0.0");
}

- (void)testParseUrlQueryToDiction {
    NSMutableDictionary *outputDictionary = [HelperFunctions parseURLQueryToDictionary:@"http://test/test.html?test=1&test2=2&test3=3"];
    NSDictionary *testDictionary = @{ @"test"  : @"1",
                                      @"test2" : @"2",
                                      @"test3" : @"3" };
    XCTAssertEqualObjects(outputDictionary, testDictionary);
}

@end

