import QtQuick 2.15

Item {
    id: clockRoot;

    property string shade: 'light';
    property string shadeColor: {
        return shade === 'light'
            ? theme.current.clockColorLight
            : theme.current.clockColorDark;
    }

    width: clockColumn.width;

    // named rather than passed inline, so it can be handed back to
    // removeCallback() below - matches every other component here
    function twentyFourHourCallback() { clockTimer.restart(); }

    Component.onCompleted: {
        clockTimer.start();
        settings.addCallback('twentyFourHour', twentyFourHourCallback);
    }

    Component.onDestruction: {
        settings.removeCallback('twentyFourHour', twentyFourHourCallback);
    }

    // Re-aligns itself to the next minute boundary after every tick rather
    // than free-running on a fixed 30s period. The old timer could show a
    // time up to 30 seconds stale (and drifted further with each restart);
    // this updates the moment the minute actually changes, while still
    // waking the device only once a minute instead of once a second.
    Timer {
        id: clockTimer;

        interval: 1000;
        repeat: true;
        triggeredOnStart: true;

        onTriggered: {
            const now = new Date();

            let format = 'hh:mm';

            if (!settings.get('twentyFourHour')) {
                format = 'h:mm AP';
            }

            clockText.text = Qt.formatTime(now, format);
            // day/month/year order regardless of the twentyFourHour setting
            // above, which only governs the time
            dateText.text = Qt.formatDate(now, 'dd/MM/yyyy');

            // assigning interval restarts the timer, which is what re-aligns
            // it; the small offset keeps us just past the boundary rather
            // than racing it
            interval = ((59 - now.getSeconds()) * 1000) + (1000 - now.getMilliseconds()) + 200;
        }
    }

    // Column rather than the single centered Text this used to be, so the
    // date can sit under the time - both centered as a pair, which pushes
    // the time up slightly from where it used to sit alone.
    Column {
        id: clockColumn;

        spacing: clockRoot.height * .03;
        anchors.verticalCenter: clockRoot.verticalCenter;

        Text {
            id: clockText;

            text: '00:00';
            color: clockRoot.shadeColor;
            anchors.horizontalCenter: parent.horizontalCenter;

            font {
                pixelSize: clockRoot.height * .33;
                letterSpacing: -0.3;
                bold: true;
            }

            MouseArea {
                anchors.fill: parent;
                onClicked: {
                    settings.toggle('twentyFourHour');
                }
            }
        }

        Text {
            id: dateText;

            text: '00/00/0000';
            color: clockRoot.shadeColor;
            anchors.horizontalCenter: parent.horizontalCenter;

            font {
                pixelSize: clockRoot.height * .16;
                letterSpacing: -0.2;
            }
        }
    }
}
