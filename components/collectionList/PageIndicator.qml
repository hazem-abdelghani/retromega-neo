import QtQuick 2.15

Item {
    id: pageIndicator;

    property int currentIndex: 0;
    property int pageCount: 1;
    // emitted when a dot is tapped/clicked, with that dot's index
    signal pageSelected(int index);
    // clamped at 0: with enough collections, width / pageCount drops below
    // the dot diameter and this went negative, which Row honours by
    // overlapping the dots into each other (and off the edge)
    property double itemSpacing: {
        return Math.max(0, Math.min(
            pageIndicator.width * .028 - pageIndicator.height,
            pageIndicator.width / pageCount - pageIndicator.height
        ));
    }

    Row {
        spacing: itemSpacing;
        anchors.horizontalCenter: parent.horizontalCenter;

        Repeater {
            model: pageCount;

            Rectangle {
                width: pageIndicator.height;
                height: pageIndicator.height;
                radius: pageIndicator.height / 2;

                color: theme.current.titleColor;
                opacity: currentIndex === index ? 1 : 0.2;

                // the dots themselves are only a few pixels across, far too
                // small to hit with a finger, so the tap target is a taller,
                // wider box centred on each dot. It reaches past this item's
                // bounds, which a parent only prevents when it clips
                MouseArea {
                    cursorShape: Qt.PointingHandCursor;
                    // one dot plus its gap, so neighbouring tap targets tile
                    // exactly instead of overlapping when the dots are packed
                    width: parent.width + itemSpacing;
                    height: Math.max(parent.height, 44);
                    anchors.centerIn: parent;
                    onClicked: pageIndicator.pageSelected(index);
                }
            }
        }
    }
}
