import QtQuick 2.15
import QtGraphicalEffects 1.12

import '../footer' as Footer

Item {
    anchors.fill: parent;
    property bool fullDescriptionShowing: false;
    property bool favoritesChanged: false;

    // right-click acts as the B/Cancel button on this screen; z: -1 keeps it
    // underneath the existing tap targets (play/favorite buttons, full
    // description toggle) so it only intercepts the right mouse button
    MouseArea {
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton;
        z: -1;
        onClicked: {
            if (fullDescriptionShowing) {
                hideFullDescription();
            } else {
                onCancelPressed();
            }
        }
    }

    function onCancelPressed() {
        if (favoritesChanged === true) {
            updateGameIndex(currentGameIndex, true);
            favoritesChanged = false;
        }

        currentView = 'gameList';
        sounds.back();
    }

    function onAcceptPressed() {
        if (!currentGame) return;

        sounds.launch();
        launchGame(currentGame);
    }

    function onFiltersPressed() {
        if (!currentGame) return;

        currentGame.favorite = !currentGame.favorite;
        favoritesChanged = true;
        sounds.nav();
    }

    function onDetailsPressed() {
        if (!currentGame || !currentGame.description) return;

        fullDescriptionShowing = true;
        fullDescription.anchors.topMargin = 0;
        sounds.forward();
    }

    function hideFullDescription() {
        fullDescriptionShowing = false;
        fullDescription.anchors.topMargin = root.height;
        fullDescription.resetFlickable();
        sounds.back();
    }

    function detailsButtonClicked(button) {
        switch (button) {
            case 'play':
                onAcceptPressed();
                break;

            case 'favorite':
                onFiltersPressed();
                break;

            case 'more':
                onDetailsPressed();
                break;

            case 'less':
                hideFullDescription();
                break;
        }
    }

    Keys.onUpPressed: {
        event.accepted = true;

        if (fullDescriptionShowing) {
            fullDescription.scrollUp();
            return;
        }

        const updated = updateGameIndex(currentGameIndex - 1);
        if (updated) {
            sounds.nav();
            allDetails.video.switchVideo();
        }
    }

    Keys.onDownPressed: {
        event.accepted = true;

        if (fullDescriptionShowing) {
            fullDescription.scrollDown();
            return;
        }

        const updated = updateGameIndex(currentGameIndex + 1);
        if (updated) {
            sounds.nav();
            allDetails.video.switchVideo();
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        // QML emits this general handler BEFORE the per-key ones
        // (Keys.onUpPressed/onDownPressed above), so accepting the event here
        // for every key - which is what this used to do - meant the first
        // press of anything closed the panel and scrollUp()/scrollDown() were
        // never reachable at all. Up/Down are let through to do their job;
        // every other key still closes the description.
        if (fullDescriptionShowing) {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                return;
            }

            event.accepted = true;
            hideFullDescription();
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

        // X/Y print the same letter on every pad, but sit in different
        // physical spots (Xbox: X left, Y top; Nintendo-style pads: X top,
        // Y left) - so which key event is the "top button" (More) vs "left
        // button" (Favorite) flips with theme.xboxMode. See the matching
        // note in collectionList/Component.qml.
        if (api.keys.isDetails(event)) {
            event.accepted = true;
            if (theme.xboxMode) { onFiltersPressed(); } else { onDetailsPressed(); }
        }

        if (api.keys.isFilters(event)) {
            event.accepted = true;
            if (theme.xboxMode) { onDetailsPressed(); } else { onFiltersPressed(); }
        }
    }

    // L2/LT - same key that opens this screen from the game list (see
    // gameList/Component.qml's onReleased). Pressing it again here just
    // goes back, so LT acts as an open/close toggle for Details. Handled
    // onReleased to match that screen and avoid the Android double-press
    // issue noted there. Works the same in both Display Modes (List
    // and Sidebar) since onCancelPressed() always returns to 'gameList'
    // regardless of theme.verticalMode.
    Keys.onReleased: {
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;

            if (fullDescriptionShowing) {
                hideFullDescription();
                return;
            }

            onCancelPressed();
        }
    }

    Item {
        id: allDetailsBlur;

        anchors.fill: parent;

        Rectangle {
            color: theme.current.bgColor;
            anchors.fill: parent;
        }

        AllDetails {
            id: allDetails;

            anchors {
                top: parent.top;
                bottom: detailsFooter.top;
                left: parent.left;
                right: parent.right;
            }
        }

        Footer.Component {
            id: detailsFooter;

            total: 0;

            buttons: theme.xboxMode ? [
                { title: 'Play', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
                { title: 'Back', key: theme.buttonGuide.cancel, square: false, sigValue: 'cancel' },
                { title: 'Favorite', key: theme.buttonGuide.details, square: false, sigValue: 'filters' },
                { title: 'More', key: theme.buttonGuide.filters, square: false, sigValue: 'details' },
            ] : [
                { title: 'Back', key: theme.buttonGuide.cancel, square: false, sigValue: 'cancel' },
                { title: 'Play', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
                { title: 'Favorite', key: theme.buttonGuide.filters, square: false, sigValue: 'filters' },
                { title: 'More', key: theme.buttonGuide.details, square: false, sigValue: 'details' },
            ];

            onFooterButtonClicked: {
                if (sigValue === 'accept') onAcceptPressed();
                if (sigValue === 'cancel') onCancelPressed();
                if (sigValue === 'filters') onFiltersPressed();
                if (sigValue === 'details') onDetailsPressed();
            }
        }
    }

    GameDescription {
        id: fullDescription;

        // no explicit width - see the same note in sorting/Component.qml
        height: parent.height;
        blurSource: allDetailsBlur;

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
