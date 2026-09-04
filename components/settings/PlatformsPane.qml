import QtQuick 2.15

// Slide-in panel on the right-hand side of the Settings screen, opened from
// the "Platforms" row under the Reorder heading. Holds the real platform
// collections (i.e. excluding the synthetic All Games/Last Played/Favorites
// entries) and restores the original grab/drop reordering: Accept picks the
// highlighted platform up, Up/Down move it, Accept drops it and saves, Cancel
// backs out. Persists to api.memory as 'collectionOrder' - an array of
// collection shortNames - the same key theme.qml's loadCollectionOrder()/
// allCollections read from.
Item {
    id: platformsPaneRoot;

    property bool open: false;
    property bool grabbed: false;

    // editable working copy of theme.qml's collectionOrder - kept separate so
    // in-progress reordering (before a drop) doesn't reshuffle the Collection
    // Screen and Game List behind the panel on every single step
    property var order: [];

    function clamp(min, val, max) { return Math.max(min, Math.min(val, max)); }

    // called each time the panel is opened, so it always reflects the order
    // that's actually in effect rather than a stale copy from last time
    function load() {
        if (Array.isArray(collectionOrder) && collectionOrder.length > 0) {
            order = collectionOrder.slice();
        } else {
            // loadCollectionOrder() always leaves a complete list, so this is
            // only reached before it has run
            const def = [];
            const raw = api.collections.toVarArray();
            for (let i = 0; i < raw.length; i++) def.push(raw[i].shortName);
            order = def;
        }

        grabbed = false;
        platformsListView.currentIndex = 0;
        platformsListView.positionViewAtBeginning();
    }

    function save() {
        api.memory.set('collectionOrder', order.slice());
        collectionOrder = order.slice();
    }

    function moveItem(fromPos, toPos) {
        if (fromPos === toPos) return;

        fromPos = clamp(0, fromPos, order.length - 1);
        toPos = clamp(0, toPos, order.length - 1);

        const copy = order.slice();
        const item = copy.splice(fromPos, 1)[0];
        copy.splice(toPos, 0, item);
        order = copy;
    }

    // navigates when not grabbed, reorders in place when grabbed
    function moveCurrent(step) {
        const from = platformsListView.currentIndex;
        const to = clamp(0, from + step, order.length - 1);

        if (to === from) return false;

        if (grabbed) {
            moveItem(from, to);
        }

        platformsListView.currentIndex = to;
        return true;
    }

    function toggleGrab() {
        if (order.length === 0) return;

        grabbed = !grabbed;
        if (!grabbed) save();
    }

    // Cancel while a row is grabbed: saves in place, same as a normal drop -
    // there's no destructive action here worth a silent discard
    function cancelGrab() {
        if (!grabbed) return;

        grabbed = false;
        save();
    }

    property double itemHeight: {
        return platformsListView.height * .12 * theme.fontScale;
    }
    // based on the panel's own height (which comes from its anchors), not the
    // list's - the list's height is reduced to make room for this header, so
    // deriving it from that would make the header's size depend on itself
    readonly property double headerHeight: (height - 24) * .12 * theme.fontScale * .62;

    Rectangle {
        color: theme.current.bgColor;
        anchors.fill: parent;
    }

    Rectangle {
        // separates the panel from the settings list behind it
        width: 1;
        color: theme.current.dividerColor;
        opacity: 0.7;

        anchors {
            top: parent.top;
            bottom: parent.bottom;
            left: parent.left;
        }
    }

    SettingsSectionHeader {
        title: 'Platforms';
        height: platformsPaneRoot.headerHeight;

        anchors {
            top: parent.top;
            left: parent.left;
            leftMargin: 20;
            right: parent.right;
            rightMargin: 20;
        }
    }

    Text {
        visible: order.length === 0;
        text: 'No Platforms';
        anchors.centerIn: parent;
        color: theme.current.blurTextColor;
        opacity: 0.5;

        font {
            pixelSize: parent.height * .065;
            letterSpacing: -0.3;
            bold: true;
        }
    }

    ListView {
        id: platformsListView;

        visible: order.length > 0;
        // an int model, deliberately: reordering reassigns "order" but never
        // changes its length, so the list isn't rebuilt and the highlight
        // stays on the row you're dragging
        model: order.length;
        delegate: lvPlatformDelegate;
        clip: true;
        highlightMoveDuration: 0;
        preferredHighlightBegin: itemHeight - 12;
        preferredHighlightEnd: height - (itemHeight + 12);
        highlightRangeMode: ListView.ApplyRange;

        anchors {
            left: parent.left;
            leftMargin: 20;
            top: parent.top;
            topMargin: 12 + platformsPaneRoot.headerHeight;
            bottom: parent.bottom;
            bottomMargin: 12;
            right: parent.right;
            rightMargin: 20;
        }

        highlight: Rectangle {
            color: theme.current.highlightColor;
            radius: 0;
            width: platformsListView.width;

            border {
                width: platformsPaneRoot.grabbed ? 2 : 0;
                color: theme.current.accentColor;
            }

            Rectangle {
                width: 4;
                color: theme.current.accentColor;

                anchors {
                    left: parent.left;
                    top: parent.top;
                    bottom: parent.bottom;
                }
            }
        }
    }

    Component {
        id: lvPlatformDelegate;

        Item {
            id: row;

            width: platformsListView.width;
            height: itemHeight;

            // order holds shortNames now; api.collections.get() still wants a
            // position, hence the lookup map on the theme root
            readonly property var collData: {
                const position = collectionIndexByShortName[platformsPaneRoot.order[index]];
                if (position === undefined) return null;

                return api.collections.get(position);
            }
            readonly property bool isCurrent: platformsListView.currentIndex === index;

            Text {
                text: row.collData ? row.collData.name : '';
                verticalAlignment: Text.AlignVCenter;
                elide: Text.ElideRight;
                color: row.isCurrent ? theme.current.focusTextColor : theme.current.blurTextColor;
                height: parent.height;

                font {
                    pixelSize: parent.height * .4;
                    letterSpacing: -0.3;
                    bold: true;
                }

                anchors {
                    left: parent.left;
                    leftMargin: 20;
                    right: platformGameCount.left;
                    rightMargin: 12;
                    verticalCenter: parent.verticalCenter;
                }
            }

            Text {
                // not `gameCount` - that would shadow theme.qml's gameCount()
                // function for everything else inside this delegate
                id: platformGameCount;

                text: {
                    if (!row.collData) return '';

                    const count = row.collData.games.count;
                    return count + (count === 1 ? ' game' : ' games');
                }
                verticalAlignment: Text.AlignVCenter;
                horizontalAlignment: Text.AlignRight;
                color: theme.current.detailsColor;
                opacity: 0.7;
                width: parent.width * .22;

                font {
                    pixelSize: parent.height * .3;
                }

                anchors {
                    right: moveColumn.left;
                    rightMargin: 12;
                    verticalCenter: parent.verticalCenter;
                }
            }

            // touch-friendly up/down nudges, alongside the gamepad/keyboard
            // grab + Up/Down reordering above
            Row {
                id: moveColumn;

                spacing: 6;

                anchors {
                    right: parent.right;
                    rightMargin: 20;
                    verticalCenter: parent.verticalCenter;
                }

                Text {
                    text: '\u25B2';
                    color: index === 0 ? theme.current.blurTextColor : theme.current.accentColor;
                    opacity: index === 0 ? 0.3 : 1;

                    font.pixelSize: row.height * .32;

                    MouseArea {
                        anchors.fill: parent;
                        enabled: index > 0;

                        onClicked: {
                            platformsListView.currentIndex = index;
                            platformsPaneRoot.moveItem(index, index - 1);
                            platformsPaneRoot.save();
                            platformsListView.currentIndex = index - 1;
                            sounds.nav();
                        }
                    }
                }

                Text {
                    text: '\u25BC';
                    color: index === platformsPaneRoot.order.length - 1 ? theme.current.blurTextColor : theme.current.accentColor;
                    opacity: index === platformsPaneRoot.order.length - 1 ? 0.3 : 1;

                    font.pixelSize: row.height * .32;

                    MouseArea {
                        anchors.fill: parent;
                        enabled: index < platformsPaneRoot.order.length - 1;

                        onClicked: {
                            platformsListView.currentIndex = index;
                            platformsPaneRoot.moveItem(index, index + 1);
                            platformsPaneRoot.save();
                            platformsListView.currentIndex = index + 1;
                            sounds.nav();
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent;
                z: -1;
                onClicked: {
                    if (platformsListView.currentIndex !== index) {
                        platformsListView.currentIndex = index;
                        sounds.nav();
                        return;
                    }

                    platformsPaneRoot.toggleGrab();
                    sounds.nav();
                }
            }
        }
    }
}
