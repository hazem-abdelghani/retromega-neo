import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    property bool failed: true;
    property bool videoPlaying: false;
    property string imageSource: '';
    property bool delayedImage: false;
    property bool active: true;

    // Decode bound for the two Images below, both of which are drawn at 75%
    // of this panel. A scraped box front is routinely 1500x2100, which costs
    // ~12MB of RAM to hold as pixels and a long decode, to end up drawn a
    // few hundred pixels wide. Same treatment GameGrid and GameGallery
    // already give their cards.
    //
    // Bound to the panel's own geometry, which only changes on a resize or
    // rotation, so moving between games never re-triggers a load - see the
    // note on GameGrid's gridImage. Nothing here reads sourceSize back, so
    // the caveat about it reporting the requested bound rather than the
    // art's real dimensions doesn't bite.
    readonly property int decodeWidth: Math.round(width * .75);
    readonly property int decodeHeight: Math.round(height * .75);

    visible: {
        if (!active) return false;
        if (failed) return false;
        if (videoPlaying) return false;
        if (gameCount() === 0) return false;
        if (imageSource.length === 0) return false;

        return true;
    }

    Timer {
        id: imageDelayTimer;

        interval: 75;
        repeat: false;
        onTriggered: {
            boxartImage.source = imageSource;
        }
    }

    onImageSourceChanged: {
        if (delayedImage) {
            imageDelayTimer.restart();
        } else {
            boxartImage.source = imageSource;
        }
    }

    function delayedImageCallback(enabled) {
        delayedImage = enabled;
    }

    function dropShadowCallback(enabled) {
        if (enabled) {
            dropShadow.visible = true;
            boxartRounded.visible = false;
        } else {
            boxartRounded.visible = true;
            dropShadow.visible = false;
        }
    }

    Component.onCompleted: {
        delayedImageCallback(settings.get('delayedImage'));
        settings.addCallback('delayedImage', delayedImageCallback);

        dropShadowCallback(settings.get('dropShadow'));
        settings.addCallback('dropShadow', dropShadowCallback);
    }

    // both instances of this component happen to live as long as the theme
    // does, so nothing was actually accumulating - but GameVideo right beside
    // it cleans up after itself and this didn't, which is the kind of gap that
    // stops being harmless the moment one of these ends up in a delegate
    Component.onDestruction: {
        settings.removeCallback('delayedImage', delayedImageCallback);
        settings.removeCallback('dropShadow', dropShadowCallback);
    }

    Image {
        id: boxartBuffer;

        // invisible - displayed by the rounded element
        visible: false;
        fillMode: Image.PreserveAspectFit;
        // Loaded off the GUI thread. This used to be a synchronous load, and
        // since it's assigned the same url boxartImage has just finished
        // loading, "synchronous" meant a full PNG decode on the GUI thread
        // every single time the selection moved. On a desktop that's a few
        // milliseconds and invisible; on a low-memory handheld it's the
        // scroll stutter.
        asynchronous: true;
        // Shares boxartImage's cache entry instead of decoding the same file
        // a second time. Safe to cache now that sourceSize (below) caps what
        // a cache entry can cost.
        cache: true;
        sourceSize.width: decodeWidth;
        sourceSize.height: decodeHeight;
        width: parent.width * .75;
        height: parent.height * .75;
        anchors.centerIn: parent;
    }

    Image {
        id: boxartImage;

        // invisible - boxartBuffer is shown and updated to prevent flickering
        visible: false;
        fillMode: Image.PreserveAspectFit;
        asynchronous: true;
        cache: true;
        sourceSize.width: decodeWidth;
        sourceSize.height: decodeHeight;
        width: parent.width * .75;
        height: parent.height * .75;
        anchors.centerIn: parent;

        onStatusChanged: {
            if (status == Image.Null) {
                failed = true;
            }

            if (status == Image.Error) {
                failed = true;
            }

            if (status === Image.Ready) {
                failed = false;
                boxartBuffer.source = source;
            }
        }
    }

    Item {
        id: boxartMask;

        // invisible - displayed by the rounded element
        visible: false;
        anchors.fill: boxartBuffer;

        Rectangle {
            color: 'white';
            radius: 10;
            anchors.centerIn: parent;
            width: boxartBuffer.paintedWidth;
            height: boxartBuffer.paintedHeight;
        }
    }

    OpacityMask {
        id: boxartRounded;

        // invisible - displayed by the dropshadow element
        visible: false;
        anchors.fill: boxartBuffer;
        source: boxartBuffer;
        maskSource: boxartMask;
    }

    DropShadow {
        id: dropShadow;

        source: boxartRounded;
        anchors.fill: boxartRounded;
        color: theme.current.dropShadowColor;
        verticalOffset: 5;
        radius: 20;
        samples: 41;
        // A 41-tap blur re-run on every frame the panel is on screen, which
        // on a mobile GPU is enough on its own to keep the whole UI below
        // its frame budget. Cached, it's re-rendered when the art changes
        // and reused otherwise - which is what GameVideo's identical shadow
        // right beside this one has always done.
        cached: true;
        visible: true;
    }
}
