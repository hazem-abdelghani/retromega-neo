import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: gameItemRoot;

    property bool showFavorite: {
        return favorite
            && currentCollection
            && currentCollection.shortName !== 'favorites';
    }

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline in the logo Image's "visible" binding) so toggling the setting
    // updates the game list immediately - see theme.qml's note on why a
    // direct binding to settings.get() never reacts to later changes
    property bool logoTitles: settings.get('logoTitles');

    // tracked the same way as logoTitles above, so the logo's shadow can
    // be toggled immediately alongside the box art / video shadow
    property bool logoDropShadow: settings.get('dropShadow');

    property bool showLogo: {
        // "assets" is a model role, so it re-reads whenever this delegate is
        // recycled or the list swaps models underneath it - and it can be
        // momentarily absent while that happens. GameGallery's equivalent
        // check already guarded the object before reaching into it; this one
        // and GameGrid's didn't.
        return logoTitles
            && assets
            && assets.logo !== undefined
            && assets.logo !== '';
    }

    function logoTitlesCallback(enabled) {
        logoTitles = enabled;
    }

    function logoDropShadowCallback(enabled) {
        logoDropShadow = enabled;
    }

    Component.onCompleted: {
        settings.addCallback('logoTitles', logoTitlesCallback);
        settings.addCallback('dropShadow', logoDropShadowCallback);
    }

    Component.onDestruction: {
        settings.removeCallback('logoTitles', logoTitlesCallback);
        settings.removeCallback('dropShadow', logoDropShadowCallback);
    }

    MouseArea {
        anchors.fill: parent;

        onClicked: {
            if (gamesListView.currentIndex === index) {
                onAcceptPressed();
            } else {
                const updated = updateGameIndex(index);
                if (updated) { sounds.nav(); }
            }
        }

        onPressAndHold: {
            if (gamesListView.currentIndex === index) {
                onDetailsPressed();
            } else {
                const updated = updateGameIndex(index);
                if (updated) { sounds.nav(); }
            }
        }
    }

    // Marquee title: behaves exactly like the plain elided Text this
    // replaces when the row is unselected or the title already fits, but
    // once a too-long title is focused it scrolls left to reveal the rest,
    // looping with a bullet separator - ported from Flat Ozone's
    // GameListView.qml gameMarqueeContainer.
    Item {
        id: gameTitleContainer;

        visible: !showLogo;
        clip: true;
        height: parent.height;

        property bool isSelected: active && gamesListView.currentIndex === index;
        property bool needsScroll: gameTitleText1.implicitWidth > gameTitleContainer.width;
        property real scrollOffset: 0;
        property real cycleWidth: gameTitleText1.implicitWidth + gameTitleSep.implicitWidth;

        anchors {
            left: parent.left;
            leftMargin: 12;
            right: parent.right;
            rightMargin: showFavorite ? parent.height * .36 + 10 : 10;
        }

        Text {
            id: gameTitleText1;
            text: title;
            verticalAlignment: Text.AlignVCenter;
            elide: gameTitleContainer.isSelected ? Text.ElideNone : Text.ElideRight;
            width: gameTitleContainer.isSelected ? implicitWidth : gameTitleContainer.width;
            height: parent.height;
            x: -gameTitleContainer.scrollOffset;
            color: gameTitleContainer.isSelected
                ? theme.current.focusTextColor
                : theme.current.blurTextColor;

            font {
                pixelSize: gameItemRoot.height * .43;
                letterSpacing: -0.3;
                bold: true;
            }
        }

        Text {
            id: gameTitleSep;
            text: "  •  ";
            verticalAlignment: Text.AlignVCenter;
            elide: Text.ElideNone;
            height: parent.height;
            x: gameTitleText1.implicitWidth - gameTitleContainer.scrollOffset;
            visible: gameTitleContainer.needsScroll;
            color: gameTitleContainer.isSelected
                ? theme.current.focusTextColor
                : theme.current.blurTextColor;

            font {
                pixelSize: gameItemRoot.height * .43;
                letterSpacing: -0.3;
                bold: true;
            }
        }

        Text {
            id: gameTitleText2;
            text: title;
            verticalAlignment: Text.AlignVCenter;
            elide: Text.ElideNone;
            height: parent.height;
            x: gameTitleText1.implicitWidth + gameTitleSep.implicitWidth - gameTitleContainer.scrollOffset;
            visible: gameTitleContainer.needsScroll;
            color: gameTitleContainer.isSelected
                ? theme.current.focusTextColor
                : theme.current.blurTextColor;

            font {
                pixelSize: gameItemRoot.height * .43;
                letterSpacing: -0.3;
                bold: true;
            }
        }

        // Pauses 1s on the start of the title (scrollOffset reset instantly
        // via PropertyAction, not animated, so the loop restart is a plain
        // snap rather than a visible reverse-slide) before scrolling once
        // through, then repeats.
        SequentialAnimation {
            id: gameTitleMarqueeAnim;
            loops: Animation.Infinite;
            running: false;

            PropertyAction {
                target: gameTitleContainer;
                property: "scrollOffset";
                value: 0;
            }

            PauseAnimation { duration: 1000; }

            NumberAnimation {
                target: gameTitleContainer;
                property: "scrollOffset";
                from: 0;
                to: gameTitleContainer.cycleWidth;
                duration: gameTitleContainer.cycleWidth * 22;
                easing.type: Easing.Linear;
            }
        }

        onIsSelectedChanged: {
            gameTitleContainer.scrollOffset = 0;
            gameTitleMarqueeAnim.stop();
            if (isSelected && needsScroll) {
                gameTitleMarqueeAnim.start();
            }
        }

        onNeedsScrollChanged: {
            if (isSelected && needsScroll) {
                gameTitleContainer.scrollOffset = 0;
                gameTitleMarqueeAnim.start();
            } else {
                gameTitleMarqueeAnim.stop();
                gameTitleContainer.scrollOffset = 0;
            }
        }
    }

    Image {
        id: gameLogo;

        visible: showLogo;
        source: showLogo ? assets.logo : '';
        fillMode: Image.PreserveAspectFit;
        horizontalAlignment: Image.AlignHCenter;
        verticalAlignment: Image.AlignVCenter;
        asynchronous: true;
        smooth: true;
        height: parent.height * .78;
        // logos are drawn one row tall; decoding them at full size was the
        // expensive half of turning on "Replace Game Names with Logos"
        sourceSize.height: Math.round(height);

        layer.enabled: logoDropShadow;
        layer.effect: DropShadow {
            color: theme.current.dropShadowColor;
            verticalOffset: 5;
            radius: 20;
            samples: 41;
            cached: true;
        }

        anchors {
            left: parent.left;
            leftMargin: 12;
            right: parent.right;
            rightMargin: showFavorite ? parent.height * .36 + 10 : 10;
            verticalCenter: parent.verticalCenter;
        }
    }

    Text {
        visible: showFavorite;
        text: glyphs.favorite;
        verticalAlignment: Text.AlignVCenter;
        color: (active && gamesListView.currentIndex === index)
            ? theme.current.focusTextColor
            : theme.current.blurTextColor;
        height: parent.height;

        font {
            family: glyphs.name;
            pixelSize: parent.height * .3;
        }

        anchors {
            verticalCenter: parent.verticalCenter;
            right: parent.right;
            rightMargin: 10;
        }
    }
}
