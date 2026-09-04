import QtQuick 2.15
import QtGraphicalEffects 1.12

// "Cards Screenshot Preview" setting - on by default. A panel fades in over
// the bottom-right corner of the screen half a second after the selection
// settles on a game, and disappears the moment it moves again. Only ever
// fires in Grid or Gallery mode.
//
// Shared by both (instantiated once in gameList/Component.qml, anchored to
// the same rect they both use) rather than duplicated per mode, since it
// isn't drawn as part of either card layout and so has nothing mode-specific
// to account for - unlike an earlier per-card inset version of this feature,
// which this replaced.
Item {
    id: screenshotPreviewRoot;

    property bool active: true;

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline) so toggling the setting takes effect immediately - see
    // theme.qml's note on why a direct binding to settings.get() never
    // reacts to later changes
    property bool screenshotPreview: settings.get('screenshotPreview');

    function screenshotPreviewCallback(value) {
        screenshotPreview = value;
        // switching the setting off mid-countdown shouldn't leave a panel
        // primed to appear the moment it's switched back on
        if (!value) resetDwell();
    }

    // false while the card this panel belongs to has been scrolled out of
    // sight. Only Grid mode can actually get into that state (its GridView
    // scrolls independently of the selection), so that's the only caller
    // that passes anything but the default - see GameGrid.qml's
    // currentItemOnScreen. Deliberately folded into enabled_ below rather
    // than gating `visible` on its own: that way scrolling the card away
    // clears the dwell like every other disqualifying condition does, and
    // scrolling it back runs the usual preload + dwell wait instead of
    // popping the panel in and out as cards cross the edge mid-flick.
    property bool targetOnScreen: true;

    readonly property bool modeActive: theme.gridMode || theme.galleryMode;
    readonly property bool enabled_: active && modeActive && screenshotPreview && targetOnScreen;

    readonly property string screenshotSrc: {
        if (!currentGame || !currentGame.assets) return '';
        // ?? '' to match every other asset read in the theme: this is a
        // `property string`, and an absent asset coming back undefined is
        // exactly the case the guards above already exist for
        return currentGame.assets.screenshot ?? '';
    }

    // The src actually handed to the Image below, set by preloadTimer - a
    // short head start before the dwell timer, so decoding is usually
    // already finished by the time the panel is due to appear. Without
    // this, "shown" flipping true and the image's decode both started at
    // the same instant, so the panel slid in showing its own bare
    // background for a beat before the picture popped in on top of it.
    property string preloadSrc: '';

    // true once the dwell timer has fired for the game currently selected;
    // reset on every selection change so a quick scroll never shows it
    property bool dwellElapsed: false;

    // the actual reveal condition: both the dwell timer AND the decode
    // itself have to be done. The preload head start makes decode finish
    // first in the overwhelming majority of cases, but on a slow SD card it
    // might not - gating on both rather than the timer alone means the
    // panel simply waits a little longer instead of ever popping in
    // half-finished.
    readonly property bool shown: dwellElapsed && previewImage.status === Image.Ready;

    function resetDwell() {
        dwellElapsed = false;
        preloadSrc = '';
        dwellTimer.stop();
        preloadTimer.stop();
    }

    // restarts both timers on every game change while eligible, and clears
    // everything the moment it isn't (mode switched away, setting turned
    // off, or this game simply has no screenshot to show)
    function restartOrClear() {
        resetDwell();
        if (enabled_ && screenshotSrc !== '') {
            preloadTimer.restart();
            dwellTimer.restart();
        }
    }

    onScreenshotSrcChanged: restartOrClear();
    onEnabled_Changed: restartOrClear();

    visible: enabled_ && shown && screenshotSrc !== '';
    // decorative only - never intercepts the tap/click that's meant for the
    // grid or gallery card underneath it
    enabled: false;

    Timer {
        // deliberately shorter than dwellTimer - see preloadSrc above.
        // Still long enough that a fast scroll through several games in a
        // row never starts a decode for any of them.
        id: preloadTimer;
        interval: 300;
        repeat: false;
        onTriggered: screenshotPreviewRoot.preloadSrc = screenshotPreviewRoot.screenshotSrc;
    }

    Timer {
        id: dwellTimer;
        interval: 500;
        repeat: false;
        onTriggered: screenshotPreviewRoot.dwellElapsed = true;
    }

    Component.onCompleted: {
        settings.addCallback('screenshotPreview', screenshotPreviewCallback);
    }

    Component.onDestruction: {
        settings.removeCallback('screenshotPreview', screenshotPreviewCallback);
    }

    Rectangle {
        id: frame;

        radius: 10;
        color: theme.current.bgColor;
        opacity: screenshotPreviewRoot.visible ? 1 : 0;

        // Sized to the screenshot's own aspect ratio rather than a fixed
        // 16:9 box, so there's no letterbox bar showing frame's background
        // color around a 4:3 or portrait-oriented screenshot. Unknown until
        // the image has actually loaded (Pegasus doesn't expose an asset's
        // dimensions ahead of decoding it), so this starts at a 16:9 guess
        // and settles into the real shape a moment after the panel appears -
        // smoothed by the Behaviors below rather than snapping.
        readonly property real aspect: (previewImage.status === Image.Ready && previewImage.implicitHeight > 0)
            ? (previewImage.implicitWidth / previewImage.implicitHeight)
            : (16 / 9);

        // a comfortable target height, then both dimensions are scaled down
        // together (aspect stays exact either way) if that would make the
        // panel wider than reasonable for something in a corner
        readonly property real targetH: parent.height * .32;
        readonly property real targetW: targetH * aspect;
        readonly property real maxW: parent.width * .55;
        readonly property real fitScale: targetW > maxW ? (maxW / targetW) : 1;

        width: targetW * fitScale;
        height: targetH * fitScale;

        // Slides in from beyond the right edge rather than just fading in
        // place. Anchors can't be animated directly, so the right/bottom
        // anchors are replaced with explicit x/y doing the same job - x
        // sits exactly at parent's right edge (fully off-screen) while
        // hidden, and eases in to its resting spot once shown.
        x: screenshotPreviewRoot.shown ? (parent.width - width - 16) : parent.width;
        y: parent.height - height - 16;

        Behavior on width { NumberAnimation { duration: 150; } }
        Behavior on height { NumberAnimation { duration: 150; } }
        Behavior on y { NumberAnimation { duration: 150; } }
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic; } }

        Behavior on opacity { NumberAnimation { duration: 250; } }

        layer.enabled: true;
        layer.effect: DropShadow {
            color: theme.current.dropShadowColor;
            verticalOffset: 4;
            radius: 16;
            samples: 33;
            cached: true;
        }

        Image {
            id: previewImage;

            anchors.fill: parent;
            fillMode: Image.PreserveAspectFit;
            asynchronous: true;
            smooth: true;
            cache: true;
            visible: false;
            // starts decoding as soon as preloadSrc is set, well before the
            // panel is actually revealed - see preloadSrc above
            source: screenshotPreviewRoot.preloadSrc;
            // only height is capped here, deliberately not width too: Qt
            // scales the unset axis to match the file's real aspect ratio
            // while decoding, which is exactly the number frame.aspect
            // above needs. Setting both axes would let this decode at a
            // guessed 16:9 shape instead, feeding the guess back into
            // itself.
            sourceSize.height: Math.round(screenshotPreviewRoot.height * .32);
        }

        Rectangle {
            id: previewMask;
            anchors.fill: parent;
            radius: 10;
            visible: false;
        }

        OpacityMask {
            anchors.fill: parent;
            source: previewImage;
            maskSource: previewMask;
            visible: previewImage.status === Image.Ready;
        }

        Rectangle {
            anchors.fill: parent;
            radius: 10;
            color: 'transparent';
            border { width: 2; color: theme.current.accentColor; }
        }
    }
}
