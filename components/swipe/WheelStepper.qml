import QtQuick 2.15

// Mouse wheel (and touchpad scroll) for the lists that Swipe Paging makes
// non-interactive - a Flickable only answers the wheel while it is
// interactive. One notch of the wheel is one step: scrolling down (or right)
// asks for the NEXT item, so +1; scrolling up asks for the previous one.
// Smooth-scrolling touchpads send many small deltas, so they are added up and
// a step happens each time a whole notch's worth has built up.
//
// Declare it as a sibling of the view, like SwipePager, and turn it on only
// while that view is paging: active: pager.enabledPaging. With Swipe Paging
// off the view is interactive again and handles the wheel itself.
WheelHandler {
    id: wheel;

    // set false by the view to ignore the wheel
    property bool active: true;

    signal stepRequested(int step);

    // whether a sideways wheel (or a touchpad's sideways scroll) counts too.
    // Off for a view that scrolls sideways by itself and would otherwise
    // move twice
    property bool sideways: true;

    // wheel units per notch (Qt reports 120 for one click of a normal wheel)
    readonly property real notch: 120;
    property real accumulated: 0;

    enabled: active;
    // a plain mouse wheel and a touchpad, not touch drags (SwipePager's job)
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad;

    onWheel: {
        // a sideways wheel counts when there is no vertical movement
        const delta = event.angleDelta.y !== 0
            ? event.angleDelta.y
            : (sideways ? -event.angleDelta.x : 0);

        if (delta === 0) return;

        // changing direction starts a fresh count
        if (delta * accumulated < 0) accumulated = 0;
        accumulated += delta;

        while (accumulated <= -notch) {
            accumulated += notch;
            stepRequested(1);
        }

        while (accumulated >= notch) {
            accumulated -= notch;
            stepRequested(-1);
        }
    }

    onActiveChanged: accumulated = 0
}
