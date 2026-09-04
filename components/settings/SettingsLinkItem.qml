import QtQuick 2.15

// A settings row that opens another screen instead of changing a value -
// currently just the "Platforms" row under the Reorder heading, which slides
// out PlatformsPane.qml. Styled like SettingsItem but with a chevron in the
// value column instead of a toggle glyph or an option label.
Item {
    property string title: '';

    readonly property bool isCurrent: active && settingsListView.currentIndex === index;

    MouseArea {
        anchors.fill: parent;

        onClicked: {
            let muteSound = false;

            if (settingsListView.currentIndex !== index) {
                settingsListView.currentIndex = index;
                sounds.nav();
                muteSound = true;
            }

            onAcceptPressed(muteSound);
        }
    }

    Text {
        text: title;
        verticalAlignment: Text.AlignVCenter;
        color: isCurrent ? theme.current.focusTextColor : theme.current.blurTextColor;
        height: parent.height;

        font {
            pixelSize: parent.height * .43;
            letterSpacing: -0.3;
            bold: true;
        }

        anchors {
            left: parent.left;
            leftMargin: 20;
            right: chevron.left;
            rightMargin: 20;
        }
    }

    Text {
        id: chevron;

        text: '\u203A';
        verticalAlignment: Text.AlignVCenter;
        horizontalAlignment: Text.AlignRight;
        color: theme.current.accentColor;
        height: parent.height;
        width: parent.height * .6;

        font {
            pixelSize: parent.height * .5;
            bold: true;
        }

        anchors {
            right: parent.right;
            rightMargin: 20;
        }
    }
}
