import QtQuick 2.15
import QtMultimedia 5.9

Item {
    property var videos: [];

    Playlist {
        id: bgPlaylist;

        playbackMode: Playlist.Loop;

        // To add your own, drop the .mp3
        // files into assets/music and give each one a line here,
        // alongside these:
        //     PlaylistItem { source: '../../assets/music/whatever.mp3'; }
        // Removing every line leaves the playlist empty, which is a
        // supported state - the Background Music setting then just has
        // nothing to play (see the itemCount guards further down).


    }

    function volumeCheck() {
        if (settings.get('quietVideo') === true) {
            bgMusic.volume = 0.3;
            return;
        }

        for (let i = 0; i < videos.length; i++) {
            if (videos[i].playbackState === MediaPlayer.PlayingState) {
                bgMusic.volume = 0.05;
                return;
            }
        }

        bgMusic.volume = 0.3;
    }

    function registerVideo(video) {
        videos.push(video);
    }

    // volumeCheck() walks this list on every video start and stop, so a player
    // that's gone needs to come back out of it rather than being left behind
    function unregisterVideo(video) {
        const index = videos.indexOf(video);
        if (index !== -1) {
            videos.splice(index, 1);
        }
    }

    property bool isPlaying: {
        return bgMusic.playbackState === Audio.PlayingState;
    }

    Component.onCompleted: {
        bgMusicTimer.start();

        settings.addCallback('bgMusic', function (enabled) {
            // an empty playlist is a valid state (see the note above the
            // PlaylistItems), so don't spin the player up over one
            if (enabled && bgPlaylist.itemCount > 0) {
                bgPlaylist.shuffle();
                bgMusic.play();
            } else {
                bgMusic.stop();
            }
        });
    }

    Connections {
        target: Qt.application;
        function onStateChanged() {
            if (settings.get('bgMusic') === false) return;
            if (bgPlaylist.itemCount === 0) return;

            if (Qt.application.state === Qt.ApplicationActive) {
                if (!isPlaying) bgMusic.play();
            } else {
                if (isPlaying) bgMusic.pause();
            }
        }
    }

    Audio {
        id: bgMusic;

        volume: 0.3;
        playlist: bgPlaylist;

        Behavior on volume {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad; }
        }
    }

    Timer {
        id: bgMusicTimer;

        interval: 300;
        repeat: false;
        onTriggered: {
            if (bgPlaylist.itemCount > 0 && settings.get('bgMusic')) {
                bgPlaylist.shuffle();
                bgMusic.play();
            }
        }
    }
}
