import QtQuick 2.15

// Photo-gallery style paging for touch and mouse drags: one step per swipe,
// never a continuous scroll. Declare it inside the Item that holds the view,
// as a sibling of the view (not wrapped around it): it is a pointer handler
// on that shared parent, so it sees drags anywhere on it while taps and
// clicks on the items underneath keep working. It tells the view to move one
// step with stepRequested(+1 / -1); dragging left (or up, when vertical)
// asks for the NEXT item, so +1.
//
// follow: true  - the view is shifted along with the finger by "offset",
//                 by at most one pageSize; the step happens on release if the
//                 drag went past swipeDistance, otherwise it springs back.
//                 The view must apply "offset" itself, e.g.
//                 transform: Translate { x: pager.offset; }
//                 and moves to the new item with its own animation, which adds
//                 up with the offset easing back to 0 to give one continuous
//                 motion from where the finger let go.
// follow: false - no finger tracking: the step fires as soon as the drag has
//                 moved swipeDistance (for views that scroll on their own).
//
// Hitting either end: swiping past the first or last item gives a short
// bounce instead of nothing. With follow:true the view, which has been
// dragged with resistance, springs back with an overshoot; with follow:false
// "offset" is nudged a few pixels in the swipe direction and springs back.
// Either way the view only has to apply "offset" (a Translate), and for
// follow:false views offset is otherwise always 0.
//
// Turned off by the "Swipe Paging" setting (paging == false), in which case
// the view should be interactive again.

DragHandler {
    id: pager;

    property bool horizontal: true;
    property bool follow: true;
    // pixels of travel that make up one step (item size plus gap); caps how
    // far the view follows the finger
    property real pageSize: 0;
    // pixels of movement that count as a swipe
    property real swipeDistance: 24;
    // set false by the view to ignore drags (wrong Display Mode, focus is
    // elsewhere, ...)
    property bool viewActive: true;
    // whether there is anything further in a direction: function(step) -> bool
    property var canGo: function(step) { return true; }

    // the user's "Swipe Paging" setting, tracked as a real property for the
    // same reason as every other setting - see theme.qml
    property bool paging: settings.get('swipePaging');
    readonly property bool enabledPaging: paging && viewActive;

    // how far the view is currently shifted by the drag. Follows the finger
    // exactly while dragging, and eases back to 0 on release
    property real offset: 0;

    // a release at either end of the list overshoots a little on the way
    // back; every other release just eases
    property bool bouncy: false;
    // pixels the view is nudged when a swipe has nowhere to go (follow:false)
    property real bounceDistance: 14;

    // eases the view back to rest after a release. Started explicitly rather
    // than as a Behavior: a Behavior would also animate the writes made while
    // dragging, and its "enabled" binding hasn't updated yet when
    // onActiveChanged fires. A property rather than a child because a
    // DragHandler has no default property to hold one
    property QtObject releaseAnimation: NumberAnimation {
        id: releaseAnim;

        target: pager;
        property: 'offset';
        to: 0;
        duration: pager.bouncy ? 380 : 225;
        easing.type: pager.bouncy ? Easing.OutBack : Easing.OutCubic;
        easing.overshoot: 2.4;
    }

    // the nudge for follow:false views: out a few pixels, then back with an
    // overshoot. A property rather than a child because a DragHandler has no
    // default property to hold one
    property QtObject bumpAnimation: SequentialAnimation {
        id: bumpAnim;

        property real distance: 0;

        NumberAnimation {
            target: pager;
            property: 'offset';
            to: bumpAnim.distance;
            duration: 90;
            easing.type: Easing.OutQuad;
        }

        NumberAnimation {
            target: pager;
            property: 'offset';
            to: 0;
            duration: 380;
            easing.type: Easing.OutBack;
            easing.overshoot: 2.4;
        }
    }

    signal stepRequested(int step);

    // one step per drag in follow:false mode
    property bool stepped: false;

    function pagingCallback(value) { paging = value; }

    Component.onCompleted: settings.addCallback('swipePaging', pagingCallback)
    Component.onDestruction: settings.removeCallback('swipePaging', pagingCallback)

    enabled: enabledPaging;
    target: null;
    xAxis.enabled: horizontal;
    yAxis.enabled: !horizontal;

    onEnabledPagingChanged: {
        if (enabledPaging) return;
        bumpAnim.stop();
        releaseAnim.stop();
        offset = 0;
    }

    onTranslationChanged: {
        if (!active) return;

        const t = horizontal ? translation.x : translation.y;
        const step = t < 0 ? 1 : -1;

        if (!follow) {
            if (stepped || Math.abs(t) < swipeDistance) return;
            stepped = true;
            if (canGo(step)) {
                stepRequested(step);
            } else {
                // nothing further that way: nudge the view (it moves with the
                // finger, hence the minus) and let it spring back
                bumpAnim.stop();
                bumpAnim.distance = -step * bounceDistance;
                bumpAnim.start();
            }
            return;
        }

        // clamp to one page; at either end of the list drag with
        // resistance, so it's clear there's nothing further
        offset = Math.max(-pageSize, Math.min(pageSize, canGo(step) ? t : t * .25));
    }

    onActiveChanged: {
        if (active) {
            stepped = false;
            bouncy = false;
            bumpAnim.stop();
            releaseAnim.stop();
            return;
        }

        if (!follow) return;

        const t = offset;
        const step = t < 0 ? 1 : -1;
        if (Math.abs(t) >= swipeDistance && canGo(step)) {
            stepRequested(step);
        } else if (!canGo(step) && Math.abs(t) > 1) {
            // dragged against an end: bounce back rather than just easing
            bouncy = true;
        }
        // the view's own slide to the new item and this easing back to 0
        // add up to one continuous motion from where the finger let go
        releaseAnim.start();
    }
}
