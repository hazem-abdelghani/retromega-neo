import QtQuick 2.15
import QtGraphicalEffects 1.12

Rectangle {
    property bool showDivider: true;
    property string shade: 'light';
    property bool showTitle: false;
    property bool showSettings: true;
    property string title: '';

    property bool showBattery: {
        return !isNaN(api.device.batteryPercent);
    }

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline in the logo Image's "visible" binding) so toggling the setting
    // updates the header immediately - see theme.qml's note on why a direct
    // binding to settings.get() never reacts to later changes
    property bool collectionLogos: settings.get('collectionLogos');
    property bool logoDropShadow: settings.get('dropShadow');

    // only swap in a logo for the collection-name case (no explicit title
    // override, e.g. 'Settings'), and only when that collection has one
    property bool showLogo: {
        return title.length === 0
            && collectionLogos
            && collectionData.hasLogo(currentShortName);
    }

    function collectionLogosCallback(value) {
        collectionLogos = value;
    }

    function logoDropShadowCallback(value) {
        logoDropShadow = value;
    }

    Component.onCompleted: {
        settings.addCallback('collectionLogos', collectionLogosCallback);
        settings.addCallback('dropShadow', logoDropShadowCallback);
    }

    Component.onDestruction: {
        settings.removeCallback('collectionLogos', collectionLogosCallback);
        settings.removeCallback('dropShadow', logoDropShadowCallback);
    }

    property double titleWidth: {
        return root.width - headerWidgets.width
            - (2 * headerWidgets.anchors.rightMargin)
            - headerTitle.anchors.leftMargin;
    }

    color: 'transparent';
    height: root.height * .115 * theme.fontScale;

    anchors {
        left: parent.left;
        right: parent.right;
        top: parent.top;
    }

    // divider
    Rectangle {
        height: 1;
        color: theme.current.dividerColor;
        visible: showDivider;

        anchors {
            bottom: parent.bottom;
            left: parent.left;
            leftMargin: 22;
            right: parent.right;
            rightMargin: 22;
        }
    }

    Text {
        id: headerTitle;

        visible: showTitle && !showLogo;
        text: title.length > 0
            ? title
            : (currentCollection ? currentCollection.name : '');
        color: title.length > 0
            ? theme.current.defaultHeaderNameColor
            : collectionData.getColor(currentShortName);
        opacity: theme.current.bgOpacity;
        width: titleWidth;
        elide: Text.ElideRight;

        anchors {
            left: parent.left;
            leftMargin: parent.height * .30;
            verticalCenter: parent.verticalCenter;
        }

        font {
            pixelSize: parent.height * .33;
            letterSpacing: -0.3;
            bold: true;
        }
    }

    Image {
        id: headerLogo;

        visible: showTitle && showLogo;
        source: showLogo ? '../../assets/images/collections/' + collectionData.getCollectionImage(currentShortName) + '.png' : '';
        width: titleWidth;
        height: parent.height * .55;
        fillMode: Image.PreserveAspectFit;
        horizontalAlignment: Image.AlignLeft;
        verticalAlignment: Image.AlignVCenter;
        opacity: theme.current.bgOpacity;
        asynchronous: true;
        smooth: true;
        // decoded at the height it's drawn at rather than the source's full
        // 1920px - see CollectionItem's collectionLogo. Deliberately not
        // bound to titleWidth, which moves as the title changes
        sourceSize.height: Math.round(parent.height * .55);

        layer.enabled: logoDropShadow;
        layer.effect: DropShadow {
            color: '#30000000';
            verticalOffset: 5;
            radius: 20;
            samples: 41;
            cached: true;
        }

        anchors {
            left: parent.left;
            leftMargin: parent.height * .30;
            verticalCenter: parent.verticalCenter;
        }
    }

    Row {
        id: headerWidgets;

        property string shade: parent.shade;
        spacing: parent.height * .30;
        height: parent.height;

        anchors {
            right: parent.right;
            rightMargin: parent.height * .30;
        }

        // the Search button used to live here; it now lives in each screen's
        // footer beside Attract (Collection Screen) or Details (Game List),
        // matching the physical L2/R2 pairing
        Clock {
            id: clock;

            shade: parent.shade;
            height: parent.height;
            opacity: 0.5;
        }

        Battery {
            id: battery;

            visible: showBattery;
            // dimming now happens per-part inside Battery.qml: the outline and
            // terminal stay at half opacity to match the clock beside them,
            // while the fill renders its charging/low colors at full strength
            opacity: 1.0;
            shade: parent.shade;
            height: parent.height * .25;
            width: parent.height * .55;
            anchors.verticalCenter: parent.verticalCenter;
        }

        Text {
            id: settingsIcon;

            visible: showSettings
            text: glyphs.settings;
            opacity: 0.5;
            color: parent.shade === 'light'
                ? theme.current.settingsColorLight
                : theme.current.settingsColorDark;
            anchors.verticalCenter: parent.verticalCenter;

            font {
                family: glyphs.name;
                pixelSize: parent.height * .33;
            }

            MouseArea {
                anchors.fill: parent;
                onClicked: {
                    if (currentView === 'settings') {
                        // same exit path as the B button, so tapping the icon
                        // to close Settings also lands on the Collection Screen
                        settingsComponent.onCancelPressed();
                    } else {
                        // no previousView bookkeeping - Settings always exits
                        // to the Collection Screen and never reads it back
                        currentView = 'settings';
                        sounds.forward();
                    }
                }
            }
        }
    }
}
