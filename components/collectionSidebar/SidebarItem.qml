import QtQuick 2.15

Item {
    property bool isCurrent: sidebarListView.currentIndex === index;

    function iconSource() {
        // resolves aliases (e.g. Mega Drive -> genesis.png) the same way the
        // rest of the theme does, via CollectionData's alias table, then
        // reuses this theme's own per-platform icons (assets/images/icons/)
        return '../../assets/images/icons/' + collectionData.getImage(modelData.shortName) + '.png';
    }

    MouseArea {
        anchors.fill: parent;
        onClicked: {
            if (!sidebarFocused) {
                focusSidebar();
                return;
            }

            const updated = updateCollectionIndex(index);
            if (updated) {
                updateSortedCollection();
                sounds.nav();
            } else {
                focusGameList();
            }
        }
    }

    // per-platform icon, always fully opaque; centers itself in the strip
    // once the sidebar collapses down to icons-only after a console is picked.
    // No Behavior on x here - x is a pure function of parent.width, which is
    // already animating (via the sidebar's own "Behavior on width"), so x
    // already interpolates smoothly and exactly in sync with that collapse.
    // Adding a second Behavior on top would chase an already-moving target
    // and lag behind instead of moving together with the name fade below.
    Image {
        id: icon;

        // tracked separately instead of overwriting "source" directly, so a
        // missing icon for one console doesn't permanently break the binding
        // for every console this (recycled) delegate is reused for later -
        // same pattern as GameScroll.qml's highlightedDeviceImage
        property bool loadFailed: false;

        source: loadFailed ? '../../assets/images/icons/default.png' : iconSource();
        fillMode: Image.PreserveAspectFit;
        asynchronous: true;
        smooth: true;
        mipmap: true;
        // icons are 256px square and drawn at roughly a fifth of that
        sourceSize.width: Math.round(parent.height * .62);
        sourceSize.height: Math.round(parent.height * .62);
        opacity: 1;
        width: parent.height * .62;
        height: parent.height * .62;
        x: sidebarFocused ? 16 : (parent.width - width) / 2;

        anchors.verticalCenter: parent.verticalCenter;

        onStatusChanged: {
            if (status === Image.Error) {
                loadFailed = true;
            }
        }
    }

    // "modelData" is a context property and has no change signal of its own,
    // so mirror the bit we care about into a real property we can watch: when
    // a recycled delegate points at a different collection, give the real
    // artwork another chance instead of staying stuck on default.png
    readonly property string shortName: modelData.shortName;

    onShortNameChanged: {
        icon.loadFailed = false;
    }

    // console/tab name - fades out as the sidebar collapses after a console
    // is selected, and fades back in when focus returns to the sidebar.
    // Duration/easing matches the sidebar's own "Behavior on width" so the
    // name fade and the width collapse (and the icon sliding above) all
    // move together instead of one finishing before the others.
    Text {
        id: nameText;

        text: modelData.name;
        elide: Text.ElideRight;
        verticalAlignment: Text.AlignVCenter;
        color: isCurrent ? theme.current.focusTextColor : theme.current.blurTextColor;
        height: parent.height;
        opacity: sidebarFocused ? 1 : 0;

        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad; }
        }

        font {
            // matches GameItem.qml's game title size (gamesListView.height * .12 * fontScale * .43)
            // previously doubled per an earlier request; halved back down since it was too big at every font-scale setting
            pixelSize: gameScroll.gamesListView.height * .12 * theme.fontScale * .43;
            letterSpacing: -0.3;
            bold: isCurrent;
        }

        anchors {
            left: icon.right;
            leftMargin: 14;
            right: parent.right;
            rightMargin: 14;
            verticalCenter: parent.verticalCenter;
        }
    }

    // divider under Favorites, separating the meta-collections (All Games,
    // Last Played, Favorites) from the actual console list below
    Rectangle {
        visible: modelData.shortName === 'favorites';
        color: theme.current.dividerColor;
        height: 1;
        opacity: 0.7;

        anchors {
            left: parent.left;
            right: parent.right;
            leftMargin: 16;
            rightMargin: 16;
            bottom: parent.bottom;
        }
    }
}
