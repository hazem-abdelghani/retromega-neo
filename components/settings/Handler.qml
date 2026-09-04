import QtQuick 2.15

Item {
    property var keys: [
        // Appearance
        'displayMode', 'cardsSize', 'fontSize', 'colorTheme', 'compactDeviceArt', 'collectionLogos', 'logoTitles', 'dropShadow', 'roundedCards',
        // Sound
        'bgMusic', 'navSounds',
        // Controls
        'controllerLayout',
        // Date & Time
        'twentyFourHour',
        // Media & Artwork
        'cycleArt', 'preferBox', 'screenshotPreview', 'gameListVideo', 'gameDetailsVideo', 'quietVideo', 'quickVideo', 'attractTitle', 'delayedImage',
        // Collections
        'favoritesOnTop', 'showAllGames', 'startOnAllGames', 'showRecents', 'showFavorites'
    ];

    // maps the first key of a group to the section title shown above it in
    // the settings list, so related settings are visually grouped together
    property var sections: {
        'displayMode': 'Appearance',
        'bgMusic': 'Sound',
        'controllerLayout': 'Controls',
        'twentyFourHour': 'Date & Time',
        'cycleArt': 'Media & Artwork',
        'favoritesOnTop': 'Collections',
    }

    function sectionTitle(key) { return sections[key]; }

    // most settings are simple on/off toggles; a key listed here instead
    // cycles through a fixed list of values (see "options" below) each time
    // it's activated, rendered as a labelled value rather than an on/off icon
    property var types: {
        'displayMode': 'select',
        'cardsSize': 'select',
        'fontSize': 'select',
        'colorTheme': 'select',
        'controllerLayout': 'select',
        'cycleArt': 'select',
    }

    property var options: {
        'displayMode': ['list', 'sidebar', 'grid', 'gallery'],
        'cardsSize': ['small', 'medium', 'large'],
        'fontSize': ['large', 'medium', 'small'],
        'colorTheme': ['light', 'dark'],
        'controllerLayout': ['switch', 'xbox'],
        'cycleArt': ['all', 'common', 'boxes', 'screens'],
    }

    property var optionLabels: {
        'displayMode': { 'list': 'List', 'sidebar': 'Sidebar', 'grid': 'Grid', 'gallery': 'Gallery' },
        'cardsSize': { 'small': 'Small', 'medium': 'Medium', 'large': 'Large' },
        'fontSize': { 'large': 'Large', 'medium': 'Medium', 'small': 'Small' },
        'colorTheme': { 'light': 'Light', 'dark': 'Dark' },
        'controllerLayout': { 'switch': 'Switch', 'xbox': 'Xbox' },
        // kept to roughly the width of "Sidebar"/"Gallery" - the value
        // column in SettingsItem is a fixed width and elides past that
        'cycleArt': { 'all': 'All Art', 'common': 'Common', 'boxes': 'Box Art', 'screens': 'Screens' },
    }

    // Some settings only do anything in certain Display Modes. Those rows stay
    // in the list and are grayed out instead of being hidden, so the list
    // never reshuffles underneath the selection (see SettingsScroll.qml).
    //
    // "mode" is optional: QML bindings pass the Display Mode in explicitly so
    // they re-evaluate when it changes, since get() reads a plain JS object
    // that doesn't notify. Plain JS callers can leave it out.
    function isRelevant(key, mode, allGamesShown) {
        const displayMode = mode ?? get('displayMode');

        if (key === 'cardsSize' || key === 'roundedCards') {
            return displayMode === 'grid' || displayMode === 'gallery';
        }

        // the Cycle Art button is only wired up on the single-column game
        // list (List and Sidebar) - Grid and Gallery pick art per card and
        // onFiltersPressed() returns early in both
        if (key === 'cycleArt') {
            return displayMode === 'list' || displayMode === 'sidebar';
        }

        // the inset and floating panel are both drawn on the Grid/Gallery
        // card layouts only - List/Sidebar already have a large permanent
        // art panel, so a screenshot preview there would have nothing to
        // add
        if (key === 'screenshotPreview') {
            return displayMode === 'grid' || displayMode === 'gallery';
        }

        // there's nothing to start on if the All Games collection itself is
        // switched off, so the row above this one disables it
        if (key === 'startOnAllGames') {
            return allGamesShown ?? get('showAllGames');
        }

        return true;
    }

    function type(key) { return types[key] ?? 'toggle'; }
    function title(key) { return titles[key]; }
    function toggle(key) { set(key, !values[key]); }

    // step defaults to +1 (Accept's behaviour); Left/Right on the settings
    // screen pass -1/+1 so a multi-option row can be walked both ways instead
    // of only wrapping forward
    function cycle(key, step = 1) {
        const opts = options[key];
        if (opts === undefined) return;

        const currentIndex = opts.indexOf(get(key));

        // -1 means the stored value isn't one of the options at all, which
        // sanitized() should have caught - land on a real option either way
        // rather than letting the modulo below pick an arbitrary one
        const nextIndex = (currentIndex === -1)
            ? (step > 0 ? 0 : opts.length - 1)
            : (currentIndex + step + opts.length) % opts.length;

        set(key, opts[nextIndex]);
    }

    // activates a row the way Accept/tap does: toggles booleans, cycles selects
    function activate(key) {
        if (type(key) === 'select') {
            cycle(key);
        } else {
            toggle(key);
        }
    }

    function optionLabel(key) {
        const value = get(key);
        const labels = optionLabels[key];

        if (labels === undefined || labels[value] === undefined) return value;

        return labels[value];
    }

    // Settings that used to be stored under a different key, or as a plain
    // on/off boolean before becoming a named list of options. Consulted only
    // when the current key isn't in api.memory yet, so an existing install
    // keeps the choice it already made instead of quietly reverting.
    function migrated(key) {
        if (key === 'colorTheme') {
            const old = api.memory.get('darkMode');
            if (old === undefined || old === null) return undefined;

            return old ? 'dark' : 'light';
        }

        if (key === 'controllerLayout') {
            const old = api.memory.get('buttonGuide');
            if (old === undefined || old === null) return undefined;

            return old ? 'xbox' : 'switch';
        }

        return undefined;
    }

    // Rejects a stored value that's no longer one of the options - e.g. an
    // install carrying displayMode: 'classic', which is now called 'list'.
    // Without this the value survives in memory, matches nothing, and the
    // row's label renders as the raw string until it's cycled.
    function sanitized(key, value) {
        const opts = options[key];

        if (opts === undefined) return value;
        if (opts.indexOf(value) !== -1) return value;

        return defaults[key];
    }

    function get(key) {
        if (values[key] === null) {
            // ?? rather than ||: an on/off setting stored as false is a real
            // value and must not fall through to the default
            const stored = api.memory.get(key) ?? migrated(key) ?? defaults[key];
            set(key, sanitized(key, stored));
        }

        return values[key];
    }

    function saveAll() {
        for (const key of keys) {
            api.memory.set(key, get(key));
        }
    }

    function set(key, value) {
        if (values[key] === undefined) return;

        values[key] = value;
        callback(key);
    }

    function addCallback(key, callback) {
        if (callbacks[key] === undefined) return;

        callbacks[key].push(callback);
    }

    function removeCallback(key, callback) {
        if (callbacks[key] === undefined) return;

        const index = callbacks[key].indexOf(callback);
        if (index !== -1) {
            callbacks[key].splice(index, 1);
        }
    }

    function callback(key) {
        if (callbacks[key] === undefined) return;

        for (let i = 0; i < callbacks[key].length; i++) {
            try {
                callbacks[key][i](values[key]);
            } catch (e) {
                // one broken callback must not stop the rest from running, but
                // swallowing it outright hid real errors - a component whose
                // callback throws just goes quietly out of sync forever, with
                // nothing anywhere to say why. Reported and then carried on.
                console.warn('settings: callback for "' + key + '" threw:', e);
            }
        }
    }

    property var defaults: {
        'cycleArt': 'common',
        'screenshotPreview': true,
        'displayMode': 'list',
        'cardsSize': 'medium',
        'bgMusic': false,
        'navSounds': true,
        'colorTheme': 'light',
        'controllerLayout': 'xbox',
        'twentyFourHour': false,
        'fontSize': 'medium',
        'preferBox': true,
        'gameListVideo': false,
        'gameDetailsVideo': false,
        'quietVideo': false,
        'quickVideo': false,
        'dropShadow': true,
        // on by default: this is how the cards have always looked, and the
        // setting exists to trade that away for speed, not the other way round
        'roundedCards': true,
        'logoTitles': false,
        'attractTitle': true,
        'favoritesOnTop': false,
        'delayedImage': false,
        'showAllGames': true,
        'startOnAllGames': true,
        'showRecents': true,
        'showFavorites': true,
        'compactDeviceArt': false,
        'collectionLogos': false,
    }

    property var values: {
        'cycleArt': null,
        'screenshotPreview': null,
        'displayMode': null,
        'cardsSize': null,
        'bgMusic': null,
        'navSounds': null,
        'colorTheme': null,
        'controllerLayout': null,
        'twentyFourHour': null,
        'fontSize': null,
        'preferBox': null,
        'gameListVideo': null,
        'gameDetailsVideo': null,
        'quietVideo': null,
        'quickVideo': null,
        'dropShadow': null,
        'roundedCards': null,
        'logoTitles': null,
        'attractTitle': null,
        'favoritesOnTop': null,
        'delayedImage': null,
        'showAllGames': null,
        'startOnAllGames': null,
        'showRecents': null,
        'showFavorites': null,
        'compactDeviceArt': null,
        'collectionLogos': null,
    }

    property var callbacks: {
        'cycleArt': [],
        'screenshotPreview': [],
        'displayMode': [],
        'cardsSize': [],
        'bgMusic': [],
        'navSounds': [],
        'colorTheme': [],
        'controllerLayout': [],
        'twentyFourHour': [],
        'fontSize': [],
        'preferBox': [],
        'gameListVideo': [],
        'gameDetailsVideo': [],
        'quietVideo': [],
        'quickVideo': [],
        'dropShadow': [],
        'roundedCards': [],
        'logoTitles': [],
        'attractTitle': [],
        'favoritesOnTop': [],
        'delayedImage': [],
        'showAllGames': [],
        'startOnAllGames': [],
        'showRecents': [],
        'showFavorites': [],
        'compactDeviceArt': [],
        'collectionLogos': [],
    }

    property var titles: {
        'displayMode': 'Display Mode',
        'cardsSize': 'Cards Size',
        'bgMusic': 'Background Music',
        'navSounds': 'Navigation Sounds',
        'colorTheme': 'Theme',
        'controllerLayout': 'Controller Layout',
        'twentyFourHour': 'Use 24-Hour Format',
        'fontSize': 'Font Size',
        'cycleArt': 'Cycle Art Types',
        'screenshotPreview': 'Cards Screenshot Preview',
        'preferBox': 'Prefer Box to Poster',
        'gameListVideo': 'Video on Game List',
        'gameDetailsVideo': 'Video on Game Details',
        'quietVideo': 'Silent Videos',
        'quickVideo': 'Shorter Video Delay',
        'dropShadow': 'Artwork Drop Shadow',
        'roundedCards': 'Rounded Card Corners',
        'logoTitles': 'Replace Game Names with Logos',
        'attractTitle': 'Game Title on Attract Mode',
        'favoritesOnTop': 'Favorites on Top',
        'delayedImage': 'Delayed Images',
        'showAllGames': 'Show All Games Collection',
        'startOnAllGames': 'Start on All Games',
        'showRecents': 'Show Last Played Collection',
        'showFavorites': 'Show Favorites Collection',
        'compactDeviceArt': 'Compact Device Art',
        'collectionLogos': 'Replace Collection Names with Logos',
    }
}
