import QtQuick 2.15

Rectangle {
    id: footer;

    property var buttons: [];
    property int index;
    property int total;

    signal footerButtonClicked(string sigValue);

    // Larger Tap Targets makes the footer a quarter taller, which scales the
    // buttons in it with it, and widens each button's hit area below
    height: safeArea.height * .115 * theme.fontScale * (theme.largeTargets ? 1.25 : 1);
    color: theme.current.bgColor;

    anchors {
        left: parent.left;
        right: parent.right;
        bottom: parent.bottom;
    }

    // divider
    Rectangle {
        height: 1;
        color: theme.current.dividerColor;

        anchors {
            top: parent.top;
            left: parent.left;
            leftMargin: 22;
            right: parent.right;
            rightMargin: 22;
        }
    }

    // button guide
    Row {
        spacing: parent.height * .27;

        anchors {
            verticalCenter: parent.verticalCenter;
            left: parent.left;
            leftMargin: 24;
        }

        Repeater {
            model: buttons;

            // each individual button
            ButtonLegend {
                title: modelData.title;
                key: modelData.key;
                square: modelData.square;
                visible: modelData.visible ?? true;

                MouseArea {

                    cursorShape: Qt.PointingHandCursor;
                    anchors.fill: parent;
                    // reaches past the button, into the gap around it
                    anchors.margins: theme.largeTargets ? -footer.height * .12 : 0;
                    onClicked: {
                        footerButtonClicked(modelData.sigValue);
                    }
                }
            }
        }
    }

    Text {
        text: index + ' of ' + total;
        color: theme.current.footerCountColor;
        visible: total > 0;

        anchors {
            right: parent.right;
            rightMargin: 26;
            verticalCenter: parent.verticalCenter;
        }

        font {
            pixelSize: parent.height * .33;
            letterSpacing: -0.3;
            bold: true;
        }
    }
}
