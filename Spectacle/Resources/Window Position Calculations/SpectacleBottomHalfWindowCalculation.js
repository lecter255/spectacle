windowPositionCalculationRegistry.registerWindowPositionCalculationWithAction(function (windowRect, visibleFrameOfSourceScreen, visibleFrameOfDestinationScreen) {
    var screen = visibleFrameOfDestinationScreen;
    return SpectacleCalculationHelpers.nextRectInResizeCycle(windowRect, function (fraction) {
        var rect = SpectacleCalculationHelpers.copyRect(screen);
        rect.height = SpectacleCalculationHelpers.lengthForFraction(screen.height, fraction);
        return rect;
    });
}, "SpectacleWindowActionBottomHalf");
