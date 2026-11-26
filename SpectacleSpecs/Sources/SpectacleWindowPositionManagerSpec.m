#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "SpectacleAccessibilityElement.h"
#import "SpectacleScreenDetectionResult.h"
#import "SpectacleScreenDetector.h"
#import "SpectacleTestHelpers.h"
#import "SpectacleWindowMover.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"
#import "SpectacleWindowPositionManager.h"

// Hand-written test doubles. These replace the OCMockito mocks the original specs used so the test
// target has no third-party dependencies.

@interface SpectacleFakeScreen : NSScreen
@property (nonatomic, assign) NSRect fakeFrame;
@property (nonatomic, assign) NSRect fakeVisibleFrame;
@end

@implementation SpectacleFakeScreen

- (NSRect)frame
{
  return _fakeFrame;
}

- (NSRect)visibleFrame
{
  return _fakeVisibleFrame;
}

@end

@interface SpectacleFakeWorkspace : NSWorkspace
@end

@implementation SpectacleFakeWorkspace

- (NSRunningApplication *)frontmostApplication
{
  return NSRunningApplication.currentApplication;
}

@end

@interface SpectacleFakeScreenDetector : SpectacleScreenDetector
@property (nonatomic, strong) SpectacleScreenDetectionResult *result;
@end

@implementation SpectacleFakeScreenDetector

- (SpectacleScreenDetectionResult *)screenWithAction:(SpectacleWindowAction *)action
                              frontmostWindowElement:(SpectacleAccessibilityElement *)frontmostWindowElement
                                             screens:(NSArray<NSScreen *> *)screens
                                          mainScreen:(NSScreen *)mainScreen
{
  return _result;
}

@end

@interface SpectacleFakeWindowPositionCalculator : SpectacleWindowPositionCalculator
/// When YES the calculator echoes back the rect it was given, simulating a no-op calculation.
@property (nonatomic, assign) BOOL returnsInputRect;
@property (nonatomic, assign) CGRect resultRect;
@property (nonatomic, assign) NSUInteger calculationCount;
@end

@implementation SpectacleFakeWindowPositionCalculator

- (SpectacleWindowPositionCalculationResult *)calculateWindowRect:(CGRect)windowRect
                                       visibleFrameOfSourceScreen:(CGRect)visibleFrameOfSourceScreen
                                  visibleFrameOfDestinationScreen:(CGRect)visibleFrameOfDestinationScreen
                                                           action:(SpectacleWindowAction *)action
{
  _calculationCount++;
  return [SpectacleWindowPositionCalculationResult resultWithAction:action
                                                         windowRect:_returnsInputRect ? windowRect : _resultRect];
}

@end

@interface SpectacleFakeAccessibilityElement : SpectacleAccessibilityElement
@property (nonatomic, assign) CGRect fakeRect;
@property (nonatomic, assign) BOOL fakeIsSheet;
@property (nonatomic, assign) BOOL fakeIsSystemDialog;
@property (nonatomic, assign) NSUInteger rectOfElementCount;
@property (nonatomic, assign) NSUInteger isSheetCount;
@property (nonatomic, assign) NSUInteger isSystemDialogCount;
@property (nonatomic, assign) NSUInteger setRectOfElementCount;
@end

@implementation SpectacleFakeAccessibilityElement

- (CGRect)rectOfElement
{
  _rectOfElementCount++;
  return _fakeRect;
}

- (void)setRectOfElement:(CGRect)rect
{
  _setRectOfElementCount++;
}

- (BOOL)isSheet
{
  _isSheetCount++;
  return _fakeIsSheet;
}

- (BOOL)isSystemDialog
{
  _isSystemDialogCount++;
  return _fakeIsSystemDialog;
}

@end

@interface SpectacleRecordingWindowMover : NSObject <SpectacleWindowMover>
@property (nonatomic, assign) NSUInteger moveCount;
@property (nonatomic, assign) CGRect lastWindowRect;
@end

@implementation SpectacleRecordingWindowMover

- (instancetype)initWithInnerWindowMover:(id<SpectacleWindowMover>)innerWindowMover
{
  return [super init];
}

+ (instancetype)newWithInnerWindowMover:(id<SpectacleWindowMover>)innerWindowMover
{
  return [[self alloc] initWithInnerWindowMover:innerWindowMover];
}

- (void)moveWindowRect:(CGRect)windowRect
         frameOfScreen:(CGRect)frameOfScreen
  visibleFrameOfScreen:(CGRect)visibleFrameOfScreen
frontmostWindowElement:(SpectacleAccessibilityElement *)frontmostWindowElement
                action:(SpectacleWindowAction *)action
{
  _moveCount++;
  _lastWindowRect = windowRect;
}

@end

@interface SpectacleWindowPositionManagerTests : XCTestCase
@end

@implementation SpectacleWindowPositionManagerTests
{
  CGRect frontmostWindowRect;
  SpectacleFakeScreen *screen;
  SpectacleFakeScreenDetector *screenDetector;
  SpectacleFakeWindowPositionCalculator *windowPositionCalculator;
  SpectacleRecordingWindowMover *windowMover;
  SpectacleFakeAccessibilityElement *accessibilityElement;
  SpectacleWindowPositionManager *windowPositionManager;
  NSUInteger failureFeedbackCount;
}

- (void)setUp
{
  [super setUp];
  frontmostWindowRect = CGRectMake(165.0f, 245.0f, 564.0f, 384.0f);
  screen = [SpectacleFakeScreen new];
  screen.fakeFrame = NSMakeRect(0.0f, 0.0f, 1440.0f, 900.0f);
  screen.fakeVisibleFrame = NSMakeRect(0.0f, 4.0f, 1440.0f, 873.0f);
  screenDetector = [SpectacleFakeScreenDetector new];
  screenDetector.result = [SpectacleScreenDetectionResult resultWithSourceScreen:screen destinationScreen:screen];
  windowPositionCalculator = [[SpectacleFakeWindowPositionCalculator alloc] initWithErrorHandler:^(NSString *message) {}];
  windowMover = [SpectacleRecordingWindowMover newWithInnerWindowMover:nil];
  accessibilityElement = [SpectacleFakeAccessibilityElement new];
  accessibilityElement.fakeRect = frontmostWindowRect;
  failureFeedbackCount = 0;
  __weak __typeof__(self) weakSelf = self;
  windowPositionManager = [[SpectacleWindowPositionManager alloc] initWithScreenDetector:screenDetector
                                                                windowPositionCalculator:windowPositionCalculator
                                                                         sharedWorkspace:[SpectacleFakeWorkspace new]
                                                                         failureFeedback:^() {
                                                                           __strong __typeof__(weakSelf) self = weakSelf;
                                                                           self->failureFeedbackCount++;
                                                                         }
                                                                             windowMover:windowMover];
}

- (void)moveWithAction:(SpectacleWindowAction *)action
{
  [windowPositionManager moveFrontmostWindowElement:accessibilityElement
                                             action:action
                                            screens:@[screen]
                                         mainScreen:screen];
}

- (void)testDoNothingIfTheFrontmostWindowIsASheet
{
  accessibilityElement.fakeIsSheet = YES;

  [self moveWithAction:kSpectacleWindowActionCenter];

  XCTAssertEqual(accessibilityElement.rectOfElementCount, 1u);
  XCTAssertEqual(accessibilityElement.isSheetCount, 1u);
  XCTAssertEqual(accessibilityElement.isSystemDialogCount, 0u);
  XCTAssertEqual(windowPositionCalculator.calculationCount, 0u);
  XCTAssertEqual(windowMover.moveCount, 0u);
  XCTAssertEqual(failureFeedbackCount, 1u);
}

- (void)testDoNothingIfTheFrontmostWindowIsASystemDialog
{
  accessibilityElement.fakeIsSystemDialog = YES;

  [self moveWithAction:kSpectacleWindowActionCenter];

  XCTAssertEqual(accessibilityElement.rectOfElementCount, 1u);
  XCTAssertEqual(accessibilityElement.isSheetCount, 1u);
  XCTAssertEqual(accessibilityElement.isSystemDialogCount, 1u);
  XCTAssertEqual(windowPositionCalculator.calculationCount, 0u);
  XCTAssertEqual(windowMover.moveCount, 0u);
  XCTAssertEqual(failureFeedbackCount, 1u);
}

- (void)testDoNothingIfTheFrontmostWindowRectIsUnavailable
{
  accessibilityElement.fakeRect = CGRectNull;

  [self moveWithAction:kSpectacleWindowActionCenter];

  XCTAssertEqual(accessibilityElement.rectOfElementCount, 1u);
  XCTAssertEqual(windowPositionCalculator.calculationCount, 0u);
  XCTAssertEqual(windowMover.moveCount, 0u);
  XCTAssertEqual(failureFeedbackCount, 1u);
}

- (void)testDoNothingIfScreenDetectionFails
{
  screenDetector.result = nil;

  [self moveWithAction:kSpectacleWindowActionCenter];

  XCTAssertEqual(windowPositionCalculator.calculationCount, 0u);
  XCTAssertEqual(windowMover.moveCount, 0u);
  XCTAssertEqual(failureFeedbackCount, 1u);
}

- (void)testDoNothingIfTheWindowPositionCalculationReturnsTheSameResults
{
  windowPositionCalculator.returnsInputRect = YES;

  [self moveWithAction:kSpectacleWindowActionCenter];

  XCTAssertEqual(windowPositionCalculator.calculationCount, 1u);
  XCTAssertEqual(windowMover.moveCount, 0u);
  XCTAssertEqual(accessibilityElement.setRectOfElementCount, 0u);
  XCTAssertEqual(failureFeedbackCount, 1u);
}

- (void)testMoveTheWindowWhenTheWindowPositionCalculationReturnsANewRect
{
  windowPositionCalculator.resultRect = CGRectMake(0.0f, 4.0f, 720.0f, 873.0f);

  [self moveWithAction:kSpectacleWindowActionLeftHalf];

  XCTAssertEqual(windowPositionCalculator.calculationCount, 1u);
  XCTAssertEqual(windowMover.moveCount, 1u);
  XCTAssertEqual(failureFeedbackCount, 0u);
}

@end
