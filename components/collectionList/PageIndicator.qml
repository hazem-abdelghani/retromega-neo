import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: pageIndicator;

    property int currentIndex: 0;
    property int pageCount: 1;
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
            }
        }
    }
}
