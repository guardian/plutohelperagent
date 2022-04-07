//
//  GetRequiredVersionTests.m
//  PlutoHelperAgentTests
//
//  Created by David Allison on 07/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GetRequiredVersion.h"

@interface GetRequiredVersionTests : XCTestCase

@end

@implementation GetRequiredVersionTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetRequiredVersion {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",nil];
    NSString *outputVersion = [GetRequiredVersion getRequiredVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"2.0.0");
}

- (void)testGetRequiredVersionWithFourVersions {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",@"15.2.1",@"15.2.2",nil];
    NSString *outputVersion = [GetRequiredVersion getRequiredVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"15.2.2");
}

- (void)testGetRequiredVersionWithFiveVersions {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",@"15.2.1",@"15.2.2",@"16.1.0",nil];
    NSString *outputVersion = [GetRequiredVersion getRequiredVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"16.1.0");
}

- (void)testGetRequiredVersionWithSixVersions {
    NSArray *testArray = [[NSArray alloc] initWithObjects:@"2.0.0",@"1.0.0",@"15.2.1",@"15.2.2",@"16.1.0",@"18.0.0",nil];
    NSString *outputVersion = [GetRequiredVersion getRequiredVersion:testArray];
    XCTAssertEqualObjects(outputVersion, @"18.0.0");
}

@end

