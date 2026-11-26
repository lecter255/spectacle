windowPositionCalculationRegistry.registerWindowPositionCalculationWithAction(function (windowRect, visibleFrameOfSourceScreen, visibleFrameOfDestinationScreen) {
    var screen = visibleFrameOfDestinationScreen;
    return SpectacleCalculationHelpers.nextRectInResizeCycle(windowRect, function (fraction) {
        var rect = SpectacleCalculationHelpers.copyRect(screen);
        rect.width = SpectacleCalculationHelpers.lengthForFraction(screen.width, fraction);
        return rect;
    });
}, "SpectacleWindowActionLeftHalf");
