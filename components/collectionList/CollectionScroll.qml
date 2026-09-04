import QtQuick 2.15

Item {
    property int collectionCount: allCollections.length;
    property alias collectionListView: collectionListView;
    property bool muteStartup: true;

    Component.onCompleted: {
        collectionListView.currentIndex = currentCollectionIndex;
        // -1 when there's nothing to show at all (no platforms scanned and all
        // three meta-collections turned off); positionViewAtIndex warns on it
        if (currentCollectionIndex >= 0) {
            collectionListView.positionViewAtIndex(currentCollectionIndex, ListView.Center);
        }

        muteStartup = false;
    }

    Rectangle {
        width: parent.width;
        height: parent.height;
        color: 'black';
    }

    // background color, fades when collection changes
    Rectangle {
        id: backgroundColor;

        width: parent.width;
        height: parent.height;
        // Left as a live binding. Both the onCompleted above and the
        // onCurrentIndexChanged below used to assign this imperatively, which
        // destroyed the binding on the first frame and left the colour driven
        // solely by index changes - so a case that moves currentShortName
        // without moving the index (turning off "Show All Games" while sitting
        // on Last Played, say) kept painting the previous platform's colour.
        color: collectionData.getColor(currentShortName);
        opacity: theme.current.bgOpacity;

        Behavior on color {
            ColorAnimation { duration: 335; easing.type: Easing.InOutQuad; }
        }
    }

    // dots
    PageIndicator {
        currentIndex: collectionListView.currentIndex;
        pageCount: collectionCount;
        width: parent.width * .85;
        height: parent.height * .01;

        anchors {
            horizontalCenter: parent.horizontalCenter;
            bottom: parent.bottom;
            bottomMargin: 25;
        }
    }

    ListView {
        id: collectionListView;

        model: allCollections;
        delegate: lvCollectionDelegate;
        orientation: ListView.Horizontal;
        highlightRangeMode: ListView.StrictlyEnforceRange;
        preferredHighlightBegin: 0;
        preferredHighlightEnd: parent.width;
        snapMode: ListView.SnapToItem;
        highlightMoveDuration: 225;
        highlightMoveVelocity: -1;
        spacing: 50;
        anchors.fill: parent;

        onCurrentIndexChanged: {
            if (currentIndex !== currentCollectionIndex) {
                const updated = updateCollectionIndex(currentIndex, true);
                if (updated && !muteStartup) sounds.nav();
            }
        }
    }

    Component {
        id: lvCollectionDelegate;

        CollectionItem {
            width: collectionListView.width;
            height: collectionListView.height;
        }
    }
}
