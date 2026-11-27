import QtQuick 2.15

// The menu a long press on a game opens: Launch, Add to / Remove from
// Favorites, and Details. Tap an entry to run it, tap anywhere outside the
// box to close it. It also answers a pad or keyboard (up/down, accept,
// cancel), which gameList/Component.qml forwards to move() and handleKey()
// while it is open.
Item {
    id: menu;

    anchors.fill: parent;
    visible: open;
    // above everything else on the screen
    z: 2000;

    property bool open: false;
    property int selected: 0;

    // 'launch', 'favorite' or 'details'
    signal chosen(string action);

    readonly property var entries: [
        { action: 'launch', label: 'Launch' },
        { action: 'favorite', label: (currentGame && currentGame.favorite) ? 'Remove from Favorites' : 'Add to Favorites' },
        { action: 'details', label: 'Details' }
    ]

    function show() {
        selected = 0;
        open = true;
    }

    function close() {
        open = false;
    }

    function move(step) {
        selected = Math.max(0, Math.min(entries.length - 1, selected + step));
    }

    function choose(index) {
        const action = entries[index].action;
        close();
        chosen(action);
    }

    // returns true when the key was handled
    function handleKey(event) {
        if (event.isAutoRepeat) return true;

        if (api.keys.isCancel(event)) {
            close();
            return true;
        }

        if (api.keys.isAccept(event)) {
            choose(selected);
            return true;
        }

        return false;
    }

    // dims the screen; a tap on it closes the menu
    Rectangle {
        anchors.fill: parent;
        color: '#b0000000';

        MouseArea {
            anchors.fill: parent;
            onClicked: menu.close();
        }
    }

    Rectangle {
        id: box;

        width: Math.min(parent.width * .8, Math.max(parent.width * .4, safeArea.height * .8));
        height: titleText.height + entryColumn.height + safeArea.height * .09;
        radius: 14;
        color: theme.current.bgColor;
        border { width: 1; color: theme.current.dividerColor; }
        anchors.centerIn: parent;

        // swallows taps inside the box so they don't reach the dimmer behind
        MouseArea { anchors.fill: parent; }

        Text {
            id: titleText;

            text: currentGame ? currentGame.title : '';
            color: theme.current.readableTextColor;
            elide: Text.ElideRight;
            horizontalAlignment: Text.AlignHCenter;
            width: parent.width - safeArea.height * .06;

            font {
                pixelSize: safeArea.height * .045;
                bold: true;
                letterSpacing: -0.3;
            }

            anchors {
                top: parent.top;
                topMargin: safeArea.height * .03;
                horizontalCenter: parent.horizontalCenter;
            }
        }

        Column {
            id: entryColumn;

            spacing: safeArea.height * .015;
            width: parent.width - safeArea.height * .06;

            anchors {
                top: titleText.bottom;
                topMargin: safeArea.height * .03;
                horizontalCenter: parent.horizontalCenter;
            }

            Repeater {
                model: menu.entries;

                Rectangle {
                    width: entryColumn.width;
                    // tall enough to hit with a finger
                    height: safeArea.height * .105;
                    radius: 10;
                    color: index === menu.selected ? theme.current.highlightColor : 'transparent';
                    border {
                        width: index === menu.selected ? 2 : 0;
                        color: theme.current.accentColor;
                    }

                    Text {
                        text: modelData.label;
                        // white on the highlight bar, theme text otherwise
                        color: index === menu.selected
                            ? theme.current.focusTextColor
                            : theme.current.readableTextColor;
                        anchors.centerIn: parent;

                        font {
                            pixelSize: safeArea.height * .045;
                            letterSpacing: -0.3;
                        }
                    }

                    MouseArea {
                        anchors.fill: parent;
                        cursorShape: Qt.PointingHandCursor;
                        onClicked: menu.choose(index);
                    }
                }
            }
        }
    }
}
