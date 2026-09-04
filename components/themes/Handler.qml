import QtQuick 2.15

Item {
    property Item current: lightTheme;
    property Item buttonGuide: switchButtons;
    property bool xboxMode: false;
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

    function setColorTheme(value) {
        current = (value === 'dark') ? darkTheme : lightTheme;
    }

    // note the two names in play here: "controllerLayout" is the setting the
    // user picks, while "buttonGuide" is the glyph set it selects, which the
    // footers read as theme.buttonGuide.accept/cancel/etc
    function setControllerLayout(value) {
        xboxMode = (value === 'xbox');
        buttonGuide = xboxMode ? xboxButtons : switchButtons;
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
        settings.addCallback('displayMode', setVerticalMode);
        settings.addCallback('displayMode', setGridMode);
        settings.addCallback('displayMode', setGalleryMode);
    }

    LightTheme { id: lightTheme; }
    DarkTheme { id: darkTheme; }
    SwitchButtons { id: switchButtons; }
    XboxButtons { id: xboxButtons; }
}
