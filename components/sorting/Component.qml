import QtQuick 2.15

Item {
    anchors.fill: parent;

    // this screen now exists purely to host the Name Filter search box -
    // sorting by title/rating/release/favorite and the Only Favorites/Only
    // Multiplayer toggles that used to live here (behind this same R2/ZR
    // button) have been removed. Callers (gameList/collectionList) call
    // showModal() directly when they switch currentView to 'sorting'.
    function showModal() {
        nameFilterModal.anchors.topMargin = 0;
        nameFilterModal.textInput.text = nameFilter;
        nameFilterModal.textInput.forceActiveFocus();
    }

    function onAcceptPressed() {
        nameFilter = nameFilterModal.textInput.text;
        nameFilterModal.anchors.topMargin = root.height;
        // delayed so the slide-down close animation gets to play out before
        // this whole screen (and the search box with it) disappears
        closeTimer.restart();
        sounds.forward();
    }

    function onCancelPressed() {
        nameFilterModal.anchors.topMargin = root.height;
        closeTimer.restart();
        sounds.back();
    }

    function onClearPressed() {
        nameFilterModal.textInput.clear();
        onAcceptPressed();
    }

    // returns to whatever screen the search was opened from, once the
    // modal's own close animation has had time to finish
    Timer {
        id: closeTimer;

        interval: 200;
        repeat: false;
        onTriggered: {
            currentView = previousView;
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isCancel(event)) {
            event.accepted = true;
            onCancelPressed();
        }

        if (api.keys.isAccept(event)) {
            event.accepted = true;
            onAcceptPressed();
        }

        if (api.keys.isDetails(event)) {
            event.accepted = true;
            onClearPressed();
        }
    }

    // R2 - pressing Search again while already on this screen backs out of it,
    // matching the R2/L2-toggle behavior expected from the footer buttons
    Keys.onReleased: {
        // matches every Keys.onPressed handler in the theme: a held trigger
        // must not re-fire this screen's action once per repeat
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isPageDown(event)) {
            event.accepted = true;
            onCancelPressed();
        }
    }

    // right-click acts as the B/Cancel button on this screen too (tapping
    // outside the search box already does this via NameFilterModal's own
    // MouseArea; this covers a right-click anywhere, including on the box)
    MouseArea {
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton;
        onClicked: onCancelPressed();
    }

    // dimming scrim behind the modal, so the search box has contrast to
    // read against instead of blending into a matching background
    Rectangle {
        id: searchBackground;

        color: '#1a1a1a';
        anchors.fill: parent;
    }

    NameFilterModal {
        id: nameFilterModal;

        // no explicit width - the left/right anchors below already set it,
        // and specifying both makes QML warn and ignore one of them
        height: parent.height;
        blurSource: searchBackground;

        anchors {
            top: parent.top;
            topMargin: root.height;
            left: parent.left;
            right: parent.right;
        }

        Behavior on anchors.topMargin {
            PropertyAnimation { easing.type: Easing.OutCubic; duration: 200; }
        }
    }
}
