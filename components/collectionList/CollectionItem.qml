import QtQuick 2.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2

Item {
    // tracked as a real QML property (rather than re-reading settings.get()
    // inline in the image "source" binding) so toggling the setting updates
    // the art immediately - see theme.qml's note on why a direct binding
    // to settings.get() never reacts to later changes
    property bool compactDeviceArt: settings.get('compactDeviceArt');

    // same pattern as compactDeviceArt above: tracked as a real QML property
    // so toggling the setting updates the collection list immediately
    property bool collectionLogos: settings.get('collectionLogos');

    // matches GameItem.qml's logoDropShadow: reuses the shared dropShadow
    // setting so the logo's shadow toggles alongside every other image/video
    property bool logoDropShadow: settings.get('dropShadow');

    // assets/images/collections/ only has logos for some platforms; when the
    // current collection isn't one of them, fall back to the text title
    // instead of showing a broken image
    property bool showLogo: {
        return collectionLogos && collectionData.hasLogo(modelData.shortName);
    }

    // "modelData" is a context property with no change signal of its own, so
    // mirror the bit we care about into a real property we can watch - same
    // pattern as SidebarItem.qml. When a recycled delegate points at a
    // different collection, give the real device art another chance instead
    // of leaving it stuck on default.png.
    readonly property string shortName: modelData.shortName;

    onShortNameChanged: {
        device.loadFailed = false;
    }

    function compactDeviceArtCallback(value) {
        compactDeviceArt = value;
    }

    function collectionLogosCallback(value) {
        collectionLogos = value;
    }

    function logoDropShadowCallback(value) {
        logoDropShadow = value;
    }

    Component.onCompleted: {
        settings.addCallback('compactDeviceArt', compactDeviceArtCallback);
        settings.addCallback('collectionLogos', collectionLogosCallback);
        settings.addCallback('dropShadow', logoDropShadowCallback);
    }

    Component.onDestruction: {
        settings.removeCallback('compactDeviceArt', compactDeviceArtCallback);
        settings.removeCallback('collectionLogos', collectionLogosCallback);
        settings.removeCallback('dropShadow', logoDropShadowCallback);
    }

    MouseArea {
        anchors.fill: parent;
        onClicked: {
            collectionListView.currentIndex = index;
            onAcceptPressed();
        }
    }

    // background stripe
    Image {
        source: '../../assets/images/stripe.png';
        fillMode: Image.PreserveAspectFit;
        horizontalAlignment: Image.AlignRight;

        anchors {
            fill: parent;
            rightMargin: 70;
        }
    }

    DropShadow {
        visible: !showLogo;
        source: title;
        verticalOffset: 10;
        color: '#30000000';
        radius: 20;
        samples: 41;
        cached: true;
        anchors.fill: title;
    }

    Text {
        id: title;

        visible: !showLogo;
        text: modelData.name;
        color: theme.current.titleColor;
        width: root.width * .46;
        wrapMode: Text.WordWrap;
        lineHeight: 0.8;

        font {
            pixelSize: root.height * .075;
            bold: true;
        }

        anchors {
            verticalCenter: parent.verticalCenter;
            left: parent.left;
            leftMargin: 30;
            verticalCenterOffset: -5;
        }
    }

    Image {
        id: collectionLogo;

        visible: showLogo;
        source: showLogo ? '../../assets/images/collections/' + collectionData.getCollectionImage(modelData.shortName) + '.png' : '';
        width: root.width * .23;
        height: root.height * .15;
        fillMode: Image.PreserveAspectFit;
        horizontalAlignment: Image.AlignLeft;
        verticalAlignment: Image.AlignVCenter;
        asynchronous: true;
        smooth: true;
        // collection logos are up to 1920px wide and drawn one row tall.
        // Height only, so PreserveAspectFit works out the width - binding
        // the width as well would reload every time the slot resized
        sourceSize.height: Math.round(root.height * .15);

        layer.enabled: logoDropShadow;
        layer.effect: DropShadow {
            color: '#30000000';
            verticalOffset: 10;
            radius: 20;
            samples: 41;
            cached: true;
        }

        anchors {
            verticalCenter: parent.verticalCenter;
            left: parent.left;
            leftMargin: 30;
            verticalCenterOffset: -5;
        }
    }

    // Unfiltered, the collection already knows how many games it holds, so
    // the proxy below is only worth building while a search is actually
    // running. It used to be unconditional: every card on screen - including
    // All Games - maintained a full index mapping of its whole collection
    // purely to render this one number.
    property int visibleGameCount: {
        if (nameFilter === '') return modelData.games.count;
        return filteredGamesCollection.count;
    }

    Text {
        id: gamesCount;

        text: visibleGameCount
            + (visibleGameCount === 1 ? ' game' : ' games');
        color: theme.current.titleColor;
        opacity: 0.7;

        anchors {
            left: parent.left;
            leftMargin: 30;
            top: showLogo ? undefined : title.bottom;
            topMargin: showLogo ? undefined : root.height * .02;
            bottom: showLogo ? parent.bottom : undefined;
            bottomMargin: showLogo ? root.height * .05 : undefined;
        }

        font {
            pixelSize: root.height * .03;
            letterSpacing: -0.3;
            bold: true;
        }
    }

    SortFilterProxyModel {
        id: filteredGamesCollection;

        // null while there's nothing to filter, so the proxy holds no mapping
        // at all - same pattern the game list layouts use for the two Display
        // Modes that aren't on screen
        sourceModel: nameFilter === '' ? null : modelData.games;
        filters: [
            RegExpFilter { roleName: 'title'; pattern: nameFilterPattern; caseSensitivity: Qt.CaseInsensitive; }
        ]
    }

    Text {
        id: vendorYear;

        visible: !showLogo;
        text: collectionData.getVendorYear(modelData.shortName);
        color: theme.current.titleColor;
        opacity: 0.7;

        font {
            capitalization: Font.AllUppercase;
            pixelSize: root.height * .025;
            letterSpacing: 1.3;
            bold: true;
        }

        anchors {
            left: parent.left;
            leftMargin: 30;
            bottom: title.top;
        }
    }

    Image {
        id: device;

        // Same fallback GameScroll's highlightedDeviceImage and SidebarItem's
        // icon already had, and the only one of the three that was missing it.
        // 26 platforms in CollectionData's own metadata table (Atari 2600, C64,
        // MSX, DOS, ScummVM, Ports and friends) resolve to a filename that
        // isn't in assets/images/devices, so the right-hand side of their
        // carousel card came up empty instead of showing the generic console.
        //
        // Tracked as a flag rather than by overwriting "source", so one
        // missing image doesn't permanently break the binding for every
        // collection this recycled delegate is reused for afterwards.
        property bool loadFailed: false;

        source: {
            const dir = compactDeviceArt
                ? '../../assets/images/devicesCompact/'
                : '../../assets/images/devices/';

            if (loadFailed) return dir + 'default.png';

            return dir + collectionData.getImage(modelData.shortName) + '.png';
        }

        onStatusChanged: {
            if (status === Image.Error) {
                loadFailed = true;
            }
        }

        width: root.width * .50;
        height: root.height * .65;
        fillMode: Image.PreserveAspectFit;
        horizontalAlignment: Image.AlignHCenter;
        asynchronous: true;
        smooth: true;
        // see GameScroll's highlightedDeviceImage - full-size device art is
        // far larger than the slot it's drawn in, and the carousel holds
        // several of these at once
        sourceSize.width: Math.round(root.width * .50);
        sourceSize.height: Math.round(root.height * .65);
        visible: true;

        anchors {
            verticalCenter: parent.verticalCenter;
            verticalCenterOffset: 10;
            right: parent.right;
            rightMargin: root.width * .02;
        }
    }

    // DropShadow {
    //     source: device;
    //     verticalOffset: 10;
    //     color: '#30000000';
    //     radius: 20;
    //     samples: 41;
    //     cached: true;
    //     anchors.fill: device;
    // }
}
