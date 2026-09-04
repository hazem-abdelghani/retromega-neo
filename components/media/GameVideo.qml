import QtQuick 2.15
import QtMultimedia 5.9
import QtGraphicalEffects 1.12

Item {
    property string settingKey: '';
    property string validView: '';
    property bool active: true;
    signal videoToggled(bool videoPlaying);

    function switchVideo() {
        videoPlayer.stop();
        videoPlayer.source = '';

        music.volumeCheck();

        videoPlayerTimer.restart();
        videoToggled(false);
    }

    function videoOff() {
        switchVideo();
        videoPlayerTimer.stop();
    }

    function quickVideoCallback(enabled) {
        if (enabled) videoPlayerTimer.interval = 500;
        else videoPlayerTimer.interval = 2000;
    }

    function quietVideoCallback(enabled) {
        if (enabled) videoPlayer.volume = 0;
        else videoPlayer.volume = .7;
    }

    function dropShadowCallback(enabled) {
        if (enabled) {
            dropShadow.visible = true;
            videoPlayer.visible = false;
        } else {
            videoPlayer.visible = true;
            dropShadow.visible = false;
        }
    }

    // named so it can be handed back to removeCurrentViewCallback() below
    function currentViewCallback(view) {
        if (view === validView) {
            switchVideo();
        } else {
            videoOff();
        }
    }

    Component.onCompleted: {
        addCurrentViewCallback(currentViewCallback);

        music.registerVideo(videoPlayer);

        quickVideoCallback(settings.get('quickVideo'));
        settings.addCallback('quickVideo', quickVideoCallback);

        quietVideoCallback(settings.get('quietVideo'));
        settings.addCallback('quietVideo', quietVideoCallback);

        dropShadowCallback(settings.get('dropShadow'));
        settings.addCallback('dropShadow', dropShadowCallback);
    }

    Component.onDestruction: {
        removeCurrentViewCallback(currentViewCallback);

        music.unregisterVideo(videoPlayer);

        settings.removeCallback('quickVideo', quickVideoCallback);
        settings.removeCallback('quietVideo', quietVideoCallback);
        settings.removeCallback('dropShadow', dropShadowCallback);
    }

    Connections {
        target: Qt.application;
        function onStateChanged() {
            // the old guard was "source === ''", which is exactly the state
            // videoOff() leaves behind - so once the app had been backgrounded
            // one time, resuming it always returned early and the preview
            // video never came back until you moved to another game. Gate on
            // whether this component is the one on screen instead.
            if (!active) return;
            if (currentView !== validView) return;

            if (Qt.application.state === Qt.ApplicationActive) {
                switchVideo();
            } else {
                videoOff();
            }
        }
    }

    onActiveChanged: {
        if (!active) videoOff();
    }

    Timer {
        id: videoPlayerTimer;

        interval: 2000;
        repeat: false;
        onTriggered: {
            if (!active) return;
            if (!currentGame || !currentGame.assets) return;
            if (!currentGame.assets.video) return;
            if (settings.get(settingKey) === false) return;
            if (currentView !== validView) return;

            videoToggled(true);

            videoPlayer.source = currentGame.assets.video;
            videoPlayer.play();
            music.volumeCheck();
        }
    }

    Video {
        id: videoPlayer;

        visible: false;
        volume: 0.7;
        // starts empty: the timer below is what actually assigns a source
        // (after the hover delay), and an eager binding here would both start
        // loading art for every game you scroll past and break the moment
        // switchVideo() assigns to source imperatively
        source: '';
        autoPlay: false;
        loops: MediaPlayer.Infinite;
        width: parent.width * .75;
        height: parent.height * .75;
        anchors.centerIn: parent;
        fillMode: VideoOutput.PreserveAspectFit;
    }

    DropShadow {
        id: dropShadow;

        source: videoPlayer;
        anchors.fill: videoPlayer;
        color: theme.current.dropShadowColor;
        verticalOffset: 5;
        radius: 20;
        samples: 41;
        cached: true;
        visible: true;
    }
}
