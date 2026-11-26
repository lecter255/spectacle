#import "SpectacleAccessibilityElement.h"

#import <AppKit/AppKit.h>

@implementation SpectacleAccessibilityElement
{
  AXUIElementRef _underlyingElement;
}

- (instancetype)init
{
  if (self = [super init]) {
    _underlyingElement = NULL;
  }

  return self;
}

+ (SpectacleAccessibilityElement *)frontmostApplicationElement
{
  NSRunningApplication *frontmostApplication = [NSWorkspace sharedWorkspace].frontmostApplication;
  if (!frontmostApplication) {
    return nil;
  }
  SpectacleAccessibilityElement *frontmostApplicationElement = [SpectacleAccessibilityElement new];
  AXUIElementRef underlyingElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier);
  frontmostApplicationElement.underlyingElement = underlyingElement;
  CFRelease(underlyingElement);
  return frontmostApplicationElement;
}

+ (SpectacleAccessibilityElement *)frontmostWindowElement
{
  SpectacleAccessibilityElement *frontmostApplicationElement = [SpectacleAccessibilityElement frontmostApplicationElement];
  SpectacleAccessibilityElement *frontmostWindowElement = nil;
  if (frontmostApplicationElement) {
    frontmostWindowElement = [frontmostApplicationElement elementWithAttribute:kAXFocusedWindowAttribute];
    if (!frontmostWindowElement) {
      NSLog(@"Invalid accessibility element provided, unable to determine the size and position of the window.");
    }
  } else {
    NSLog(@"Failed to find the application that currently has focus.");
  }
  return frontmostWindowElement;
}

- (SpectacleAccessibilityElement *)elementWithAttribute:(CFStringRef)attribute
{
  SpectacleAccessibilityElement *newElement = nil;
  if (_underlyingElement == NULL) {
    return nil;
  }
  AXUIElementRef underlyingElement = NULL;
  AXError result = AXUIElementCopyAttributeValue(_underlyingElement, attribute, (CFTypeRef *)&underlyingElement);
  if (result == kAXErrorSuccess && underlyingElement != NULL) {
    newElement = [SpectacleAccessibilityElement new];
    newElement.underlyingElement = underlyingElement;
    CFRelease(underlyingElement);
  } else {
    NSLog(@"Unable to obtain the accessibility element with the specified attribute: %@ (error code %d)", attribute, result);
  }
  return newElement;
}

- (NSString *)stringValueOfAttribute:(CFStringRef)attribute
{
  if (_underlyingElement != NULL && CFGetTypeID(_underlyingElement) == AXUIElementGetTypeID()) {
    CFTypeRef value = NULL;
    AXError result;
    result = AXUIElementCopyAttributeValue(_underlyingElement, attribute, &value);
    if (result == kAXErrorSuccess && value != NULL) {
      if (CFGetTypeID(value) == CFStringGetTypeID()) {
        return CFBridgingRelease(value);
      }
      CFRelease(value);
    } else {
      NSLog(@"There was a problem getting the string value of the specified attribute: %@ (error code %d)", attribute, result);
    }
  }
  return nil;
}

- (AXValueRef)valueOfAttribute:(CFStringRef)attribute type:(AXValueType)type
{
  if (_underlyingElement != NULL && CFGetTypeID(_underlyingElement) == AXUIElementGetTypeID()) {
    CFTypeRef value = NULL;
    AXError result;
    result = AXUIElementCopyAttributeValue(_underlyingElement, attribute, &value);
    if ((result == kAXErrorSuccess)
        && (value != NULL)
        && (CFGetTypeID(value) == AXValueGetTypeID())
        && (AXValueGetType((AXValueRef)value) == type)) {
      return (AXValueRef)value;
    } else {
      if (value != NULL) {
        CFRelease(value);
      }
      NSLog(@"There was a problem getting the value of the specified attribute: %@ (error code %d)", attribute, result);
    }
  }
  return NULL;
}

- (void)setValue:(AXValueRef)value forAttribute:(CFStringRef)attribute
{
  AXError result = AXUIElementSetAttributeValue(_underlyingElement, attribute, value);
  if (result != kAXErrorSuccess) {
    NSLog(@"There was a problem setting the value of the specified attribute: %@ (error code %d)", attribute, result);
  }
}

- (CGRect)rectOfElement
{
  CGRect result = CGRectNull;
  AXValueRef positionValue = [self valueOfAttribute:kAXPositionAttribute type:kAXValueCGPointType];
  AXValueRef sizeValue = [self valueOfAttribute:kAXSizeAttribute type:kAXValueCGSizeType];
  CGPoint position;
  CGSize size;
  // Only read the values once both are known to be non-NULL; previously AXValueGetValue was
  // called on a possibly-NULL value, and one value leaked when the other lookup failed.
  if ((positionValue != NULL)
      && (sizeValue != NULL)
      && AXValueGetValue(positionValue, kAXValueCGPointType, (void *)&position)
      && AXValueGetValue(sizeValue, kAXValueCGSizeType, (void *)&size)) {
    result = CGRectMake(position.x, position.y, size.width, size.height);
  }
  if (positionValue != NULL) {
    CFRelease(positionValue);
  }
  if (sizeValue != NULL) {
    CFRelease(sizeValue);
  }
  return result;
}

- (void)setRectOfElement:(CGRect)rect
{
  AXValueRef positionRef;
  AXValueRef sizeRef;
  positionRef = AXValueCreate(kAXValueCGPointType, (const void *)&rect.origin);
  sizeRef = AXValueCreate(kAXValueCGSizeType, (const void *)&rect.size);
  [self setValue:sizeRef forAttribute:kAXSizeAttribute];
  [self setValue:positionRef forAttribute:kAXPositionAttribute];
  [self setValue:sizeRef forAttribute:kAXSizeAttribute];
  CFRelease(positionRef);
  CFRelease(sizeRef);
}

+ (CGRect)normalizeCoordinatesOfRect:(CGRect)rect frameOfScreen:(CGRect)frameOfScreen
{
  CGRect frameOfScreenWithMenuBar = NSScreen.screens.firstObject.frame;
  rect.origin.y = frameOfScreen.size.height - NSMaxY(rect) + (frameOfScreenWithMenuBar.size.height - frameOfScreen.size.height);
  return rect;
}

- (BOOL)isSheet
{
  return [[self stringValueOfAttribute:kAXRoleAttribute] isEqualToString:(__bridge NSString *)kAXSheetRole];
}

- (BOOL)isSystemDialog
{
  return [[self stringValueOfAttribute:kAXSubroleAttribute] isEqualToString:(__bridge NSString *)kAXSystemDialogSubrole];
}

- (void)dealloc
{
  if (_underlyingElement != NULL) {
    CFRelease(_underlyingElement);
  }
}

- (void)setUnderlyingElement:(AXUIElementRef)underlyingElement
{
  if (_underlyingElement != NULL) {
    CFRelease(_underlyingElement);
  }
  _underlyingElement = CFRetain(underlyingElement);
}

@end
