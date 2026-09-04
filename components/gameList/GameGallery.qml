import QtQuick 2.15
import QtGraphicalEffects 1.12

// Horizontal coverflow layout for the Game List screen (Display Mode:
// Gallery): the current game's box art sits large and centered, with
// smaller thumbnails for its neighbours to either side. Concept and card
// styling (featured card grows, thumbnails shrink, rounded art, focus
// border) adapted from Beacon Lite's GameListView.qml (its "Gallery" view
// mode), but rebuilt on this theme's own data model, colors and settings
// instead of Beacon's ThemeManager/FontManager/utils.js/ReflectionEffect.

Item {
    id: gameGalleryRoot;

    property alias carousel: carousel;
    property alias letter: skipLetter.letter;
    property bool active: true;

    // sets the flashed letter and (re)runs the flash, even when it's the same
    // letter as last time - see SkipLetter.qml
    function flashLetter(value) {
        skipLetter.letter = value;
        skipLetter.flash();
    }

    // see GameScroll.qml's note: only the Display Mode's own layout carries a
    // model, so the other two aren't building delegates behind it
    readonly property bool modeActive: theme.galleryMode;

    // Repopulating the strip makes the view pick its own currentIndex, and
    // onCurrentIndexChanged below writes that straight back to the theme -
    // which would reset the selection to the first game every time Gallery
    // was switched to. Suppressed while the strip settles - both on a mode
    // switch and on the initial layout pass at startup, which is what
    // muteStartup covers alongside it.
    property bool restoringIndex: false;

    onModeActiveChanged: {
        if (!modeActive) return;

        restoringIndex = true;
        carousel.currentIndex = currentGameIndex;

        if (currentGameIndex >= 0) {
            carousel.positionViewAtIndex(currentGameIndex, ListView.Center);
        }

        restoreGuardTimer.restart();
    }

    Timer {
        id: restoreGuardTimer;

        // outlasts the strip's own 200ms highlightMoveDuration, since
        // StrictlyEnforceRange keeps nudging currentIndex until it settles
        interval: 300;
        repeat: false;
        onTriggered: {
            restoringIndex = false;
            muteStartup = false;
        }
    }

    // tracked as real QML properties (rather than re-reading settings.get()
    // inline in bindings) so toggling the settings updates the gallery
    // immediately - see theme.qml's note on why a direct binding to
    // settings.get() never reacts to later changes
    property bool preferBox: settings.get('preferBox');
    property bool darkMode: settings.get('colorTheme') === 'dark';
    property bool logoTitles: settings.get('logoTitles');
    property bool logoDropShadow: settings.get('dropShadow');
    property string cardsSize: settings.get('cardsSize');

    // see GameGrid.qml: rounding a card's corners costs a mask texture and a
    // shader pass per card, and this is the switch that trades the rounding
    // away for speed
    property bool roundedCards: settings.get('roundedCards');

    // suppresses the navigation sound (and the index write-back) while the
    // carousel is still settling into its initial position during startup,
    // mirroring CollectionScroll.qml's own muteStartup guard
    property bool muteStartup: true;

    function preferBoxCallback(value) { preferBox = value; }
    function darkModeCallback(value) { darkMode = (value === 'dark'); }
    function logoTitlesCallback(value) { logoTitles = value; }
    function logoDropShadowCallback(value) { logoDropShadow = value; }
    function cardsSizeCallback(value) { cardsSize = value; }
    function roundedCardsCallback(value) { roundedCards = value; }

    Component.onCompleted: {
        settings.addCallback('preferBox', preferBoxCallback);
        settings.addCallback('colorTheme', darkModeCallback);
        settings.addCallback('logoTitles', logoTitlesCallback);
        settings.addCallback('dropShadow', logoDropShadowCallback);
        settings.addCallback('cardsSize', cardsSizeCallback);
        settings.addCallback('roundedCards', roundedCardsCallback);

        // Same settling problem onModeActiveChanged above guards against, and
        // it applies just as much here: this used to clear muteStartup
        // synchronously, before the strip had a model or had finished moving,
        // so StrictlyEnforceRange's intermediate currentIndex values went
        // straight back into updateGameIndex() - resuming from a game in
        // Gallery mode could land on the wrong title, with nav clicks firing
        // during startup. Released by the same timer instead.
        restoringIndex = true;
        carousel.currentIndex = currentGameIndex;

        if (currentGameIndex >= 0) {
            carousel.positionViewAtIndex(currentGameIndex, ListView.Center);
        }

        restoreGuardTimer.restart();
    }

    Component.onDestruction: {
        settings.removeCallback('preferBox', preferBoxCallback);
        settings.removeCallback('colorTheme', darkModeCallback);
        settings.removeCallback('logoTitles', logoTitlesCallback);
        settings.removeCallback('dropShadow', logoDropShadowCallback);
        settings.removeCallback('cardsSize', cardsSizeCallback);
        settings.removeCallback('roundedCards', roundedCardsCallback);
    }

    property var imageAssetTypes: [
        'boxFront', 'poster', 'screenshot', 'boxBack', 'logo', 'titlescreen',
        'marquee', 'steam', 'banner', 'tile', 'cartridge', 'boxSpine',
        'boxFull', 'bezel', 'panel', 'cabinetLeft', 'cabinetRight', 'background'
    ];

    // picks the best available art for a card, respecting the 'Prefer Box
    // to Poster' setting before falling back to the first available asset
    // type - mirrors GameScroll's getDefaultImageType() / GameGrid's imageFor()
    function imageFor(assets) {
        if (assets === undefined) return '';

        const primary = preferBox ? 'boxFront' : 'poster';
        const secondary = preferBox ? 'poster' : 'boxFront';

        if (assets[primary]) return assets[primary];
        if (assets[secondary]) return assets[secondary];

        for (let i = 0; i < imageAssetTypes.length; i++) {
            if (assets[imageAssetTypes[i]]) return assets[imageAssetTypes[i]];
        }

        return '';
    }

    readonly property bool showLogo: {
        return logoTitles
            && currentGame
            && currentGame.assets
            && currentGame.assets.logo !== undefined
            && currentGame.assets.logo !== '';
    }

    // maps the "Cards Size" setting to how much of the screen's height the
    // featured card takes up - featuredH drives thumbH and (via each card's
    // own aspect ratio) card width too, so this scales the whole strip
    readonly property var featuredScaleBySize: { 'small': .5, 'medium': .62, 'large': .74 };
    readonly property real featuredH: Math.round(height * (featuredScaleBySize[cardsSize] ?? .62));
    readonly property real thumbH: Math.round(featuredH * .68);
    // fallback ratio (this gallery's old fixed width:height ratio) used
    // before a card's image has loaded and reported its real aspect ratio
    readonly property real fallbackAspect: .72;
    // the strip's highlight range needs a concrete width to center on.
    // deliberately NOT derived from carousel.currentItem.width - that would
    // make the view's own positioning depend on its current delegate's
    // size, which depends on the view's state (isCurrent), a feedback loop
    // that's harmless while interactive is false but can crash once the
    // Flickable is actively enforcing StrictlyEnforceRange against it. This
    // is a fixed reference width instead, so a very wide/narrow cover might
    // land a few pixels off-center, which is an acceptable trade for
    // stability - this component keeps running in the background (kept in
    // sync with the current game/collection) even when Gallery isn't the
    // active Display Mode.
    readonly property real currentCardWidth: Math.round(featuredH * fallbackAspect);

    Text {
        visible: gameCount() === 0;
        text: nameFilter !== '' ? ('No Games With "' + nameFilter + '"') : 'No Games';
        anchors.centerIn: parent;
        color: theme.current.blurTextColor;
        opacity: 0.5;

        font {
            pixelSize: parent.height * .065;
            letterSpacing: -0.3;
            bold: true;
        }
    }

    Column {
        visible: gameCount() > 0;
        spacing: 18;

        anchors {
            top: parent.top;
            topMargin: gameGalleryRoot.height * .05;
            left: parent.left;
            right: parent.right;
            bottom: parent.bottom;
        }

        ListView {
            id: carousel;

            width: parent.width;
            height: gameGalleryRoot.featuredH + 24;
            orientation: ListView.Horizontal;
            // swipe to scroll through the strip (tap-to-select still works
            // via the delegate's MouseArea below); was previously false,
            // which silently disabled touch scrolling in this Display Mode
            interactive: true;
            clip: false;
            spacing: 24;
            model: gameGalleryRoot.modeActive ? currentGameList : null;
            reuseItems: true;
            highlightRangeMode: ListView.StrictlyEnforceRange;
            preferredHighlightBegin: (width - gameGalleryRoot.currentCardWidth) / 2;
            preferredHighlightEnd: (width + gameGalleryRoot.currentCardWidth) / 2;
            highlightMoveDuration: 200;

            // "interactive" plus StrictlyEnforceRange means a swipe moves the
            // view's own currentIndex without anything telling the rest of the
            // theme about it - updateIndex() only ever pushes the other way.
            // Without this, flicking the strip left the title below it, the
            // footer counter and the Play target all pointing at the game you
            // *used* to be on. Guarded against re-entry (updateGameIndex calls
            // back into updateIndex, which writes this same value) and against
            // the transient -1/0 a model swap produces.
            onCurrentIndexChanged: {
                if (muteStartup) return;
                if (gameGalleryRoot.restoringIndex) return;
                if (!theme.galleryMode) return;
                if (currentIndex < 0) return;
                if (currentIndex === currentGameIndex) return;

                const updated = updateGameIndex(currentIndex);
                if (updated) sounds.nav();
            }

            delegate: Item {
                id: card;

                readonly property bool isCurrent: ListView.isCurrentItem && gameGalleryRoot.active;

                // see GameGrid.qml: a recycled delegate arrives still sized to
                // the previous game's cover, and the grow/shrink Behaviors
                // below would animate their way out of it in full view. The
                // featured-card growth this same Behavior drives happens on
                // navigation, long after the art has loaded, so it's unaffected.
                property bool animateSize: true;

                ListView.onReused: animateSize = false;
                // card width follows the box art's own aspect ratio (so a
                // horizontal cover renders as a wide card) instead of a
                // fixed ratio; falls back to the old default ratio until
                // the image has loaded and reported its real size
                // implicit size rather than sourceSize - see GameGrid.qml
                readonly property real aspect: (cardImage.status === Image.Ready && cardImage.implicitHeight > 0)
                    ? (cardImage.implicitWidth / cardImage.implicitHeight)
                    : gameGalleryRoot.fallbackAspect;
                width: (isCurrent ? gameGalleryRoot.featuredH : gameGalleryRoot.thumbH) * aspect;
                height: carousel.height;

                Behavior on width { enabled: card.animateSize; NumberAnimation { duration: 200; easing.type: Easing.OutQuad; } }

                Item {
                    id: art;
                    width: parent.width;
                    height: isCurrent ? gameGalleryRoot.featuredH : gameGalleryRoot.thumbH;
                    anchors.top: parent.top;

                    Behavior on height { enabled: card.animateSize; NumberAnimation { duration: 200; easing.type: Easing.OutQuad; } }

                    Rectangle {
                        id: cardBg;
                        anchors.fill: parent;
                        radius: 12;
                        color: theme.current.highlightColor;
                        opacity: 0.35;
                    }

                    Text {
                        opacity: cardImage.status === Image.Ready ? 0 : 1;
                        anchors.centerIn: parent;
                        text: title ? title.charAt(0).toUpperCase() : '';
                        color: theme.current.blurTextColor;

                        Behavior on opacity { NumberAnimation { duration: 150; } }

                        font {
                            pixelSize: parent.height * .2;
                            bold: true;
                        }
                    }

                    Image {
                        id: cardImage;
                        anchors.fill: parent;
                        source: gameGalleryRoot.imageFor(assets);
                        fillMode: Image.PreserveAspectFit;
                        asynchronous: true;
                        smooth: true;
                        cache: true;
                        // drawn directly when the corners aren't rounded; the
                        // masked copy below stands in for it when they are.
                        // Ready-or-not is opacity rather than this visible
                        // line, so the letter above and the art here can
                        // crossfade instead of one instantly replacing the
                        // other.
                        visible: !gameGalleryRoot.roundedCards;
                        opacity: status === Image.Ready ? 1 : 0;
                        // sized off the featured card (the largest a card ever
                        // gets), not the card's own animating size, so growing
                        // and shrinking a card never reloads its art
                        sourceSize.height: Math.round(gameGalleryRoot.featuredH);

                        // releases the size-animation suppression above once
                        // this delegate's new art has settled one way or the other
                        onStatusChanged: {
                            if (status !== Image.Loading) card.animateSize = true;
                        }

                        Behavior on opacity { NumberAnimation { duration: 150; } }
                    }

                    // see GameGrid.qml for why this is a Loader and not just
                    // a visibility toggle, and why it doesn't need its own
                    // fade - it samples cardImage as its source, so
                    // cardImage's own opacity Behavior above already carries
                    // through into the masked result automatically
                    Loader {
                        anchors.fill: parent;
                        active: gameGalleryRoot.roundedCards;
                        visible: cardImage.status === Image.Ready;

                        sourceComponent: Component {
                            Item {
                                Rectangle {
                                    id: cardMask;
                                    anchors.fill: parent;
                                    radius: 12;
                                    visible: false;
                                }

                                OpacityMask {
                                    anchors.fill: parent;
                                    source: cardImage;
                                    maskSource: cardMask;
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent;
                        radius: 12;
                        color: '#000000';
                        opacity: card.isCurrent ? 0 : 0.4;

                        Behavior on opacity { NumberAnimation { duration: 150; } }
                    }

                    Rectangle {
                        anchors.fill: parent;
                        radius: 12;
                        color: 'transparent';
                        border {
                            width: 3;
                            color: collectionData.getColor(currentShortName);
                        }
                        opacity: card.isCurrent ? 1 : 0;

                        Behavior on opacity { NumberAnimation { duration: 150; } }
                    }
                }

                MouseArea {
                    anchors.fill: parent;

                    onClicked: {
                        if (carousel.currentIndex === index) {
                            onAcceptPressed();
                        } else {
                            const updated = updateGameIndex(index);
                            if (updated) { sounds.nav(); }
                        }
                    }

                    onPressAndHold: {
                        if (carousel.currentIndex === index) {
                            onDetailsPressed();
                        } else {
                            const updated = updateGameIndex(index);
                            if (updated) { sounds.nav(); }
                        }
                    }
                }
            }
        }

        // Column refuses to position a child that sets left/right/
        // horizontalCenter/fill/centerIn ("Column will not function"), so the
        // centered Row lives inside a full-width Item instead of anchoring
        // itself against the Column directly
        Item {
            width: parent.width;
            height: titleRow.height;

            Row {
                id: titleRow;

                anchors.horizontalCenter: parent.horizontalCenter;
                spacing: 10;

                Text {
                    text: glyphs.favorite;
                    visible: currentGame && currentGame.favorite === true
                        && currentCollection
                        && currentCollection.shortName !== 'favorites';
                    color: gameGalleryRoot.darkMode ? theme.current.focusTextColor : '#000000';
                    anchors.verticalCenter: parent.verticalCenter;

                    font {
                        family: glyphs.name;
                        pixelSize: gameGalleryRoot.height * .04;
                    }
                }

                Text {
                    visible: !gameGalleryRoot.showLogo;
                    text: currentGame ? currentGame.title : '';
                    // matches List mode's game list: white text over the dark
                    // theme, but plain black once the Light theme is picked
                    color: gameGalleryRoot.darkMode ? theme.current.focusTextColor : '#000000';
                    elide: Text.ElideRight;
                    horizontalAlignment: Text.AlignHCenter;
                    width: Math.min(implicitWidth, gameGalleryRoot.width * .8);
                    anchors.verticalCenter: parent.verticalCenter;

                    font {
                        pixelSize: gameGalleryRoot.height * .05;
                        letterSpacing: -0.3;
                        bold: true;
                    }
                }

                Image {
                    id: galleryLogo;

                    visible: gameGalleryRoot.showLogo;
                    source: gameGalleryRoot.showLogo ? currentGame.assets.logo : '';
                    fillMode: Image.PreserveAspectFit;
                    asynchronous: true;
                    smooth: true;
                    height: gameGalleryRoot.height * .09;
                    // Follows the logo's own aspect ratio, capped at half the
                    // screen. A fixed width reserved that much space in the
                    // Row no matter how narrow the logo actually drew, so the
                    // favorite glyph beside it sat well off to the left of
                    // center. implicitWidth/implicitHeight carry the loaded
                    // image's real size and don't depend on this item's own
                    // width, so there's no loop; the multiplier is just a
                    // stand-in until the image reports back.
                    width: Math.min(
                        implicitHeight > 0 ? height * (implicitWidth / implicitHeight) : height * 3,
                        gameGalleryRoot.width * .5
                    );
                    anchors.verticalCenter: parent.verticalCenter;

                    layer.enabled: gameGalleryRoot.logoDropShadow;
                    layer.effect: DropShadow {
                        color: theme.current.dropShadowColor;
                        verticalOffset: 5;
                        radius: 20;
                        samples: 41;
                        cached: true;
                    }
                }
            }
        }
    }

    SkipLetter {
        id: skipLetter;

        anchors.centerIn: gameGalleryRoot;
    }
}
