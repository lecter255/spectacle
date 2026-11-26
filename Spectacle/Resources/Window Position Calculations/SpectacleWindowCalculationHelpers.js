var SpectacleCalculationHelpers = (function () {
    var copyRect = function(rect) {
        return {
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
        };
    };
    var rectCenteredWithinRect = function(rect1, rect2) {
        var centeredMidX = Math.abs(CGRectGetMidX(rect2) - CGRectGetMidX(rect1)) <= 1.0;
        var centeredMidY = Math.abs(CGRectGetMidY(rect2) - CGRectGetMidY(rect1)) <= 1.0;
        return CGRectContainsRect(rect1, rect2) && centeredMidX && centeredMidY;
    };
    var rectFitsWithinRect = function(rect1, rect2) {
        return (rect1.width <= rect2.width) && (rect1.height <= rect2.height);
    };
    // The sizes that repeated presses of a half or corner shortcut step through, as fractions of
    // the screen. The first press lands on 1/2, and each further press moves to the next size,
    // wrapping around: 1/2, 2/3, 3/4, 1/4, 1/3, then 1/2 again.
    var resizeCycleFractions = [
        {numerator: 1, denominator: 2},
        {numerator: 2, denominator: 3},
        {numerator: 3, denominator: 4},
        {numerator: 1, denominator: 4},
        {numerator: 1, denominator: 3},
    ];
    var lengthForFraction = function(length, fraction) {
        return Math.floor(length * fraction.numerator / fraction.denominator);
    };
    // rectForFraction(fraction) builds the target rect for one size in the cycle. Returns the rect
    // for the size after the one the window currently occupies, or the 1/2 rect if it occupies none.
    var nextRectInResizeCycle = function(windowRect, rectForFraction) {
        var count = resizeCycleFractions.length;
        for (var i = 0; i < count; i++) {
            if (rectCenteredWithinRect(rectForFraction(resizeCycleFractions[i]), windowRect)) {
                return rectForFraction(resizeCycleFractions[(i + 1) % count]);
            }
        }
        return rectForFraction(resizeCycleFractions[0]);
    };
    return {
        copyRect: copyRect,
        lengthForFraction: lengthForFraction,
        nextRectInResizeCycle: nextRectInResizeCycle,
        rectCenteredWithinRect: rectCenteredWithinRect,
        rectFitsWithinRect: rectFitsWithinRect,
    };
})();
