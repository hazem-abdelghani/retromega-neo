import QtQuick 2.15

Item {
    property alias sidebarListView: sidebarListView;
    property bool sidebarFocused: true;
    // rows are a bit tighter now that the console name matches the game
    // title's font size instead of being 2x as large
    property double itemHeight: {
        return sidebarListView.height * .12 * theme.fontScale;
    }

    Component.onCompleted: {
        // see CollectionScroll.qml - -1 means there's no collection to show
        if (currentCollectionIndex >= 0) {
            sidebarListView.positionViewAtIndex(currentCollectionIndex, ListView.Center);
        }
    }

    ListView {
        id: sidebarListView;

        model: allCollections;
        delegate: lvSidebarDelegate;
        currentIndex: currentCollectionIndex;
        clip: true;
        highlightMoveDuration: 150;
        highlightRangeMode: ListView.ApplyRange;
        preferredHighlightBegin: itemHeight;
        preferredHighlightEnd: height - itemHeight;

        anchors {
            top: parent.top;
            topMargin: 12;
            bottom: parent.bottom;
            bottomMargin: 12;
            left: parent.left;
            right: parent.right;
        }

        // No onCurrentIndexChanged re-centering here. ApplyRange plus the
        // preferredHighlightBegin/End above already keep the selected console
        // a row clear of either edge and scroll only when it needs to, which
        // is how the game list beside it behaves. Calling
        // positionViewAtIndex(Center) on every change overrode that outright -
        // the range settings never got to do anything, and every single step
        // yanked the whole list so the selection stayed pinned to the middle.

        highlight: Rectangle {
            color: theme.current.highlightColor;
            radius: 0;
            width: sidebarListView.width;
            opacity: sidebarFocused ? 1 : 0.5;

            Rectangle {
                width: 4;
                color: theme.current.accentColor;
                visible: sidebarFocused;

                anchors {
                    left: parent.left;
                    top: parent.top;
                    bottom: parent.bottom;
                }
            }
        }
    }

    Component {
        id: lvSidebarDelegate;

        SidebarItem {
            width: sidebarListView.width;
            height: itemHeight;
        }
    }
}
