#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

/**
 * Asserts that two CGRects are equal, printing both rects on failure so that a broken window
 * position calculation is easy to diagnose from the test log.
 */
#define SpectacleAssertEqualRects(actualRect, expectedRect)                                       \
  do {                                                                                            \
    CGRect _spectacleActualRect = (actualRect);                                                   \
    CGRect _spectacleExpectedRect = (expectedRect);                                               \
    XCTAssertTrue(CGRectEqualToRect(_spectacleActualRect, _spectacleExpectedRect),                \
                  @"%@ is not equal to %@",                                                       \
                  NSStringFromRect(NSRectFromCGRect(_spectacleActualRect)),                       \
                  NSStringFromRect(NSRectFromCGRect(_spectacleExpectedRect)));                    \
  } while (0)
