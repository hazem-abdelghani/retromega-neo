import QtQuick 2.15
import SortFilterProxyModel 0.2

import 'components/collectionList' as CollectionList
import 'components/gameList' as GameList
import 'components/gameDetails' as GameDetails
import 'components/settings' as Settings
import 'components/resources' as Resources
import 'components/themes' as Themes
import 'components/sorting' as Sorting
import 'components/attract' as Attract

FocusScope {
    id: root;

    property string currentView: 'collectionList';
    property string previousView: 'collectionList';
    property var currentViewCallbacks: [];

    property int currentCollectionIndex: -1;
    property var currentCollection;
    property string currentShortName;
    property var currentGameList;
    property int currentGameIndex: -1;
    property var currentGame;

    // guards onAllCollectionsChanged (further down) from running during
    // initial construction, before the deliberate startup sequence below
    // has had a chance to set currentCollectionIndex/currentShortName
    property bool startupComplete: false;

    // Pegasus tears the entire theme down while a game runs and builds it
    // again when the game exits, so "we just came back from a game" and
    // "Pegasus was just started" look identical from in here - both are a
    // fresh Component.onCompleted against the same api.memory. This flag is
    // the only thing that tells them apart: it's set on the way out to a game,
    // written to memory in Component.onDestruction, and read back (then
    // immediately cleared) in Component.onCompleted.
    property bool launchingGame: false;

    // Single entry point for launching, so the flag above can't be forgotten
    // at one of the call sites (game list, game details, attract mode). A
    // launch that skipped it would be indistinguishable from a cold start and
    // would drop the player on All Games instead of back where they were.
    function launchGame(game) {
        if (!game) return;

        launchingGame = true;
        api.memory.set('resumeAfterGame', true);

        game.launch();
    }

    // last value of the 'displayMode' setting, so the callback below can tell
    // an actual List<->Sidebar transition apart from a Grid<->Gallery one.
    // theme.verticalMode can't be used for this: Themes.Handler registers its
    // own displayMode callback first (child Component.onCompleted runs before
    // the parent's), so by the time our callback runs it already holds the
    // NEW value.
    property string previousDisplayMode: 'list';

    // Cutoff for the Last Played collection: games played more recently than
    // this are in it. Held as a property rather than recomputed inside the
    // filter, which built a Date object and redid the arithmetic for every
    // game it tested - on a large library, on every re-filter.
    //
    // Refreshed hourly so the collection still ages games out during a long
    // session. Assigning it re-runs the filter, which is the point.
    // initialised inline rather than left at 0 and filled in by the timer:
    // the collection is built during startup, before the timer's first tick
    property real recentsCutoff: new Date().getTime() - (1000 * 60 * 60 * 24 * 31);

    function updateRecentsCutoff() {
        const lastMonth = 1000 * 60 * 60 * 24 * 31; // ms in 31 days
        recentsCutoff = new Date().getTime() - lastMonth;
    }

    Timer {
        interval: 60 * 60 * 1000;
        repeat: true;
        running: true;
        triggeredOnStart: true;
        onTriggered: updateRecentsCutoff();
    }

    // onlyFavorites, onlyMultiplayer, sortKey and sortDir used to live here.
    // The sorting screen that owned them was removed - R2 opens the name
    // search and nothing else - so all four were pinned at their defaults on
    // every startup and nothing anywhere could change them again. They were
    // still being carried by two disabled filters on each of four
    // SortFilterProxyModels, two RoleSorters, four dead Connections handlers
    // and a footer "visible" binding, so every re-filter paid for predicates
    // whose answer was fixed. Deleted outright rather than left inert.
    property bool favoritesOnTop: false;
    property string nameFilter: '';

    // The search box takes a plain substring, but RegExpFilter takes a
    // regular expression, so anything the user types that means something
    // to a regex has to be escaped before it gets there. ROM titles are
    // full of exactly those characters: searching "Sonic (USA)" used to
    // match "Sonic USA" but not "Sonic (USA)" itself, since the brackets
    // were read as a capture group, and a lone "[" or "(" is an invalid
    // pattern that quietly matches nothing at all.
    //
    // Kept as its own property rather than escaped at the point of use, so
    // the four filters that need it all get the same treatment and
    // nameFilter itself stays the literal text for the "No Games With ..."
    // message and the search box.
    property string nameFilterPattern: nameFilter.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

    function addCurrentViewCallback(callback) {
        currentViewCallbacks.push(callback);
    }

    function removeCurrentViewCallback(callback) {
        const index = currentViewCallbacks.indexOf(callback);
        if (index !== -1) {
            currentViewCallbacks.splice(index, 1);
        }
    }

    onCurrentViewChanged: {
        for (let i = 0; i < currentViewCallbacks.length; i++) {
            currentViewCallbacks[i](currentView);
        }
    }

    function clamp(min, val, max) {
        return Math.max(min, Math.min(val, max));
    }

    // currentGameList is a plain "property var" and stays undefined until
    // Component.onCompleted below runs updateSortedCollection(). Child
    // components finish constructing first, so every binding of theirs that
    // read currentGameList.count directly threw a TypeError on the way up -
    // once per launch, per binding. They go through this instead, which is
    // the same guard theme.qml already applies in updateGameIndex() and on
    // sortedCollection's sourceModel.
    function gameCount() {
        return currentGameList ? currentGameList.count : 0;
    }

    function updateSortedCollection() {
        // currentCollection first: sortedCollection's sourceModel is bound to
        // currentCollection.games, so assigning currentGameList before it
        // pointed the proxy at the previous collection for one pass
        currentCollection = allCollections[currentCollectionIndex];

        if (currentShortName === 'favorites') {
            currentGameList = allFavorites;
        } else if (currentShortName === 'recents') {
            currentGameList = filterLastPlayed;
        } else {
            currentGameList = sortedCollection;
        }

        updateGameIndex(0, true);
    }

    // position of a collection in allCollections by shortName, or -1 if it
    // isn't there. The synthetic entries ('allgames', 'recents', 'favorites')
    // can each be switched off in Settings, so their presence - and the index
    // of everything after them - is never a given
    function indexOfCollection(shortName) {
        for (let i = 0; i < allCollections.length; i++) {
            if (allCollections[i].shortName === shortName) return i;
        }

        return -1;
    }

    function updateCollectionIndex(newIndex, skipCollectionListUpdate = false) {
        // Same trap updateGameIndex() below was fixed for: with no collections
        // at all (nothing scanned and All Games/Last Played/Favorites each
        // switched off in Settings), clamp() returns 0 rather than -1 -
        // Math.min(x, -1) then Math.max(0, ...) - and the shortName lookup a
        // few lines down then dereferences allCollections[0]. -1 is the honest
        // answer, and it's the value CollectionScroll/SidebarScroll already
        // expect to see for "nothing to show".
        if (allCollections.length === 0) {
            if (currentCollectionIndex === -1) return false;

            currentCollectionIndex = -1;
            currentShortName = '';

            if (!skipCollectionListUpdate) {
                collectionList.updateIndex(-1);
            }

            return true;
        }

        const clampedIndex = clamp(0, newIndex, allCollections.length - 1);

        if (clampedIndex === currentCollectionIndex) return false;

        currentCollectionIndex = clampedIndex;
        currentShortName = allCollections[currentCollectionIndex].shortName;

        // this prevents a circular update loop if we're updating from dragging the collection list
        if (!skipCollectionListUpdate) {
            collectionList.updateIndex(currentCollectionIndex);
        }

        return true;
    }

    function updateGameIndex(newIndex, forceUpdate = false) {
        // an empty collection has no valid index at all. clamp() would return
        // 0 here (Math.min(x, -1) then Math.max(0, ...)), which every consumer
        // then treats as a real selection and dereferences - the root cause of
        // the "no games" crashes. -1 is the honest answer, and it's also what
        // ListView/GridView expect for "nothing is current".
        const count = gameCount();

        if (count === 0) {
            if (!forceUpdate && currentGameIndex === -1) return false;

            currentGameIndex = -1;
            currentGame = null;
            gameList.updateIndex(-1);

            return true;
        }

        const clampedIndex = clamp(0, newIndex, count - 1);

        if (!forceUpdate && clampedIndex === currentGameIndex) return false;

        currentGameIndex = clampedIndex;
        currentGame = getMappedGame(currentGameIndex);
        gameList.updateIndex(currentGameIndex);

        return true;
    }


    // Changing any of these rebuilds the filter proxies underneath the current
    // selection. Nothing used to re-anchor afterwards, so filtering could
    // leave currentGameIndex pointing past the end of the shortened list, and
    // currentGame pointing at a game that had just been filtered out - the
    // footer counter, the art panel and the Play button all disagreed with
    // what was on screen, and searching down to zero results left the previous
    // game live behind the "No Games" message.
    //
    // Deferred through a 0ms timer rather than done inline: the proxies pick
    // up these same values through their own bindings, and there's no
    // guarantee they've refiltered by the time this handler runs.
    // true when the change removed games (jump to the top of what's left);
    // false when it only reordered them (stay put, just re-map currentGame)
    property bool resyncToTop: false;

    function scheduleResync(toTop) {
        // never during startup - Component.onCompleted below deliberately
        // restores the last collection/game from api.memory, and a resync
        // scheduled by the property writes it makes would land afterwards
        // and reset the selection to the top of the list
        if (!startupComplete) return;

        resyncToTop = resyncToTop || toTop;
        filterResyncTimer.restart();
    }

    onNameFilterChanged: scheduleResync(true);
    onFavoritesOnTopChanged: scheduleResync(false);

    Timer {
        id: filterResyncTimer;

        interval: 0;
        repeat: false;
        onTriggered: {
            updateGameIndex(resyncToTop ? 0 : currentGameIndex, true);
            resyncToTop = false;
        }
    }


    // code to handle reading and writing api.memory
    Component.onCompleted: {
        // read this early since the default view (and how memory is
        // sanitized below) depends on it
        theme.setVerticalMode(settings.get('displayMode'));
        theme.setGridMode(settings.get('displayMode'));
        theme.setGalleryMode(settings.get('displayMode'));

        // Was this session started by a game exiting, or by Pegasus itself
        // starting up? See launchGame() above for why this is needed.
        //
        // Cleared immediately, before anything else can go wrong: api.memory
        // is flushed to theme_settings/<theme>.json on every set, so from this
        // point on the file on disk already reads "not resuming". However this
        // session ends - a clean quit, a crash, the handheld's power button -
        // the next cold start gets the fresh-start behaviour, and only an
        // actual game launch writes true again.
        const resumingFromGame = api.memory.get('resumeAfterGame') === true;
        api.memory.set('resumeAfterGame', false);

        currentView = api.memory.get('currentView') ?? (theme.verticalMode ? 'gameList' : 'collectionList');

        // Vertical Mode replaces the standalone Collection Screen with a
        // sidebar built into the Game List, so make sure we never land on
        // the standalone screen while it's on (e.g. it was turned on after the
        // last time currentView was saved to memory)
        if (theme.verticalMode && currentView === 'collectionList') {
            currentView = 'gameList';
        }

        // The search screen is a modal: sorting/Component.qml only slides its
        // box into view from showModal(), which is called on the way in from a
        // Search button press and nowhere else. Restoring straight into it -
        // i.e. Pegasus was quit or crashed with the box open - came back to an
        // empty dark screen with the box still parked off the bottom edge.
        if (currentView === 'sorting') {
            currentView = theme.verticalMode ? 'gameList' : 'collectionList';
        }

        // Nothing to restore for sorting or filtering anymore - the sorting
        // screen is gone and the properties behind it with it (see the note
        // where they used to be declared). Only the name filter is left, and
        // clearing it on reload is always-on rather than a user-facing
        // toggle, so it's never read back from memory either.
        nameFilter = '';

        favoritesOnTop = settings.get('favoritesOnTop');
        settings.addCallback('favoritesOnTop', function (enabled) {
            favoritesOnTop = enabled;
        });

        loadCollectionOrder();

        // Cold start: open the Collection Screen with All Games selected,
        // rather than restoring whatever the last session happened to end on.
        //
        // Deliberately gated on resumingFromGame: coming back from a game must
        // still land exactly where it left off - same collection, same game,
        // same screen - which is the whole point of the memory restore below.
        //
        // -1 covers both "the setting is off" and "the All Games collection is
        // hidden in Settings", in which case there's nothing to start on and
        // the normal restore runs instead.
        const startOnAllGames = !resumingFromGame && settings.get('startOnAllGames');
        const allGamesIndex = startOnAllGames ? indexOfCollection('allgames') : -1;

        if (allGamesIndex !== -1) {
            updateCollectionIndex(allGamesIndex);
            updateSortedCollection(); // selects the first game of the collection

            // Sidebar mode has no standalone Collection Screen - the console
            // list lives inside the Game List view - so the equivalent
            // landing spot there is the Game List with the sidebar focused,
            // which is what sidebarFocused defaults to anyway. Set explicitly
            // rather than left alone: it's restored from memory in
            // GameList.Component's own onCompleted, which has already run by
            // the time we get here.
            currentView = theme.verticalMode ? 'gameList' : 'collectionList';
            previousView = currentView;
            gameList.sidebarFocused = true;
        } else {
            updateCollectionIndex(api.memory.get('currentCollectionIndex') ?? -1);
            updateSortedCollection();
            updateGameIndex(api.memory.get('currentGameIndex') ?? -1, true);
        }

        // this is done in here to prevent a quick flash of default themes
        theme.setColorTheme(settings.get('colorTheme'));
        theme.setControllerLayout(settings.get('controllerLayout'));
        theme.setFontScale();

        // Display Mode switches between List, Sidebar, Grid and Gallery
        // live, without needing a restart.
        // theme.verticalMode is already kept in sync by Themes.Handler's own callback.
        //
        // Sidebar is the ONLY mode that removes the standalone Collection
        // Screen (it folds the console list into the Game List). List,
        // Grid and Gallery all still have it, and all still use 'gameList'
        // for the games themselves, so switching between those three must
        // leave currentView/previousView completely alone. The old check
        // here was `value === 'sidebar'`, which treated Grid and Gallery as
        // "not the Game List" and rewrote previousView to 'collectionList' -
        // so changing Display Mode from e.g. Grid to Gallery in Settings and
        // pressing Back dumped you on the Collection Screen instead of
        // returning to the game list you came from.
        previousDisplayMode = settings.get('displayMode');

        settings.addCallback('displayMode', function (value) {
            const wasSidebar = previousDisplayMode === 'sidebar';
            const isSidebar = value === 'sidebar';
            previousDisplayMode = value;

            // List <-> Grid <-> Gallery: both views stay valid, nothing to do
            if (isSidebar === wasSidebar) return;

            if (isSidebar) {
                if (currentView === 'collectionList') currentView = 'gameList';
                if (previousView === 'collectionList') previousView = 'gameList';
                return;
            }

            // leaving Sidebar mode: the console list becomes its own screen again
            if (currentView === 'gameList') currentView = 'collectionList';
            if (previousView === 'gameList') previousView = 'collectionList';
        });

        settings.addCallback('showAllGames', function (enabled) {
            showAllGamesSetting = enabled;
        });

        settings.addCallback('showRecents', function (enabled) {
            showRecentsSetting = enabled;
        });

        settings.addCallback('showFavorites', function (enabled) {
            showFavoritesSetting = enabled;
        });

        startupComplete = true;

        sounds.start();
    }

    Component.onDestruction: {
        // false for every teardown that isn't a game launch - quitting
        // Pegasus, reloading the theme, switching themes - so those all come
        // back as a fresh start. launchGame() has already written true for the
        // launch case; this re-asserts it in case anything cleared it since.
        api.memory.set('resumeAfterGame', launchingGame);

        api.memory.set('currentView', currentView);
        api.memory.set('currentCollectionIndex', currentCollectionIndex);
        api.memory.set('currentGameIndex', currentGameIndex);

        // No sort/filter state is saved - those properties no longer exist,
        // and nameFilter is always cleared on reload rather than restored

        settings.saveAll();
    }


    // code to handle collection modification
    // tracked as real, change-notifying properties (kept in sync via
    // settings.addCallback below) rather than calling settings.get(...)
    // directly inside allCollections' binding - settings.get() reads a
    // plain JS object whose internal mutations don't notify QML, so a
    // binding built directly on it only ever evaluates once at startup
    // and never reacts to these three toggles afterwards
    property bool showAllGamesSetting: settings.get('showAllGames');
    property bool showRecentsSetting: settings.get('showRecents');
    property bool showFavoritesSetting: settings.get('showFavorites');

    // custom ordering of the *real* platform collections (i.e. excluding
    // the synthetic All Games/Last Played/Favorites entries below), set from
    // the Settings screen's Platforms panel (components/settings/PlatformsPane.qml)
    // and persisted to api.memory as an array of collection shortNames.
    // Referenced directly (rather than via settings.get()) so reordering
    // updates allCollections immediately - see the note above.
    //
    // shortNames rather than indices into api.collections: an index only means
    // anything against the exact list it was saved from, so adding or removing
    // a platform silently shifted every entry after it and the retained order
    // was approximate at best. A name still refers to the same platform.
    property var collectionOrder: [];

    // shortName -> position in api.collections, for the Platforms panel, which
    // needs an index to call api.collections.get()
    property var collectionIndexByShortName: {
        const map = {};
        const raw = api.collections.toVarArray();

        for (let i = 0; i < raw.length; i++) {
            map[raw[i].shortName] = i;
        }

        return map;
    }

    // Rebuilds the custom platform order against the collection list Pegasus
    // actually loaded this time: keeps the saved order for platforms that are
    // still present, drops any that have gone, and appends anything new at the
    // end. Adding or removing a platform no longer disturbs the rest.
    function loadCollectionOrder() {
        const raw = api.collections.toVarArray();
        const saved = api.memory.get('collectionOrder');
        const order = [];
        const seen = {};

        if (Array.isArray(saved)) {
            for (let i = 0; i < saved.length; i++) {
                const value = saved[i];

                // migration: this used to be stored as indices into
                // api.collections, so translate anything numeric back to a
                // name. Approximate if the set of collections changed in the
                // meantime, but it only happens once
                const name = (typeof value === 'number' && value >= 0 && value < raw.length)
                    ? raw[value].shortName
                    : value;

                if (typeof name !== 'string') continue;
                if (collectionIndexByShortName[name] === undefined) continue;
                if (seen[name] === true) continue;

                seen[name] = true;
                order.push(name);
            }
        }

        for (let i = 0; i < raw.length; i++) {
            if (seen[raw[i].shortName] !== true) order.push(raw[i].shortName);
        }

        collectionOrder = order;
    }

    property var allCollections: {
        const raw = api.collections.toVarArray();
        const byName = {};

        for (let i = 0; i < raw.length; i++) {
            byName[raw[i].shortName] = raw[i];
        }

        const ordered = [];

        for (let i = 0; i < collectionOrder.length; i++) {
            const entry = byName[collectionOrder[i]];
            if (entry !== undefined) ordered.push(entry);
        }

        // safety net: if the custom order doesn't account for exactly the
        // collections Pegasus loaded, fall back to its order rather than
        // hiding one of them
        // .slice() on the fallback: the three unshift()s below mutate whatever
        // this ends up pointing at, and "raw" is the array api.collections
        // handed back rather than one we built
        const collections = (ordered.length === raw.length) ? ordered : raw.slice();

        if (showFavoritesSetting) {
            collections.unshift({'name': 'Favorites', 'shortName': 'favorites', 'games': allFavorites});
        }

        if (showRecentsSetting) {
            collections.unshift({'name': 'Last Played', 'shortName': 'recents', 'games': filterLastPlayed});
        }

        if (showAllGamesSetting) {
            collections.unshift({'name': 'All Games', 'shortName': 'allgames', 'games': api.allGames});
        }

        return collections;
    };

    // whenever the list's shape changes (one of the three toggles above),
    // keep pointing at the same collection instead of drifting to whatever
    // now sits at the old numeric index
    onAllCollectionsChanged: {
        if (!startupComplete) return;

        // everything got switched off - clear the selection rather than
        // leaving it pointing at a collection that no longer exists
        if (allCollections.length === 0) {
            currentCollectionIndex = -1;
            currentShortName = '';
            updateSortedCollection();
            collectionList.updateIndex(-1);

            return;
        }

        let newIndex = allCollections.findIndex(function (c) { return c.shortName === currentShortName; });
        if (newIndex === -1) newIndex = 0;

        currentCollectionIndex = clamp(0, newIndex, allCollections.length - 1);
        currentShortName = allCollections[currentCollectionIndex].shortName;
        updateSortedCollection();
        collectionList.updateIndex(currentCollectionIndex);
    }

    function getMappedGame(index) {
        if (!currentCollection || index < 0) return null;

        if (currentCollection.shortName === 'favorites') {
            return api.allGames.get(allFavorites.mapToSource(index));
        } else if (currentCollection.shortName === 'recents') {
            return api.allGames.get(filterLastPlayed.mapToSource(index));
        } else {
            return currentCollection.games.get(sortedCollection.mapToSource(index));
        }
    }

    SortFilterProxyModel {
        id: allFavorites;

        sourceModel: api.allGames;
        filters: [
            ValueFilter { roleName: 'favorite'; value: true; },
            RegExpFilter { roleName: 'title'; pattern: nameFilterPattern; caseSensitivity: Qt.CaseInsensitive; enabled: nameFilter !== ''; }
        ]
        sorters: RoleSorter { roleName: 'sortBy'; sortOrder: Qt.AscendingOrder; }
    }

    SortFilterProxyModel {
        id: filterLastPlayed;

        sourceModel: api.allGames;
        filters: [
            RegExpFilter { roleName: 'title'; pattern: nameFilterPattern; caseSensitivity: Qt.CaseInsensitive; enabled: nameFilter !== ''; },
            ExpressionFilter {
                expression: {
                    const lastPlayedTime = lastPlayed.getTime();
                    if (isNaN(lastPlayedTime)) return false;

                    return lastPlayedTime > recentsCutoff;
                }
            }
        ]
        sorters: [
            RoleSorter { roleName: 'favorite'; sortOrder: Qt.DescendingOrder; enabled: favoritesOnTop; },
            RoleSorter { roleName: 'lastPlayed'; sortOrder: Qt.DescendingOrder; }
        ]
    }

    SortFilterProxyModel {
        id: sortedCollection;

        // guarded: currentCollection is briefly undefined during startup, and
        // an unguarded binding logs a TypeError on every launch
        sourceModel: currentCollection ? currentCollection.games : null;
        sorters: [
            RoleSorter { roleName: 'favorite'; sortOrder: Qt.DescendingOrder; enabled: favoritesOnTop; },
            RoleSorter { roleName: 'sortBy'; sortOrder: Qt.AscendingOrder; }
        ]
        filters: [
            RegExpFilter { roleName: 'title'; pattern: nameFilterPattern; caseSensitivity: Qt.CaseInsensitive; enabled: nameFilter !== ''; }
        ]
    }


    // data components
    Settings.Handler { id: settings; }
    Themes.Handler { id: theme; }
    Resources.CollectionData { id: collectionData; }
    Resources.GameData { id: gameData; }
    Resources.Sounds { id: sounds; }
    Resources.Music { id: music; }

    FontLoader {
        id: glyphs;

        property string favorite: '\ue805';
        property string unfavorite: '\ue802';
        property string settings: '\uf1de';
        property string enabled: '\ue800';
        property string disabled: '\uf096';
        property string play: '\ue801';
        property string fullStar: '\ue803';
        property string halfStar: '\uf123';
        property string emptyStar: '\ue804';

        source: "assets/images/fontello.ttf";
    }


    // ui components
    CollectionList.Component {
        id: collectionList;

        visible: currentView === 'collectionList';
        focus: currentView === 'collectionList';
    }

    GameList.Component {
        id: gameList;

        visible: currentView === 'gameList';
        focus: currentView === 'gameList';
    }

    GameDetails.Component {
        visible: currentView === 'gameDetails';
        focus: currentView === 'gameDetails';
    }

    Settings.Component {
        id: settingsComponent;

        visible: currentView === 'settings';
        focus: currentView === 'settings';
    }

    Sorting.Component {
        id: sortingComponent;

        visible: currentView === 'sorting';
        focus: currentView === 'sorting';
    }

    Attract.Component {
        id: attractComponent;

        visible: currentView === 'attract';
        focus: currentView === 'attract';
    }

    /* Text { id: debug; x: 20; y: 20; width: 20; height: 20; text: 'debug'; color: 'magenta'; } */
    /* Rectangle { width: 640; height: 480; color: 'transparent'; border.color: 'magenta'; } */
    /* Rectangle { width: 1280; height: 720; color: 'transparent'; border.color: 'magenta'; } */
}
