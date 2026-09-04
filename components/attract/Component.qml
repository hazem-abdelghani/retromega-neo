import QtQuick 2.15
import QtMultimedia 5.9
import SortFilterProxyModel 0.2

Item {
    property bool showTitle: true;
    property var currentAttractGame;

    anchors.fill: parent;

    function quietAttractCallback(enabled) {
        if (enabled) attractPlayer.volume = 0;
        else attractPlayer.volume = .7;
    }

    function onCancelPressed() {
        currentView = theme.verticalMode ? 'gameList' : 'collectionList';
        sounds.back();
    }

    function onDetailsPressed() {
        settings.toggle('attractTitle');
        showTitle = settings.get('attractTitle');
    }

    function onAcceptPressed() {
        // nextVideo() leaves this unset when nothing in the library has a
        // video, and the screen sits on "No Videos Found" - Accept used to
        // read straight through it and take the theme down
        if (!currentAttractGame) return;

        launchGame(currentAttractGame);
    }

    // nextVideo() is re-entered from the player's own onStatusChanged when a
    // scraped path is broken, so a library whose video assets have all moved
    // (an external drive that didn't mount, say) spun through every entry as
    // fast as the backend could fail them. Counted instead, and the screen
    // settles on a message once a run of them has failed.
    property int failedVideos: 0;
    readonly property int maxFailedVideos: 10;

    // see attractGames below - raised for exactly as long as this screen is
    // the one being shown
    property bool proxyActive: false;

    function noVideosMessage(text) {
        currentAttractGame = null;
        showTitle = true;
        attractTitle.text = text;
        collectionTitle.text = '';
    }

    function stopVideo() {
        attractPlayer.stop();
        proxyActive = false;
        music.volumeCheck();
    }

    function startVideo() {
        showTitle = settings.get('attractTitle');
        failedVideos = 0;
        proxyActive = true;
        nextVideo();
        music.volumeCheck();
    }

    function nextVideo() {
        const gameCount = attractGames.count;

        if (gameCount === 0) {
            // cleared, not just left alone: a stale game here is what Accept
            // would otherwise still try to launch
            noVideosMessage('No Videos Found');
            return;
        }

        const randomIndex = Math.floor(Math.random() * gameCount);
        currentAttractGame = api.allGames.get(attractGames.mapToSource(randomIndex));

        if (!currentAttractGame) {
            noVideosMessage('No Videos Found');
            return;
        }

        attractPlayer.source = currentAttractGame.assets.video;
        attractTitle.text = currentAttractGame.title;

        // a game with no collection would throw on .name
        const collection = currentAttractGame.collections.get(0);
        collectionTitle.text = collection ? collection.name : '';
    }

    // isAutoRepeat guards to match every other Keys handler in the theme:
    // holding a direction used to fire nextVideo() once per repeat, each call
    // tearing down the player and assigning a fresh source
    Keys.onUpPressed: { event.accepted = true; if (!event.isAutoRepeat) nextVideo(); }
    Keys.onDownPressed: { event.accepted = true; if (!event.isAutoRepeat) nextVideo(); }
    Keys.onLeftPressed: { event.accepted = true; if (!event.isAutoRepeat) nextVideo(); }
    Keys.onRightPressed: { event.accepted = true; if (!event.isAutoRepeat) nextVideo(); }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isAccept(event)) {
            event.accepted = true;
            onAcceptPressed();
        }

        if (api.keys.isCancel(event)) {
            event.accepted = true;
            onCancelPressed();
        }

        if (api.keys.isDetails(event)) {
            event.accepted = true;
            onDetailsPressed();
        }

        if (api.keys.isFilters(event)) {
            event.accepted = true;
            nextVideo();
        }
    }

    // L2 - pressing Attract again while already on this screen backs out of it,
    // matching the R2/L2-toggle behavior expected from the footer buttons
    Keys.onReleased: {
        // matches every Keys.onPressed handler in the theme: a held trigger
        // must not re-fire this screen's action once per repeat
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isPageUp(event)) {
            event.accepted = true;
            onCancelPressed();
        }
    }

    // right-click acts as the B/Cancel button on this screen too
    MouseArea {
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton;
        onClicked: onCancelPressed();
    }

    SortFilterProxyModel {
        id: attractGames;

        // Only mapped while attract mode is actually on screen. This is the
        // one proxy in the theme that isn't backing something visible: it was
        // built at theme load and read assets.video for every game in the
        // library, then stayed subscribed to api.allGames - a startup cost
        // paid by everyone whether or not they ever press Attract. Same
        // treatment the three Display Mode layouts already give their views.
        //
        // Driven by a flag that startVideo() raises itself rather than by
        // currentView directly: nextVideo() reads this model's count on the
        // very next line, and a binding on currentView would be racing the
        // same change signal that invoked startVideo() in the first place.
        // Assigning sourceModel repopulates synchronously, so by the time
        // startVideo() gets to nextVideo() the mapping is already there.
        sourceModel: proxyActive ? api.allGames : null;
        filters: [
            ExpressionFilter { expression: { return assets.video !== ''; } }
        ]
    }

    // named so it can be handed back to removeCurrentViewCallback() below
    function currentViewCallback(view) {
        if (view === 'attract') {
            startVideo();
        } else {
            stopVideo();
        }
    }

    Component.onCompleted: {
        addCurrentViewCallback(currentViewCallback);

        music.registerVideo(attractPlayer);
        if (currentView === 'attract') startVideo();

        quietAttractCallback(settings.get('quietVideo'));
        settings.addCallback('quietVideo', quietAttractCallback);
    }

    Component.onDestruction: {
        removeCurrentViewCallback(currentViewCallback);
        music.unregisterVideo(attractPlayer);
        settings.removeCallback('quietVideo', quietAttractCallback);
    }

    Connections {
        target: Qt.application;
        function onStateChanged() {
            if (currentView !== 'attract') return;

            if (Qt.application.state === Qt.ApplicationActive) {
                startVideo();
            } else {
                stopVideo();
            }
        }
    }

    Video {
        id: attractPlayer;

        volume: 0.7;
        fillMode: VideoOutput.PreserveAspectFit;
        anchors.fill: parent;
        autoPlay: true;

        onStatusChanged: {
            if (status === MediaPlayer.Buffered || status === MediaPlayer.Loaded) {
                failedVideos = 0;
            }

            if (status === MediaPlayer.InvalidMedia) {
                failedVideos++;

                if (failedVideos >= maxFailedVideos) {
                    noVideosMessage('No Playable Videos');
                    return;
                }

                nextVideo();
            }

            if (status === MediaPlayer.EndOfMedia) {
                nextVideo();
            }
        }
    }

    Text {
        id: attractTitle;

        visible: showTitle;
        width: parent.width;
        color: 'white';
        style: Text.Outline;
        styleColor: 'black';
        horizontalAlignment: Text.AlignHCenter;
        elide: Text.ElideRight;
        maximumLineCount: 2;
        wrapMode: Text.WordWrap;
        opacity: .6;

        font {
            pixelSize: root.height * .06;
            bold: true;
        }

        anchors {
            top: parent.top;
            topMargin: root.height * .025;
            left: parent.left;
            leftMargin: root.width * .03;
            right: parent.right;
            rightMargin: root.width * .03;
        }
    }

    Text {
        id: collectionTitle;

        visible: showTitle;
        width: parent.width;
        color: 'white';
        style: Text.Outline;
        styleColor: 'black';
        horizontalAlignment: Text.AlignHCenter;
        elide: Text.ElideRight;
        maximumLineCount: 1;
        wrapMode: Text.WordWrap;
        opacity: .6;

        font {
            pixelSize: root.height * .06;
            bold: true;
        }

        anchors {
            bottom: parent.bottom;
            bottomMargin: root.height * .025;
            left: parent.left;
            leftMargin: root.width * .03;
            right: parent.right;
            rightMargin: root.width * .03;
        }
    }
}
