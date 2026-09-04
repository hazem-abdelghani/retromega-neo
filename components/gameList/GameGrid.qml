import QtQuick 2.15
import QtGraphicalEffects 1.12

// Grid layout for the Game List screen (Display Mode: Grid), showing box
// art in a multi-column grid instead of List mode's single-column list +
// large art preview. Concept and card styling (rounded art, focus border,
// bottom title overlay) adapted from Beacon Lite's GameGridView.qml, but
// rebuilt on this theme's own data model, colors and settings instead of
// Beacon's ThemeManager/FontManager/utils.js.

Item {
    id: gameGridRoot;

    property alias gridView: grid;
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
    readonly property bool modeActive: theme.gridMode;

    onModeActiveChanged: {
        if (!modeActive) return;

        grid.currentIndex = currentGameIndex;
        if (currentGameIndex >= 0) {
            grid.positionViewAtIndex(currentGameIndex, GridView.Contain);
        }
    }

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline) so toggling the setting updates the grid immediately - see
    // theme.qml's note on why a direct binding to settings.get() never
    // reacts to later changes
    property string cardsSize: settings.get('cardsSize');
    function cardsSizeCallback(value) { cardsSize = value; }

    // maps the "Cards Size" setting to a column count - more columns means
    // smaller cards, fewer columns means bigger cards, since cell size is
    // always derived from the available width divided by this number
    readonly property var columnsBySize: { 'small': 7, 'medium': 5, 'large': 4 };
    readonly property int columns: columnsBySize[cardsSize] ?? 5;

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline in each cell's image source binding) so toggling the setting
    // updates the grid immediately - see theme.qml's note on why a direct
    // binding to settings.get() never reacts to later changes
    property bool preferBox: settings.get('preferBox');

    function preferBoxCallback(value) { preferBox = value; }

    // tracked the same way as preferBox/cardsSize above, so toggling either
    // setting updates the grid immediately - mirrors GameItem.qml's/
    // GameGallery.qml's own logoTitles/logoDropShadow handling
    property bool logoTitles: settings.get('logoTitles');
    property bool logoDropShadow: settings.get('dropShadow');

    // Rounding a card's corners means masking its art, and a mask costs an
    // offscreen texture plus a shader pass per card - so a screenful of cards
    // is a screenful of both. Turning this off drops the mask entirely and
    // draws the art square, which is the cheaper way to render the grid on a
    // slower device.
    property bool roundedCards: settings.get('roundedCards');

    function logoTitlesCallback(value) { logoTitles = value; }
    function logoDropShadowCallback(value) { logoDropShadow = value; }
    function roundedCardsCallback(value) { roundedCards = value; }

    Component.onCompleted: {
        settings.addCallback('preferBox', preferBoxCallback);
        settings.addCallback('cardsSize', cardsSizeCallback);
        settings.addCallback('logoTitles', logoTitlesCallback);
        settings.addCallback('dropShadow', logoDropShadowCallback);
        settings.addCallback('roundedCards', roundedCardsCallback);

        grid.currentIndex = currentGameIndex;
        // positionViewAtIndex(-1) warns and does nothing useful; -1 is the
        // "empty collection" index (see theme.qml's updateGameIndex)
        if (currentGameIndex >= 0) {
            grid.positionViewAtIndex(currentGameIndex, GridView.Contain);
        }
    }

    Component.onDestruction: {
        settings.removeCallback('preferBox', preferBoxCallback);
        settings.removeCallback('cardsSize', cardsSizeCallback);
        settings.removeCallback('logoTitles', logoTitlesCallback);
        settings.removeCallback('dropShadow', logoDropShadowCallback);
        settings.removeCallback('roundedCards', roundedCardsCallback);
    }

    property var imageAssetTypes: [
        'boxFront', 'poster', 'screenshot', 'boxBack', 'logo', 'titlescreen',
        'marquee', 'steam', 'banner', 'tile', 'cartridge', 'boxSpine',
        'boxFull', 'bezel', 'panel', 'cabinetLeft', 'cabinetRight', 'background'
    ];

    // picks the best available art for a grid cell, respecting the
    // 'Prefer Box to Poster' setting before falling back to the first
    // available asset type - mirrors GameScroll's getDefaultImageType()
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

    GridView {
        id: grid;

        visible: gameCount() > 0;
        model: gameGridRoot.modeActive ? currentGameList : null;
        reuseItems: true;
        // swipe to scroll (tap-to-select still works via the delegate's
        // MouseArea below); was previously false, which silently disabled
        // touch scrolling in this Display Mode
        interactive: true;
        cellWidth: Math.floor(width / gameGridRoot.columns);
        cellHeight: Math.floor(cellWidth * 1.32);
        cacheBuffer: cellHeight * 2;

        anchors {
            fill: parent;
            leftMargin: 16;
            rightMargin: 16;
            topMargin: 16;
            bottomMargin: 16;
        }

        delegate: Item {
            id: cell;

            width: grid.cellWidth;
            height: grid.cellHeight;

            readonly property bool isCurrent: GridView.isCurrentItem && gameGridRoot.active;

            // The card is sized from its art's aspect ratio, and the Behaviors
            // below smooth that out - but a recycled delegate arrives still
            // wearing the previous game's dimensions, so those Behaviors turned
            // every reuse into a visible morph as the list scrolled. Suppressed
            // from the moment the delegate is handed new content until that
            // content's art has actually resolved, so the card just snaps to
            // its new shape.
            property bool animateSize: true;

            GridView.onReused: animateSize = false;
            readonly property bool showFavorite: {
                return favorite
                    && currentCollection
                    && currentCollection.shortName !== 'favorites';
            }
            // mirrors GameItem.qml's/GameGallery.qml's showLogo check
            readonly property bool showLogo: {
                return gameGridRoot.logoTitles
                    && assets
                    && assets.logo !== undefined
                    && assets.logo !== '';
            }

            Item {
                id: art;

                // the outer cell stays a fixed size (GridView needs uniform
                // tiles for row/column keyboard navigation), but the card
                // itself is sized to match the actual box art's aspect
                // ratio and centered in the slot - so horizontal art (e.g.
                // some arcade/PC boxes) renders as a wide card instead of
                // being force-fit into a tall portrait frame
                readonly property real maxWidth: cell.width - 20;
                readonly property real maxHeight: cell.height - 20;
                // fallback ratio (matches this grid's old fixed 1:1.32
                // frame) used until the image finishes loading and reports
                // its real dimensions
                // implicit size rather than sourceSize: sourceSize now reports
                // the decode bound requested below, not the art's own
                // dimensions, while implicitWidth/implicitHeight still carry
                // the loaded image's real (aspect-preserving) size
                readonly property real aspect: (gridImage.status === Image.Ready && gridImage.implicitHeight > 0)
                    ? (gridImage.implicitWidth / gridImage.implicitHeight)
                    : (1 / 1.32);

                width: (maxWidth / maxHeight > aspect) ? (maxHeight * aspect) : maxWidth;
                height: (maxWidth / maxHeight > aspect) ? maxHeight : (maxWidth / aspect);
                anchors.centerIn: parent;

                Behavior on width { enabled: cell.animateSize; NumberAnimation { duration: 150; } }
                Behavior on height { enabled: cell.animateSize; NumberAnimation { duration: 150; } }

                Rectangle {
                    id: cardBg;
                    anchors.fill: parent;
                    radius: 10;
                    color: theme.current.highlightColor;
                    opacity: 0.35;
                }

                Text {
                    opacity: gridImage.status === Image.Ready ? 0 : 1;
                    anchors.centerIn: parent;
                    text: title ? title.charAt(0).toUpperCase() : '';
                    color: theme.current.blurTextColor;

                    Behavior on opacity { NumberAnimation { duration: 150; } }

                    font {
                        pixelSize: parent.height * .22;
                        bold: true;
                    }
                }

                Image {
                    id: gridImage;
                    anchors.fill: parent;
                    source: gameGridRoot.imageFor(assets);
                    fillMode: Image.PreserveAspectFit;
                    asynchronous: true;
                    smooth: true;
                    cache: true;
                    // drawn directly when the corners aren't rounded; the
                    // masked copy below stands in for it when they are.
                    // Ready-or-not is opacity rather than this visible line,
                    // so the letter above and the art here can crossfade
                    // instead of one instantly replacing the other.
                    visible: !gameGridRoot.roundedCards;
                    opacity: status === Image.Ready ? 1 : 0;
                    // decode to roughly the size it's drawn at rather than
                    // whatever the scraper produced. Bound to the grid's cell
                    // size, which only changes with Cards Size or the window,
                    // so this never re-triggers a load while scrolling
                    sourceSize.width: Math.round(grid.cellWidth);
                    sourceSize.height: Math.round(grid.cellHeight);

                    // releases the size-animation suppression above once this
                    // delegate's new art has settled one way or the other
                    onStatusChanged: {
                        if (status !== Image.Loading) cell.animateSize = true;
                    }

                    Behavior on opacity { NumberAnimation { duration: 150; } }
                }

                // Loader rather than just hiding these: a ShaderEffect claims
                // its source and mask items as texture providers whether or
                // not it's visible, so an invisible OpacityMask would still
                // be paying for the mask's offscreen texture. No separate
                // fade needed here either - this samples gridImage as its
                // source, so gridImage's own opacity Behavior above already
                // carries through into the masked result automatically.
                Loader {
                    anchors.fill: parent;
                    active: gameGridRoot.roundedCards;
                    visible: gridImage.status === Image.Ready;

                    sourceComponent: Component {
                        Item {
                            Rectangle {
                                id: gridMask;
                                anchors.fill: parent;
                                radius: 10;
                                visible: false;
                            }

                            OpacityMask {
                                anchors.fill: parent;
                                source: gridImage;
                                maskSource: gridMask;
                            }
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left;
                        right: parent.right;
                        bottom: parent.bottom;
                    }
                    height: parent.height * .4;
                    radius: 10;
                    opacity: cell.isCurrent ? 1 : 0;

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: '#00000000'; }
                        GradientStop { position: 1.0; color: '#cc000000'; }
                    }

                    Behavior on opacity { NumberAnimation { duration: 120; } }
                }

                Rectangle {
                    anchors.fill: parent;
                    radius: 10;
                    color: 'transparent';
                    border {
                        width: 3;
                        color: collectionData.getColor(currentShortName);
                    }
                    opacity: cell.isCurrent ? 1 : 0;

                    Behavior on opacity { NumberAnimation { duration: 120; } }
                }

                Text {
                    visible: cell.isCurrent && !cell.showLogo;
                    text: title;
                    color: '#ffffff';
                    elide: Text.ElideRight;
                    wrapMode: Text.WordWrap;
                    maximumLineCount: 2;
                    horizontalAlignment: Text.AlignHCenter;

                    anchors {
                        left: parent.left;
                        right: parent.right;
                        bottom: parent.bottom;
                        margins: 8;
                    }

                    font {
                        pixelSize: parent.height * .075;
                        bold: true;
                    }
                }

                Image {
                    id: gridLogo;

                    visible: cell.isCurrent && cell.showLogo;
                    source: cell.showLogo ? assets.logo : '';
                    fillMode: Image.PreserveAspectFit;
                    horizontalAlignment: Image.AlignHCenter;
                    verticalAlignment: Image.AlignBottom;
                    asynchronous: true;
                    smooth: true;
                    height: parent.height * .3;

                    layer.enabled: gameGridRoot.logoDropShadow;
                    layer.effect: DropShadow {
                        color: theme.current.dropShadowColor;
                        verticalOffset: 5;
                        radius: 20;
                        samples: 41;
                        cached: true;
                    }

                    anchors {
                        left: parent.left;
                        right: parent.right;
                        bottom: parent.bottom;
                        margins: 8;
                    }
                }

                Text {
                    // shown on every favorited card, the same way List mode
                    // marks every favorited row. It used to be gated on
                    // isCurrent, which made the grid the only view where you
                    // couldn't see your favorites at a glance.
                    visible: cell.showFavorite;
                    text: glyphs.favorite;
                    color: '#ffffff';
                    style: Text.Outline;
                    styleColor: '#99000000';

                    anchors {
                        top: parent.top;
                        right: parent.right;
                        margins: 8;
                    }

                    font {
                        family: glyphs.name;
                        pixelSize: parent.height * .09;
                    }
                }

            }

            MouseArea {
                anchors.fill: parent;

                onClicked: {
                    if (grid.currentIndex === index) {
                        onAcceptPressed();
                    } else {
                        const updated = updateGameIndex(index);
                        if (updated) { sounds.nav(); }
                    }
                }

                onPressAndHold: {
                    if (grid.currentIndex === index) {
                        onDetailsPressed();
                    } else {
                        const updated = updateGameIndex(index);
                        if (updated) { sounds.nav(); }
                    }
                }
            }
        }
    }

    SkipLetter {
        id: skipLetter;

        anchors.centerIn: grid;
    }
}
