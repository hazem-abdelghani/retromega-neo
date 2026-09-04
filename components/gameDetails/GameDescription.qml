import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    property var blurSource;

    function resetFlickable() {
        flickable.contentY = -flickable.topMargin;
    }

    function scrollUp() {
        flickable.contentY = Math.max(
            -flickable.topMargin,
            flickable.contentY - fullDesc.font.pixelSize
        );
    }

    function scrollDown() {
        // clamped against the flickable's own viewport rather than root.height
        // - the two happen to be near-identical here, but the bound belongs to
        // the thing actually doing the scrolling. Floored at the resting
        // position too, so a description shorter than the viewport can't be
        // pushed off the top.
        const maxY = Math.max(
            -flickable.topMargin,
            flickable.contentHeight - flickable.height + flickable.bottomMargin
        );

        flickable.contentY = Math.min(flickable.contentY + fullDesc.font.pixelSize, maxY);
    }

    // solves some kerning issues with period and commas
    property var descText: {
        // description as well as currentGame: a game scraped without one
        // leaves it undefined, and .replace() below would throw on it. This
        // binding re-evaluates every time the selection moves, not only while
        // the full description is on screen, so it has to tolerate any game
        if (!currentGame || !currentGame.description) return '';

        return currentGame.description
            .replace(/\. {1,}/g, '.  ')
            .replace(/, {1,}/g, ',  ');
    }

    property var fullDescText: {
        if (filenames === '') return descText;
        return descText + "\n\n" + filenames;
    }

    // this screen is constructed before any game is selected, and
    // collectionList's onAcceptPressed() deliberately sets currentGame back
    // to null, so this has to tolerate both states the same way descText does
    property var filenames: {
        if (!currentGame) return '';
        if (!currentGame.files || currentGame.files.count === 0) return '';

        if (currentGame.files.count === 1) {
            return 'file: ' + currentGame.files.get(0).path;
        }

        const files = [];
        for (let i = 0; i < currentGame.files.count; i++) {
            files.push(currentGame.files.get(i).path);
        }

        return "files:\n  - " + files.join("\n  - ");
    }

    // background to lighten or darken the blur effect, since it's translucent
    Rectangle {
        color: theme.current.bgColor;
        anchors.fill: parent;
    }

    FastBlur {
        width: root.width;
        height: root.height;
        radius: 80;
        opacity: .4;
        source: blurSource;
        cached: true;
    }

    Flickable {
        id: flickable;

        contentWidth: fullDesc.width;
        contentHeight: fullDesc.height;
        flickableDirection: Flickable.VerticalFlick;
        anchors.fill: parent;
        clip: true;
        bottomMargin: 40;
        leftMargin: 40;
        rightMargin: 40;
        topMargin: 40;

        Behavior on contentY {
            PropertyAnimation { easing.type: Easing.OutCubic; duration: 150; }
        }

        Text {
            id: fullDesc;

            width: root.width - flickable.leftMargin - flickable.rightMargin;
            text: fullDescText;
            wrapMode: Text.WordWrap;
            lineHeight: 1.2;
            color: theme.current.detailsColor;
            horizontalAlignment: Text.AlignJustify;

            font {
                pixelSize: root.height * .045 * theme.fontScale;
                letterSpacing: -0.35;
                bold: true;
            }
        }
    }

    MouseArea {
        anchors.fill: parent;

        onClicked: {
            detailsButtonClicked('less');
        }
    }
}
