import QtQuick 2.15

// Mouse wheel (and touchpad scroll) that scrolls a list's content - the
// page - and leaves the selection where it is, which is what a wheel does in
// any other program. Used on the lists that Swipe Paging makes
// non-interactive, since a Flickable only answers the wheel while it is
// interactive (WheelStepper.qml is the other way to use the wheel, for
// carousels where the wheel should change page).
//
// Declare it as a sibling of the view and turn it on only while that view is
// paging: active: pager.enabledPaging. With Swipe Paging off the view is
// interactive again and scrolls with the wheel by itself.
WheelHandler {
    id: wheel;

    // the list to scroll
    property Flickable view: null;
    // set false to ignore the wheel
    property bool active: true;
    // how far one click of a wheel scrolls
    property real pixelsPerNotch: 100;

    // emitted on every wheel event that scrolls, so a view can tell the
    // content is moving because of the wheel rather than because the mouse
    // moved (see the hover selection in settings/SettingsScroll.qml)
    signal scrolled();

    enabled: active && view !== null;
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad;

    onWheel: {
        if (view === null) return;

        // touchpads report exact pixels, wheels report 120 units per click
        const delta = event.pixelDelta.y !== 0
            ? event.pixelDelta.y
            : event.angleDelta.y / 120 * pixelsPerNotch;

        const top = view.originY - view.topMargin;
        const bottom = Math.max(top, view.originY + view.contentHeight - view.height + view.bottomMargin);

        view.cancelFlick();
        view.contentY = Math.max(top, Math.min(bottom, view.contentY - delta));
        scrolled();
    }
}
