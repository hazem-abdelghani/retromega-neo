import QtQuick 2.15

import '../footer' as Footer
import '../header' as Header

Item {
    anchors.fill: parent;

    function updateIndex(newIndex) {
        collectionScroll.collectionListView.currentIndex = newIndex;
    }

    Keys.onLeftPressed: {
        event.accepted = true;
        const updated = updateCollectionIndex(currentCollectionIndex - 1);
        if (updated) { sounds.nav(); }
    }

    Keys.onRightPressed: {
        event.accepted = true;
        const updated = updateCollectionIndex(currentCollectionIndex + 1);
        if (updated) { sounds.nav(); }
    }

    function onAcceptPressed() {
        currentGame = null;
        updateSortedCollection();
        currentView = 'gameList';
        sounds.forward();
    }

    // no previousView bookkeeping here: Settings deliberately always exits to
    // the Collection Screen (see settings/Component.qml's
    // exitToCollectionScreen), so it never reads previousView back
    function onSettingsPressed() {
        currentView = 'settings';
        sounds.forward();
    }

    function onAttractPressed() {
        currentView = 'attract';
        sounds.forward();
    }

    function onSearchPressed() {
        previousView = currentView;
        currentView = 'sorting';
        sortingComponent.showModal();
        sounds.forward();
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            onAcceptPressed();
        }

        // Settings is the "top button" action. Which physical button that
        // is depends on the pad style: on Xbox pads X/Y sit left/top, but on
        // Nintendo-style pads (like Switch or many handhelds) they sit
        // top/left - the opposite way round. api.keys.isDetails()/isFilters()
        // fire off the button's printed letter (X/Y), not its physical
        // position, on every pad - so which one is physically "on top" has
        // to be looked up via theme.xboxMode rather than assumed fixed.
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            if (!theme.xboxMode) {
                event.accepted = true;
                onSettingsPressed();
            }
        }

        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            if (theme.xboxMode) {
                event.accepted = true;
                onSettingsPressed();
            }
        }

        // L1
        if (api.keys.isPrevPage(event)) {
            event.accepted = true;
            const updated = updateCollectionIndex(currentCollectionIndex - 1);
            if (updated) { sounds.nav(); }
        }

        // R1
        if (api.keys.isNextPage(event)) {
            event.accepted = true;
            const updated = updateCollectionIndex(currentCollectionIndex + 1);
            if (updated) { sounds.nav(); }
        }
    }

    Keys.onReleased: {
        // matches every Keys.onPressed handler in the theme: a held trigger
        // must not re-fire this screen's action once per repeat
        if (event.isAutoRepeat) {
            return;
        }

        // L2
        if (api.keys.isPageUp(event)) {
            event.accepted = true;
            onAttractPressed();
        }

        // R2
        if (api.keys.isPageDown(event)) {
            event.accepted = true;
            onSearchPressed();
        }
    }

    CollectionScroll {
        id: collectionScroll;

        anchors {
            top: parent.top;
            bottom: collectionListFooter.top;
            left: parent.left;
            right: parent.right;
        }
    }

    Footer.Component {
        id: collectionListFooter;
        index: currentCollectionIndex + 1;
        total: allCollections.length;

        // Settings fires api.keys.isFilters() on Xbox pads, or isDetails() on
        // Nintendo-style ones (see the Keys.onPressed handler above) - either
        // way it's the "top button", so the printed letter follows suit.
        buttons: theme.xboxMode ? [
            { title: 'Select', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
            { title: 'Menu', key: theme.buttonGuide.cancel, square: false, sigValue: null },
            { title: 'Settings', key: theme.buttonGuide.filters, square: false, sigValue: 'settings' },
            { title: 'Attract', key: theme.buttonGuide.pageUp, square: true, sigValue: 'attract' },
            { title: 'Search', key: theme.buttonGuide.pageDown, square: true, sigValue: 'search' },
        ] : [
            { title: 'Menu', key: theme.buttonGuide.cancel, square: false, sigValue: null },
            { title: 'Select', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
            { title: 'Settings', key: theme.buttonGuide.details, square: false, sigValue: 'settings' },
            { title: 'Attract', key: theme.buttonGuide.pageUp, square: true, sigValue: 'attract' },
            { title: 'Search', key: theme.buttonGuide.pageDown, square: true, sigValue: 'search' },
        ];

        onFooterButtonClicked: {
            if (sigValue === 'accept') onAcceptPressed();
            if (sigValue === 'settings') onSettingsPressed();
            if (sigValue === 'attract') onAttractPressed();
            if (sigValue === 'search') onSearchPressed();
        }
    }

    Header.Component {
        showDivider: false;
        shade: 'light';
    }
}
