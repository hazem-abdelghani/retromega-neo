import QtQuick 2.15

import '../footer' as Footer
import '../header' as Header
import '../collectionSidebar' as Sidebar
import '../media' as Media

Item {
    id: gameListRoot;

    anchors.fill: parent;

    // only meaningful when theme.verticalMode is on: true = the console
    // sidebar has focus (browsing consoles); false = the game list + art
    // panel has focus (browsing games)
    property bool sidebarFocused: true;

    // Pegasus destroys and recreates this whole theme when returning from a
    // launched game (see theme.qml's Component.onDestruction/onCompleted for
    // currentView/currentCollectionIndex/etc), so this needs its own memory
    // entry too - otherwise Vertical Mode would always drop you back on the
    // sidebar after quitting a game instead of exactly where you left off.
    Component.onCompleted: {
        sidebarFocused = api.memory.get('sidebarFocused') ?? true;
    }

    Component.onDestruction: {
        api.memory.set('sidebarFocused', sidebarFocused);
    }

    function updateIndex(newIndex) {
        gameScroll.gamesListView.currentIndex = newIndex;
        gameGrid.gridView.currentIndex = newIndex;
        gameGallery.carousel.currentIndex = newIndex;
    }

    // right-click anywhere on this screen acts as the B/Cancel button.
    // onCancelPressed() already branches on theme.verticalMode, so this
    // single MouseArea covers both Display Modes (List and Sidebar).
    // acceptedButtons is restricted to the right button so this sits
    // underneath every existing tap/left-click target without touching it.
    MouseArea {
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton;
        z: -1;
        onClicked: onCancelPressed();
    }

    function focusSidebar() {
        sidebarFocused = true;
    }

    function focusGameList() {
        if (gameCount() === 0) return;
        sidebarFocused = false;
        sounds.forward();
    }

    // a game's sortBy can be missing or empty (badly scraped metadata), which
    // used to throw on sortBy[0] and abort the whole letter-skip
    function sortLetter(game) {
        if (!game || !game.sortBy || game.sortBy.length === 0) return '';
        return game.sortBy[0].toLowerCase();
    }

    // L1/R1 walk the list a game at a time looking for the first entry whose
    // sort letter differs from the current one. Each step used to map the row
    // back through the sort proxy and fetch the whole game object just to read
    // one character, so skipping past a letter with several hundred games
    // behind it did several hundred model lookups on a single keypress - and
    // did them again on every repeat while the button was held.
    //
    // The letters are cached in a plain array instead, so the walk itself is
    // over local strings. Building the cache costs one pass, i.e. what a
    // single skip used to cost, and only happens on the first skip after the
    // list changes.
    property var letterCache: null;

    function invalidateLetterCache() {
        letterCache = null;
    }

    function letterCacheIsStale(cache) {
        if (cache === null) return true;
        if (!currentGameList) return true;
        if (cache.length !== gameCount()) return true;

        // Catches a reorder that left the count alone, which the invalidation
        // hooks below can't see - toggling a favorite while "Favorites on Top"
        // is on moves a game without changing how many there are. Cheap: the
        // current game is already in hand.
        if (currentGameIndex >= 0 && cache[currentGameIndex] !== sortLetter(currentGame)) return true;

        return false;
    }

    function sortLetters() {
        if (!letterCacheIsStale(letterCache)) return letterCache;

        const count = gameCount();
        const cache = [];

        for (let i = 0; i < count; i++) {
            cache.push(sortLetter(getMappedGame(i)));
        }

        letterCache = cache;
        return cache;
    }

    // anything that changes which games are in the list, or what order they're
    // in, drops the cache; it's rebuilt lazily on the next skip
    Connections {
        target: root;

        function onCurrentGameListChanged() { invalidateLetterCache(); }
        function onCurrentCollectionChanged() { invalidateLetterCache(); }
        function onNameFilterChanged() { invalidateLetterCache(); }
        function onFavoritesOnTopChanged() { invalidateLetterCache(); }
    }

    // the letter briefly flashed over the list when L1/R1 skips.
    // Derived from sortLetter() - the same value the skip itself walks over -
    // rather than from the raw title, so the flashed letter always matches
    // where you actually landed. (These differ whenever sortBy is scraped
    // separately from title, e.g. "The Legend of Zelda" sorting under L.)
    function setSkipLetter() {
        const sorted = sortLetter(currentGame);
        const fallback = (currentGame && currentGame.title) ? currentGame.title[0] : '';
        const source = sorted !== '' ? sorted : fallback;

        if (source === '') return;

        const letter = source.toUpperCase();
        gameScroll.flashLetter(letter);
        gameGrid.flashLetter(letter);
        gameGallery.flashLetter(letter);
    }

    function moveCollection(delta) {
        const updated = updateCollectionIndex(currentCollectionIndex + delta);
        if (updated) {
            updateSortedCollection();
            sounds.nav();
            gameScroll.video.switchVideo();
        }
    }

    Keys.onUpPressed: {
        event.accepted = true;

        if (theme.verticalMode && sidebarFocused) {
            moveCollection(-1);
            return;
        }

        // Gallery is a single horizontal strip, so Up/Down page
        // collections instead (mirrors List's Left/Right)
        if (theme.galleryMode) {
            moveCollection(-1);
            return;
        }

        // Grid: Up/Down move a full row instead of a single game
        const step = theme.gridMode ? gameGrid.columns : 1;
        const updated = updateGameIndex(currentGameIndex - step);
        if (updated) { sounds.nav(); }
    }

    Keys.onDownPressed: {
        event.accepted = true;

        if (theme.verticalMode && sidebarFocused) {
            moveCollection(1);
            return;
        }

        if (theme.galleryMode) {
            moveCollection(1);
            return;
        }

        const step = theme.gridMode ? gameGrid.columns : 1;
        const updated = updateGameIndex(currentGameIndex + step);
        if (updated) { sounds.nav(); }
    }

    // List mode: Left/Right page through collections directly.
    // Vertical Mode: Left/Right swap focus between the sidebar and the game list
    // (paging collections becomes the sidebar's Up/Down job instead).
    // Grid: Left/Right move within the current row instead; L1/R1 stay on
    // letter-skip, so B (back to the Collection Screen) is how you change
    // collection in this mode.
    // Gallery: Left/Right move to the previous/next game in the strip
    // (paging collections becomes Up/Down's job instead, see above).
    Keys.onLeftPressed: {
        event.accepted = true;

        if (theme.gridMode || theme.galleryMode) {
            const updated = updateGameIndex(currentGameIndex - 1);
            if (updated) { sounds.nav(); }
            return;
        }

        if (!theme.verticalMode) {
            const updated = updateCollectionIndex(currentCollectionIndex - 1);
            if (updated) {
                updateSortedCollection();
                sounds.nav();
                gameScroll.video.switchVideo();
            }
            return;
        }

        if (!sidebarFocused) focusSidebar();
    }

    Keys.onRightPressed: {
        event.accepted = true;

        if (theme.gridMode || theme.galleryMode) {
            const updated = updateGameIndex(currentGameIndex + 1);
            if (updated) { sounds.nav(); }
            return;
        }

        if (!theme.verticalMode) {
            const updated = updateCollectionIndex(currentCollectionIndex + 1);
            if (updated) {
                updateSortedCollection();
                sounds.nav();
                gameScroll.video.switchVideo();
            }
            return;
        }

        if (sidebarFocused) focusGameList();
    }

    function onAcceptPressed() {
        if (theme.verticalMode && sidebarFocused) {
            focusGameList();
            return;
        }

        if (gameCount() === 0 || !currentGame) return;

        sounds.launch();
        launchGame(currentGame);
    }

    function onCancelPressed() {
        if (theme.verticalMode) {
            focusSidebar();
            sounds.back();
            return;
        }

        currentView = 'collectionList';
        updateGameIndex(0, true);
        sounds.back();
    }

    function onDetailsPressed() {
        currentView = 'gameDetails';
        sounds.forward();
    }

    function onFiltersPressed() {
        if (gameCount() === 0 || theme.gridMode || theme.galleryMode) return;
        gameScroll.cycleImageType();
        sounds.nav();
    }

    function onFavoritePressed() {
        if (gameCount() === 0 || !currentGame) return;

        currentGame.favorite = !currentGame.favorite;
        sounds.nav();
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
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            // in Vertical Mode, don't accept the event once the sidebar
            // already has focus - let it bubble up to Pegasus' own menu,
            // same as the standalone top-level Collection Screen used to
            if (!theme.verticalMode || !sidebarFocused) {
                event.accepted = true;
                onCancelPressed();
            }
        }

        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            onAcceptPressed();
        }

        // X/Y print the same letter on every pad, but sit in different
        // physical spots (Xbox: X left, Y top; Nintendo-style pads like
        // Switch: X top, Y left) - so which key event is the "top button"
        // vs "left button" flips with theme.xboxMode. See the matching note
        // in collectionList/Component.qml.
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;

            if (theme.xboxMode) {
                if (!(theme.verticalMode && sidebarFocused)) {
                    onFavoritePressed();
                }
            } else if (theme.verticalMode && sidebarFocused) {
                onSettingsPressed();
            } else {
                onFiltersPressed();
            }
        }

        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;

            if (!theme.xboxMode) {
                if (!(theme.verticalMode && sidebarFocused)) {
                    onFavoritePressed();
                }
            } else if (theme.verticalMode && sidebarFocused) {
                onSettingsPressed();
            } else {
                onFiltersPressed();
            }
        }

        // L1
        if (api.keys.isPrevPage(event)) {
            event.accepted = true;

            if (theme.verticalMode && sidebarFocused) {
                moveCollection(-1);
                return;
            }

            // Gallery already pages collections via Up/Down (see above),
            // so L1/R1 there keeps the letter-skip like List/Grid below
            if (gameCount() === 0) return;
            if (currentGameIndex <= 0) return;

            const letters = sortLetters();
            let newIndex = currentGameIndex - 1;
            const oldLetter = letters[newIndex];

            while (newIndex > 0) {
                if (letters[newIndex - 1] !== oldLetter) {
                    break;
                }

                newIndex--;
            }

            const updated = updateGameIndex(newIndex);
            if (updated) {
                setSkipLetter();
                sounds.nav();
            }
        }

        // R1
        if (api.keys.isNextPage(event)) {
            event.accepted = true;

            if (theme.verticalMode && sidebarFocused) {
                moveCollection(1);
                return;
            }

            // ">=" rather than "===": on an empty collection currentGameIndex
            // is clamped to 0 while count - 1 is -1, so the old equality check
            // fell through and dereferenced a null currentGame below
            if (gameCount() === 0) return;
            if (currentGameIndex >= gameCount() - 1) return;

            // letters[currentGameIndex] rather than sortLetter(currentGame):
            // the staleness check guarantees they agree, and reading both from
            // the same array keeps the comparison below consistent
            const letters = sortLetters();
            const oldLetter = letters[currentGameIndex];
            let newIndex = currentGameIndex;

            while (newIndex < gameCount() - 1) {
                newIndex++;

                if (letters[newIndex] !== oldLetter) {
                    break;
                }
            }

            const updated = updateGameIndex(newIndex);
            if (updated) {
                setSkipLetter();
                sounds.nav();
            }
        }
    }

    // todo keep an eye on this issue https://github.com/mmatyas/pegasus-frontend/issues/781
    // R2 and L2 must be handled 'onRelease' because of an android bug that requires double presses
    Keys.onReleased: {
        // matches every Keys.onPressed handler in the theme: a held trigger
        // must not re-fire this screen's action once per repeat
        if (event.isAutoRepeat) {
            return;
        }

        // R2 - always opens search
        if (api.keys.isPageDown(event)) {
            event.accepted = true;
            onSearchPressed();
        }

        // L2 - Vertical Mode: attract mode from the sidebar, game details
        // from the game list. List layout: always game details.
        if (api.keys.isPageUp(event)) {
            event.accepted = true;

            if (theme.verticalMode && sidebarFocused) {
                onAttractPressed();
            } else {
                onDetailsPressed();
            }
        }
    }

    Rectangle {
        color: theme.current.bgColor;
        anchors.fill: parent;
    }

    Sidebar.SidebarScroll {
        id: collectionSidebar;

        visible: theme.verticalMode;
        // qualified with gameListRoot. - SidebarScroll declares its own
        // "sidebarFocused" property, so an unqualified reference here would
        // shadow itself instead of picking up this screen's real focus state
        sidebarFocused: gameListRoot.sidebarFocused;
        // collapses to an icon-only strip once a console is selected and
        // focus moves into the games column, and re-expands on Back -
        // see Flat Ozone's collectionListView width transition
        width: !theme.verticalMode ? 0 : (gameListRoot.sidebarFocused ? parent.width * .26 : parent.width * .09);

        Behavior on width {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad; }
        }

        anchors {
            top: gameListHeader.bottom;
            bottom: gameListFooter.top;
            left: parent.left;
        }

        Rectangle {
            // separates the sidebar from the game list
            width: 1;
            color: theme.current.dividerColor;
            opacity: 0.7;

            anchors {
                top: parent.top;
                bottom: parent.bottom;
                right: parent.right;
            }
        }
    }

    GameScroll {
        id: gameScroll;

        visible: !theme.gridMode && !theme.galleryMode;
        letter: '';
        // also inactive in Grid/Gallery: this whole component is hidden there,
        // but "active" is what gates its GameVideo, so leaving it true let an
        // off-screen preview video start playing (audible) behind the grid
        active: !(theme.verticalMode && sidebarFocused) && !theme.gridMode && !theme.galleryMode;

        anchors {
            top: gameListHeader.bottom;
            bottom: gameListFooter.top;
            left: theme.verticalMode ? collectionSidebar.right : parent.left;
            right: parent.right;
        }
    }

    GameGrid {
        id: gameGrid;

        visible: theme.gridMode;
        active: !(theme.verticalMode && sidebarFocused);

        anchors {
            top: gameListHeader.bottom;
            bottom: gameListFooter.top;
            left: parent.left;
            right: parent.right;
        }
    }

    GameGallery {
        id: gameGallery;

        visible: theme.galleryMode;
        active: !(theme.verticalMode && sidebarFocused);

        anchors {
            top: gameListHeader.bottom;
            bottom: gameListFooter.top;
            left: parent.left;
            right: parent.right;
        }
    }

    // the 'floating' Screenshot Preview option - anchored to the same rect
    // as GameGrid/GameGallery above and declared after both, so it always
    // paints on top of whichever of the two is currently visible. See
    // ScreenshotPreview.qml for why this one is shared rather than
    // duplicated per mode like the 'inset' option is.
    Media.ScreenshotPreview {
        active: (theme.gridMode || theme.galleryMode) && !(theme.verticalMode && sidebarFocused);

        anchors {
            top: gameListHeader.bottom;
            bottom: gameListFooter.top;
            left: parent.left;
            right: parent.right;
        }
    }

    Footer.Component {
        id: gameListFooter;

        index: (theme.verticalMode && sidebarFocused) ? currentCollectionIndex + 1 : currentGameIndex + 1;
        total: (theme.verticalMode && sidebarFocused) ? allCollections.length : gameCount();

        // Only the *order* of the entries differs between the two branches
        // (Xbox leads with Accept, Nintendo-style pads lead with Cancel,
        // matching where those buttons physically sit). The printed letters
        // all come from theme.buttonGuide - X and Y print the same letter on
        // both pad styles, just in different physical spots - see
        // SwitchButtons.qml.
        buttons: (theme.verticalMode && sidebarFocused)
            ? (theme.xboxMode ? [
                { title: 'Select', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
                { title: 'Menu', key: theme.buttonGuide.cancel, square: false, sigValue: null },
                { title: 'Settings', key: theme.xboxMode ? theme.buttonGuide.filters : theme.buttonGuide.details, square: false, sigValue: 'settings' },
                { title: 'Attract', key: theme.buttonGuide.pageUp, square: true, sigValue: 'attract' },
                { title: 'Search', key: theme.buttonGuide.pageDown, square: true, sigValue: 'search' },
            ] : [
                { title: 'Menu', key: theme.buttonGuide.cancel, square: false, sigValue: null },
                { title: 'Select', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
                { title: 'Settings', key: theme.xboxMode ? theme.buttonGuide.filters : theme.buttonGuide.details, square: false, sigValue: 'settings' },
                { title: 'Attract', key: theme.buttonGuide.pageUp, square: true, sigValue: 'attract' },
                { title: 'Search', key: theme.buttonGuide.pageDown, square: true, sigValue: 'search' },
            ])
            : (theme.xboxMode ? [
                { title: 'Play', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
                { title: 'Back', key: theme.buttonGuide.cancel, square: false, sigValue: 'cancel' },
                { title: 'Favorite', key: theme.xboxMode ? theme.buttonGuide.details : theme.buttonGuide.filters, square: false, sigValue: 'favorite' },
                { title: 'Cycle Art', visible: !theme.gridMode && !theme.galleryMode, key: theme.xboxMode ? theme.buttonGuide.filters : theme.buttonGuide.details, square: false, sigValue: 'filters' },
                { title: 'Details', key: theme.buttonGuide.pageUp, square: true, sigValue: 'details' },
                { title: 'Search', key: theme.buttonGuide.pageDown, square: true, sigValue: 'search' },
            ] : [
                { title: 'Back', key: theme.buttonGuide.cancel, square: false, sigValue: 'cancel' },
                { title: 'Play', key: theme.buttonGuide.accept, square: false, sigValue: 'accept' },
                { title: 'Favorite', key: theme.xboxMode ? theme.buttonGuide.details : theme.buttonGuide.filters, square: false, sigValue: 'favorite' },
                { title: 'Cycle Art', visible: !theme.gridMode && !theme.galleryMode, key: theme.xboxMode ? theme.buttonGuide.filters : theme.buttonGuide.details, square: false, sigValue: 'filters' },
                { title: 'Details', key: theme.buttonGuide.pageUp, square: true, sigValue: 'details' },
                { title: 'Search', key: theme.buttonGuide.pageDown, square: true, sigValue: 'search' },
            ]);

        onFooterButtonClicked: {
            if (sigValue === 'accept') onAcceptPressed();
            if (sigValue === 'cancel') onCancelPressed();
            if (sigValue === 'details') onDetailsPressed();
            if (sigValue === 'filters') onFiltersPressed();
            if (sigValue === 'favorite') onFavoritePressed();
            if (sigValue === 'settings') onSettingsPressed();
            if (sigValue === 'attract') onAttractPressed();
            if (sigValue === 'search') onSearchPressed();
        }
    }

    Header.Component {
        id: gameListHeader;

        showDivider: true;
        shade: 'dark';
        color: theme.current.bgColor;
        showTitle: true;
    }
}
