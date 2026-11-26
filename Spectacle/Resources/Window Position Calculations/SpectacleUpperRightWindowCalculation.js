windowPositionCalculationRegistry.registerWindowPositionCalculationWithAction(function (windowRect, visibleFrameOfSourceScreen, visibleFrameOfDestinationScreen) {
    var screen = visibleFrameOfDestinationScreen;
    return SpectacleCalculationHelpers.nextRectInResizeCycle(windowRect, function (fraction) {
        var rect = SpectacleCalculationHelpers.copyRect(screen);
        rect.width = SpectacleCalculationHelpers.lengthForFraction(screen.width, fraction);
        rect.x = screen.x + screen.width - rect.width;
        rect.height = Math.floor(screen.height / 2.0);
        rect.y = screen.y + screen.height - rect.height;
        return rect;
    });
}, "SpectacleWindowActionUpperRight");
