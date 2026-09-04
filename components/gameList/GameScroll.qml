import QtQuick 2.15

import '../media' as Media

Item {
    id: gameScrollRoot;

    property alias video: gameListVideo;
    property alias gamesListView: gamesListView;
    property alias letter: skipLetter.letter;
    property bool active: true;

    // sets the flashed letter and (re)runs the flash, even when it's the same
    // letter as last time - see SkipLetter.qml
    function flashLetter(value) {
        skipLetter.letter = value;
        skipLetter.flash();
    }

    // Whether this layout is the one the Display Mode has chosen. Distinct
    // from "active" above, which also goes false while the console sidebar
    // has focus - the list is still on screen then and must keep its model.
    //
    // A view with a model builds delegates for its viewport even when its
    // Item is hidden, so leaving all three layouts populated meant scrolling
    // one of them also churned delegates and decoded box art in the other
    // two. The inactive ones get a null model instead, and re-anchor to the
    // current game when they're switched back to.
    readonly property bool modeActive: !theme.gridMode && !theme.galleryMode;

    onModeActiveChanged: {
        if (!modeActive) return;

        gamesListView.currentIndex = currentGameIndex;
        if (currentGameIndex >= 0) {
            gamesListView.positionViewAtIndex(currentGameIndex, ListView.Center);
        }
    }

    property double itemHeight: {
        return gamesListView.height * .12 * theme.fontScale;
    }

    property var imageAssetTypes: [
        'boxFront', 'poster', 'screenshot', 'boxBack', 'logo', 'titlescreen',
        'marquee', 'steam', 'banner', 'tile', 'cartridge', 'boxSpine',
        'boxFull', 'bezel', 'panel', 'cabinetLeft', 'cabinetRight', 'background'
    ];

    property string currentImageType: '';

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline in the highlighted device image's "source" binding) so
    // toggling the setting updates the art immediately - see theme.qml's
    // note on why a direct binding to settings.get() never reacts to
    // later changes
    property bool compactDeviceArt: settings.get('compactDeviceArt');

    property string imgSrc: {
        // assets as well as currentGame: the fallback path below indexes into
        // it directly, and getDefaultImageType() never returns '' (it falls
        // back to a type name whether or not the game has one), so a game with
        // no assets object at all reached the index and threw
        if (!currentGame || !currentGame.assets) return '';

        if (currentImageType !== '' && assetAvailable(currentGame, currentImageType)) {
            return currentGame.assets[currentImageType];
        }

        // current game doesn't have the selected art type; fall back for
        // display only, without losing the user's chosen type for other games
        const fallbackType = getDefaultImageType(currentGame);
        return fallbackType === '' ? '' : currentGame.assets[fallbackType];
    }

    function assetAvailable(game, type) {
        if (!game || !game.assets) return false;

        return game.assets[type] !== undefined && game.assets[type] !== '';
    }

    // Picks the starting image for a newly selected game, respecting the
    // 'Prefer Box to Poster' setting before falling back to the first
    // available asset type.
    function getDefaultImageType(game) {
        if (!game) return 'boxFront';

        const preferBox = settings.get('preferBox');
        const primary = preferBox ? 'boxFront' : 'poster';
        const secondary = preferBox ? 'poster' : 'boxFront';

        if (assetAvailable(game, primary)) return primary;
        if (assetAvailable(game, secondary)) return secondary;

        for (let i = 0; i < imageAssetTypes.length; i++) {
            if (assetAvailable(game, imageAssetTypes[i])) return imageAssetTypes[i];
        }

        return primary;
    }

    // Which of the types above the Cycle Art button actually steps through,
    // from the 'cycleArt' setting. 'common' is the default: walking 18 types
    // to reach a screenshot is tedious when most of them aren't scraped
    // anyway. 'all' is the full list, i.e. the behaviour this button had
    // before the setting existed.
    readonly property var cycleArtGroups: {
        'all': imageAssetTypes,
        'common': ['boxFront', 'poster', 'screenshot'],
        'boxes': ['boxFront', 'boxBack', 'boxSpine', 'boxFull'],
        'screens': ['screenshot', 'titlescreen', 'background'],
    };

    // tracked as a real QML property with a callback, for the same reason
    // compactDeviceArt above is - settings.get() reads a plain JS object
    // that never notifies QML, so a direct binding would only ever evaluate
    // once
    property string cycleArt: settings.get('cycleArt');

    // The chosen group, always with the type this game would show by default
    // folded in: without it, picking e.g. Screens would strand the art on a
    // screenshot with no way back to box art. Filtered out of
    // imageAssetTypes rather than used directly so the cycle keeps the same
    // order whichever group is selected.
    function cycleArtTypes(game) {
        const group = cycleArtGroups[cycleArt] ?? imageAssetTypes;
        if (group === imageAssetTypes) return imageAssetTypes;

        const fallback = getDefaultImageType(game);

        return imageAssetTypes.filter(function (type) {
            return group.indexOf(type) !== -1 || type === fallback;
        });
    }

    // Finds the next asset type (in imageAssetTypes order) that actually
    // exists for the current game, wrapping back to the start if needed.
    function getNextImageType(game) {
        if (!game) return currentImageType;

        const types = cycleArtTypes(game);
        // -1 when the type on screen isn't in the current group at all, which
        // starts the walk one before the first entry so the first press lands
        // on it rather than skipping past it
        const startIndex = types.indexOf(currentImageType);

        for (let i = 1; i <= types.length; i++) {
            const nextIndex = (startIndex + i + types.length) % types.length;
            const nextType = types[nextIndex];

            if (assetAvailable(game, nextType)) return nextType;
        }

        return currentImageType;
    }

    function resetImageType() {
        currentImageType = getDefaultImageType(currentGame);
    }

    // Carries the cycled art type across a game launch, and only across a
    // game launch.
    //
    // Pegasus tears the whole theme down while a game runs and builds it
    // again when the game exits (see theme.qml's launchGame()), so without
    // this the art snapped back to box front every time the player quit a
    // game. It's written on the way out to a game and blanked for every
    // other teardown - quitting Pegasus, reloading or switching themes - so
    // the next cold start of the launcher opens on box art again.
    readonly property string imageTypeMemoryKey: 'gameListImageType';

    function restoreImageType() {
        const saved = api.memory.get(imageTypeMemoryKey);

        // Cleared as soon as it's read, the same way theme.qml handles its
        // resumeAfterGame flag: api.memory is flushed to disk on every set,
        // so from here on the stored state already reads "cold start" and a
        // crash or a pulled power cable can't leave a stale type behind.
        if (saved) api.memory.set(imageTypeMemoryKey, '');

        // A type that's no longer in imageAssetTypes (an install coming from
        // a version with a different list) would leave the art on imgSrc's
        // per-game fallback with no way back into the cycle, since
        // getNextImageType() starts from indexOf(currentImageType).
        if (saved && imageAssetTypes.indexOf(saved) !== -1) {
            currentImageType = saved;
            return;
        }

        resetImageType();
    }

    function cycleImageType() {
        if (!currentGame) return;
        currentImageType = getNextImageType(currentGame);
    }

    property string noGameText: {
        if (nameFilter != '') {
            return 'No Games With "' + nameFilter + '"';
        }

        return 'No Games';
    }

    // named rather than anonymous so they can be handed back to
    // removeCallback() below - an anonymous function can't be
    function gameListVideoCallback() { gameListVideo.switchVideo(); }
    function preferBoxCallback() { resetImageType(); }

    // narrowing the group can leave the art on a type the button can no
    // longer reach, so drop back to the game's normal art when that happens
    function cycleArtCallback(value) {
        cycleArt = value;

        if (cycleArtTypes(currentGame).indexOf(currentImageType) === -1) {
            resetImageType();
        }
    }

    function compactDeviceArtCallback(value) { compactDeviceArt = value; }

    Component.onCompleted: {
        gamesListView.currentIndex = currentGameIndex;
        if (currentGameIndex >= 0) {
            gamesListView.positionViewAtIndex(currentGameIndex, ListView.Center);
        }
        restoreImageType();

        settings.addCallback('gameListVideo', gameListVideoCallback);
        settings.addCallback('preferBox', preferBoxCallback);
        settings.addCallback('cycleArt', cycleArtCallback);
        settings.addCallback('compactDeviceArt', compactDeviceArtCallback);
    }

    Component.onDestruction: {
        // launchingGame is theme.qml's own flag, set by launchGame() and
        // false for every other teardown - the one thing in here that can
        // tell "the player is going into a game" apart from "the launcher is
        // closing". See restoreImageType() above.
        api.memory.set(imageTypeMemoryKey, launchingGame ? currentImageType : '');

        settings.removeCallback('gameListVideo', gameListVideoCallback);
        settings.removeCallback('preferBox', preferBoxCallback);
        settings.removeCallback('cycleArt', cycleArtCallback);
        settings.removeCallback('compactDeviceArt', compactDeviceArtCallback);
    }

    Text {
        visible: gameCount() === 0;
        text: noGameText;
        anchors.centerIn: theme.verticalMode ? gamesListView : parent;
        color: theme.current.blurTextColor;
        opacity: 0.5;

        font {
            pixelSize: parent.height * .065;
            letterSpacing: -0.3;
            bold: true;
        }
    }

    ListView {
        id: gamesListView;

        model: modeActive ? currentGameList : null;
        delegate: lvGameDelegate;
        // recycle delegates instead of destroying and rebuilding one per row
        // as it crosses the viewport edge - the single biggest scroll cost in
        // a long list, since each row otherwise re-registers its settings
        // callbacks and rebuilds its text/logo items from scratch
        reuseItems: true;
        width: (parent.width / 2) - 20; // 20 is left margin
        height: parent.height - 24;
        highlightMoveDuration: 0;
        preferredHighlightBegin: itemHeight - 12; // height of an item minus top margin
        preferredHighlightEnd: height - (itemHeight + 12); // height of an item plus bottom margin
        // "height", not "parent.height": this range is measured inside the
        // view's own viewport, which is 24px shorter than the parent Item
        // (12px top + 12px bottom margin), so the parent's height pushed the
        // range 24px past the bottom edge
        highlightRangeMode: ListView.ApplyRange;

        anchors {
            left: parent.left;
            leftMargin: 20;
            top: parent.top;
            topMargin: 12;
            bottom: parent.bottom;
            bottomMargin: 12;
        }

        highlight: Rectangle {
            color: collectionData.getColor(currentShortName);
            // fully hidden (rather than dimmed) while browsing the console
            // sidebar, so no game appears selected until one is actually focused
            opacity: theme.current.bgOpacity * (active ? 1 : 0);
            radius: 8;
            width: gamesListView.width;
        }

        onCurrentIndexChanged: {
            gameListVideo.switchVideo();
        }
    }

    Component {
        id: lvGameDelegate;

        GameItem {
            width: gamesListView.width;
            height: itemHeight;
        }
    }

    SkipLetter {
        id: skipLetter;

        anchors {
            verticalCenter: gamesListView.verticalCenter;
            horizontalCenter: gamesListView.horizontalCenter;
        }
    }

    Media.GameImage {
        id: gameListBoxart;

        width: parent.width / 2;
        height: parent.height;
        x: parent.width / 2;
        imageSource: imgSrc;
        // qualified with gameScrollRoot. - GameImage declares its own
        // "active" property, so an unqualified reference here would shadow
        // itself instead of picking up this screen's real active state
        active: gameScrollRoot.active;
    }

    Media.GameVideo {
        id: gameListVideo;

        width: parent.width / 2;
        height: parent.height;
        x: parent.width / 2;
        settingKey: 'gameListVideo';
        validView: 'gameList';
        active: gameScrollRoot.active;

        onVideoToggled: {
            gameListBoxart.videoPlaying = videoPlaying;
        }
    }

    // shown instead of the game art/video while browsing the console
    // sidebar (i.e. before a console has actually been selected) - shows
    // that console's device art, same image used by the standalone Collection Screen
    Item {
        id: highlightedDeviceOverlay;

        visible: !gameScrollRoot.active;
        width: parent.width / 2;
        height: parent.height;
        x: parent.width / 2;

        Rectangle {
            color: theme.current.bgColor;
            anchors.fill: parent;
        }

        Image {
            id: highlightedDeviceImage;

            // tracked separately instead of overwriting "source" directly,
            // so a missing image for one console doesn't permanently break
            // the binding for every console highlighted afterwards
            property bool loadFailed: false;

            source: loadFailed
                ? (compactDeviceArt ? '../../assets/images/devicesCompact/default.png' : '../../assets/images/devices/default.png')
                : (compactDeviceArt ? '../../assets/images/devicesCompact/' : '../../assets/images/devices/') + collectionData.getImage(currentShortName) + '.png';
            fillMode: Image.PreserveAspectFit;
            asynchronous: true;
            smooth: true;
            // the bundled device art goes up to 2570x2208 - about 22MB of
            // pixels - for something drawn a few hundred pixels wide. Bound
            // to this panel's geometry, which doesn't change as consoles are
            // highlighted, so switching console never re-triggers a load
            sourceSize.width: Math.round(parent.width * .65);
            sourceSize.height: Math.round(parent.height * .65);
            width: parent.width * .65;
            height: parent.height * .65;
            anchors.centerIn: parent;

            onStatusChanged: {
                if (status === Image.Error) {
                    loadFailed = true;
                }
            }
        }
    }

    // reset the fallback flag whenever a different console is highlighted,
    // so the real artwork is tried again instead of getting stuck on default.png
    Connections {
        target: root;
        function onCurrentShortNameChanged() {
            highlightedDeviceImage.loadFailed = false;
        }
    }

    // The sort-order label that used to sit under the art panel is gone.
    // sortKey has been pinned to 'sortBy' since the sorting screen was
    // removed, so its text resolved to gameData.lastPlayedText, which was
    // itself hardcoded empty - the element rendered an empty string forever.
}
