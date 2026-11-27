import QtQuick 2.15

Item {
    property Item current: lightTheme;
    property Item buttonGuide: switchButtons;
    // true for both the Xbox and PlayStation layouts: they share the same
    // physical button positions and key events (see PlayStationButtons.qml),
    // so everything that depends on which button is where keys off this
    property bool xboxMode: false;
    // the Accent Color setting: 'default' keeps each theme's own accent
    property string accent: 'default';
    // Overscan Margin: the fraction of the screen's width and height left
    // empty on each side (0 = off). Applied by theme.qml's safe area
    property double overscan: 0;
    // Larger Tap Targets: bigger footer buttons and header icons, with
    // bigger hit areas around them. See footer/ and header/
    property bool largeTargets: false;
    property bool verticalMode: false;
    // true when Display Mode is set to Grid: the Game List screen shows a
    // multi-column grid of box art (see components/gameList/GameGrid.qml)
    // instead of List mode's single-column list + art preview. Mutually
    // exclusive with verticalMode - both are just parsed from the same
    // 'displayMode' setting value.
    property bool gridMode: false;
    // true when Display Mode is set to Gallery: the Game List screen shows
    // a horizontal coverflow of box art (see components/gameList/GameGallery.qml)
    // instead of List mode's single-column list + art preview. Mutually
    // exclusive with verticalMode/gridMode - all three are just parsed
    // from the same 'displayMode' setting value.
    property bool galleryMode: false;
    property double fontScale: 1.0;

    function setFontScale() {
        const size = settings.get('fontSize');

        if (size === 'small') {
            fontScale = 0.5;
        } else if (size === 'medium') {
            fontScale = 0.75;
        } else {
            fontScale = 1.0;
        }
    }

    // every theme, by the value the Theme setting stores; the second field
    // says which palette the Accent Color setting uses on it
    readonly property var themesByName: ({
        'light': lightTheme, 'dark': darkTheme, 'black': blackTheme,
        'sapphire': sapphireTheme, 'ruby': rubyTheme, 'emerald': emeraldTheme,
        'amethyst': amethystTheme, 'amber': amberTheme, 'aquamarine': aquamarineTheme,
        'diamond': diamondTheme
    });

    function setColorTheme(value) {
        current = themesByName[value] ?? lightTheme;
    }

    // Accent colours, one set per kind of background: the light theme gets
    // the deeper tones so they stay readable on white. Applied by assigning
    // each theme's own accentColor, which everything reads through
    // theme.current.accentColor, so no screen needs to know about this.
    readonly property var accentColorsLight: ({
        'blue': '#2f7bdb', 'green': '#2a9d6a', 'orange': '#d9731a', 'red': '#d03a33',
        'purple': '#7d4cdb', 'pink': '#d4489a', 'yellow': '#b8860b'
    });
    readonly property var accentColorsDark: ({
        'blue': '#5b9bf0', 'green': '#4cc38a', 'orange': '#f0953c', 'red': '#e5534b',
        'purple': '#a371f7', 'pink': '#e879b9', 'yellow': '#e3b341'
    });

    function setAccentColor(value) {
        accent = value ?? 'default';

        for (const name in themesByName) {
            const item = themesByName[name];
            const palette = item.isDark ? accentColorsDark : accentColorsLight;

            item.accentColor = palette[accent] ?? item.defaultAccent;
        }
    }

    function setOverscan(value) {
        const percent = parseInt(value);
        overscan = isNaN(percent) ? 0 : percent / 100;
    }

    function setLargeTargets(value) {
        largeTargets = value === true;
    }

    // note the two names in play here: "controllerLayout" is the setting the
    // user picks, while "buttonGuide" is the glyph set it selects, which the
    // footers read as theme.buttonGuide.accept/cancel/etc
    function setControllerLayout(value) {
        xboxMode = (value === 'xbox' || value === 'playstation');

        if (value === 'playstation') {
            buttonGuide = playStationButtons;
        } else {
            buttonGuide = xboxMode ? xboxButtons : switchButtons;
        }
    }

    function setVerticalMode(value) {
        verticalMode = (value === 'sidebar');
    }

    function setGridMode(value) {
        gridMode = (value === 'grid');
    }

    function setGalleryMode(value) {
        galleryMode = (value === 'gallery');
    }

    Component.onCompleted: {
        settings.addCallback('colorTheme', setColorTheme);
        settings.addCallback('controllerLayout', setControllerLayout);
        settings.addCallback('fontSize', setFontScale);
        settings.addCallback('accentColor', setAccentColor);
        settings.addCallback('overscan', setOverscan);
        settings.addCallback('largeTapTargets', setLargeTargets);
        settings.addCallback('displayMode', setVerticalMode);
        settings.addCallback('displayMode', setGridMode);
        settings.addCallback('displayMode', setGalleryMode);
    }

    LightTheme { id: lightTheme; }
    DarkTheme { id: darkTheme; }
    BlackTheme { id: blackTheme; }

    // the coloured themes: each is the Dark theme tinted from one hue
    GemTheme { id: sapphireTheme; hue: .60; saturation: .75; }
    GemTheme { id: rubyTheme; hue: .99; saturation: .72; accentLightness: .6; }
    GemTheme { id: emeraldTheme; hue: .40; saturation: .65; accentSaturation: .55; accentLightness: .54; }
    GemTheme { id: amethystTheme; hue: .76; saturation: .55; accentLightness: .68; }
    GemTheme { id: amberTheme; hue: .11; saturation: .8; accentLightness: .52; }
    GemTheme { id: aquamarineTheme; hue: .49; saturation: .7; accentSaturation: .55; accentLightness: .52; }

    // Diamond: the Light theme in cool silver, with slate-grey selection bars
    LightTheme {
        id: diamondTheme;

        bgColor: '#dde1e6';
        highlightColor: '#3a424c';
        blurTextColor: '#2b3138';
        readableTextColor: '#2b3138';
        detailsColor: '#2b3138';
        textInputBackgroundColor: '#cdd2d8';
        textInputBorderColor: '#aeb5bd';
        textInputPlaceholderColor: '#9aa2ab';
        footerCountColor: '#8a929c';
        defaultAccent: '#7a8ca0';
    }
    SwitchButtons { id: switchButtons; }
    XboxButtons { id: xboxButtons; }
    PlayStationButtons { id: playStationButtons; }
}
