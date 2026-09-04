import QtQuick 2.15

import '../footer' as Footer
import '../header' as Header

Item {
    id: settingsRoot;

    anchors.fill: parent;

    // The Preferences/Platforms tab sidebar has been removed. The settings
    // list is now one continuous list, ending in a "Reorder" section whose
    // single "Platforms" row slides PlatformsPane.qml in from the right.
    // While that panel is open it takes all the input; the list behind it is
    // left exactly where it was.
    property bool platformsOpen: false;

    readonly property var currentRow: settingsScroll.rowModel[settingsScroll.settingsListView.currentIndex];

    readonly property string acceptLabel: {
        if (platformsOpen) return platformsPane.grabbed ? 'Drop' : 'Grab';
        if (currentRow === undefined || currentRow.isHeader) return 'Select';
        if (currentRow.isLink) return 'Open';
        // grayed-out row: Accept is a no-op here, so don't promise otherwise.
        // The Display Mode and the All Games toggle are passed in explicitly
        // rather than left for isRelevant() to read itself, so this label
        // re-evaluates when either changes - settings.get() reads a plain JS
        // object that never notifies QML, so the old call left the label stuck
        // on whatever it said when the row was first selected. Same reason
        // SettingsScroll passes them into each row's own binding.
        if (!settings.isRelevant(currentRow.key, settingsScroll.displayMode, showAllGamesSetting)) return 'N/A';
        return settings.type(currentRow.key) === 'select' ? 'Change' : 'Toggle';
    }

    function openPlatforms() {
        platformsPane.load();
        platformsOpen = true;
        sounds.forward();
    }

    function closePlatforms() {
        // a grabbed row is dropped (and saved) first, same as the old
        // Platforms tab did - that's this panel's own "back" step, so it takes
        // priority over closing the panel
        if (platformsPane.grabbed) {
            platformsPane.cancelGrab();
            sounds.back();
            return;
        }

        platformsOpen = false;
        sounds.back();
    }

    // Leaving Settings always lands on the Collection Screen, whichever screen
    // it was opened from - deliberately NOT previousView, so changing Display
    // Mode and backing out can't drop you onto a game list laid out for the
    // mode you just left.
    //
    // Sidebar mode has no standalone Collection Screen (the console list lives
    // inside the Game List there), so land on that with the sidebar focused,
    // which is that mode's equivalent.
    function exitToCollectionScreen() {
        if (theme.verticalMode) {
            currentView = 'gameList';
            gameList.focusSidebar();
        } else {
            currentView = 'collectionList';
        }

        previousView = currentView;
    }

    Keys.onUpPressed: {
        event.accepted = true;

        if (platformsOpen) {
            if (platformsPane.moveCurrent(-1)) sounds.nav();
            return;
        }

        const prevIndex = settingsScroll.settingsListView.currentIndex;
        settingsScroll.moveCurrentIndex(-1);
        if (settingsScroll.settingsListView.currentIndex !== prevIndex) {
            sounds.nav();
        }
    }

    Keys.onDownPressed: {
        event.accepted = true;

        if (platformsOpen) {
            if (platformsPane.moveCurrent(1)) sounds.nav();
            return;
        }

        const prevIndex = settingsScroll.settingsListView.currentIndex;
        settingsScroll.moveCurrentIndex(1);
        if (settingsScroll.settingsListView.currentIndex !== prevIndex) {
            sounds.nav();
        }
    }

    // Left/Right walk a multi-option row (Display Mode, Cards Size, Font
    // Size, Theme, Controller Layout, Cycle Art Types) through its values
    // directly, so reaching the previous option no longer means pressing
    // Accept until it wraps all the way round. Returns false - and does
    // nothing - for header, link and plain on/off rows, which have only the
    // one action and keep it on Accept, and for rows that are grayed out in
    // the current Display Mode, matching onAcceptPressed()'s own no-op.
    function stepCurrentRow(step) {
        const row = settingsScroll.rowModel[settingsScroll.settingsListView.currentIndex];

        if (row === undefined || row.isHeader || row.isLink) return false;
        if (settings.type(row.key) !== 'select') return false;
        if (!settings.isRelevant(row.key, settingsScroll.displayMode, showAllGamesSetting)) return false;

        settings.cycle(row.key, step);
        sounds.nav();

        return true;
    }

    // the panel comes in from the right, so Left/Right close and open it.
    // Otherwise they step the highlighted multi-option row (see above)
    Keys.onLeftPressed: {
        event.accepted = true;

        if (platformsOpen) {
            if (!platformsPane.grabbed) closePlatforms();
            return;
        }

        stepCurrentRow(-1);
    }

    Keys.onRightPressed: {
        event.accepted = true;

        if (platformsOpen) return;

        if (currentRow !== undefined && currentRow.isLink) {
            openPlatforms();
            return;
        }

        stepCurrentRow(1);
    }

    function onAcceptPressed(muteSound = false) {
        if (platformsOpen) {
            platformsPane.toggleGrab();
            if (!muteSound) sounds.nav();
            return;
        }

        const row = settingsScroll.rowModel[settingsScroll.settingsListView.currentIndex];
        if (row === undefined || row.isHeader) return;

        // rows that don't apply to the current Display Mode are shown grayed
        // out rather than hidden, so activating one has to be a no-op
        if (!row.isLink && !settings.isRelevant(row.key)) return;

        if (row.isLink) {
            openPlatforms();
            return;
        }

        settings.activate(row.key);
        if (!muteSound) sounds.nav();
    }

    function onCancelPressed() {
        if (platformsOpen) {
            closePlatforms();
            return;
        }

        exitToCollectionScreen();
        sounds.back();
    }

    // right-click anywhere on this screen acts as the B/Cancel button,
    // matching the same behavior on the Game List, Game Details, Sorting
    // and Attract screens (see those Component.qml files)
    MouseArea {
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton;
        z: -1;
        onClicked: onCancelPressed();
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
            onCancelPressed();
        }

        // Settings is opened via the top button (isFilters - see
        // collectionList/Component.qml and gameList/Component.qml), so
        // pressing that same button again here also backs out, letting it
        // act as an open/close toggle like L2 does for Game Details.
        if (api.keys.isFilters(event)) {
            event.accepted = true;
            onCancelPressed();
        }
    }

    Rectangle {
        color: theme.current.bgColor;
        anchors.fill: parent;
    }

    SettingsScroll {
        id: settingsScroll;

        // the panel overlays this list rather than replacing it, so the row
        // you opened it from stays highlighted underneath
        active: !settingsRoot.platformsOpen;

        anchors {
            top: settingsHeader.bottom;
            bottom: settingsFooter.top;
            left: parent.left;
            right: parent.right;
        }
    }

    // dims the settings list while the panel is out, and closes it on a tap
    // anywhere outside the panel
    Rectangle {
        color: '#000000';
        opacity: settingsRoot.platformsOpen ? 0.5 : 0;
        visible: opacity > 0;

        anchors {
            top: settingsHeader.bottom;
            bottom: settingsFooter.top;
            left: parent.left;
            right: parent.right;
        }

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic; }
        }

        MouseArea {
            anchors.fill: parent;
            enabled: settingsRoot.platformsOpen;
            onClicked: closePlatforms();
        }
    }

    PlatformsPane {
        id: platformsPane;

        open: settingsRoot.platformsOpen;
        width: parent.width * .5;
        // slides fully off the right edge when closed
        x: parent.width - (open ? width : 0);
        visible: x < parent.width;

        Behavior on x {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic; }
        }

        anchors {
            top: settingsHeader.bottom;
            bottom: settingsFooter.top;
        }
    }

    Footer.Component {
        id: settingsFooter;

        total: 0;

        buttons: {
            const accept = { title: acceptLabel, key: theme.buttonGuide.accept, square: false, sigValue: 'accept' };
            const back = { title: 'Back', key: theme.buttonGuide.cancel, square: false, sigValue: 'cancel' };

            return theme.xboxMode ? [accept, back] : [back, accept];
        }

        onFooterButtonClicked: {
            if (sigValue === 'accept') onAcceptPressed();
            if (sigValue === 'cancel') onCancelPressed();
        }
    }

    Header.Component {
        id: settingsHeader;

        showDivider: true;
        shade: 'dark';
        color: theme.current.bgColor;
        showTitle: true;
        title: 'Settings';
    }
}
