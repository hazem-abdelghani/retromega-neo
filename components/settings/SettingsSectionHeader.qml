import QtQuick 2.15

// Non-interactive row used to label a group of related settings
// (e.g. "Appearance", "Sound") within the settings list.
Item {
    property string title: '';

    Text {
        text: title.toUpperCase();
        verticalAlignment: Text.AlignBottom;
        color: theme.current.accentColor;
        height: parent.height;

        font {
            pixelSize: parent.height * .32;
            letterSpacing: 1.2;
            bold: true;
        }

        anchors {
            left: parent.left;
            leftMargin: 20;
            right: parent.right;
            rightMargin: 20;
            bottom: parent.bottom;
            bottomMargin: parent.height * .18;
        }
    }
}
