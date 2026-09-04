import QtQuick 2.15

Item {
    id: batteryRoot;

    property string shade: 'light';
    property string shadeColor: {
        return shade === 'light'
            ? theme.current.batteryColorLight
            : theme.current.batteryColorDark;
    }

    // 0.0 - 1.0, or NaN on devices without a battery (the header already
    // hides this whole item in that case)
    readonly property real level: api.device.batteryPercent;

    // Pegasus doesn't expose this on every platform; "=== true" makes an
    // absent property behave exactly like the old unconditional rendering
    readonly property bool charging: api.device.batteryCharging === true;

    readonly property bool low: !charging && !isNaN(level) && level <= 0.15;

    // true whenever the fill is carrying a warning color rather than just
    // matching the header's shade
    readonly property bool highlighted: charging || low;

    // The header's other widgets (clock, settings icon) sit at half opacity,
    // and this widget used to be dimmed to match as a whole - which washed the
    // red and green out to a pale pink and mint. The outline and terminal keep
    // that muted look below, while the fill goes to full strength as soon as it
    // has something to say.
    readonly property real idleOpacity: 0.5;

    // the fill is the only part that changes color - the outline stays in
    // the header's shade so the widget keeps its shape against both themes
    readonly property color fillColor: {
        if (charging) return '#2fbf51';
        if (low) return '#f0342f';
        return shadeColor;
    }

    // driven by the animation below rather than the fill's own opacity, so the
    // fill keeps its declarative binding - an "animation on opacity" would take
    // the property over outright and leave it wherever it stopped
    property real chargePulse: 1.0;

    // slow pulse while charging, so a glance tells you it's plugged in even at
    // a battery level that isn't visibly moving. Bottoms out well short of
    // transparent so the green never looks washed out on the way down.
    SequentialAnimation {
        running: batteryRoot.charging;
        loops: Animation.Infinite;
        alwaysRunToEnd: true;

        NumberAnimation {
            target: batteryRoot;
            property: 'chargePulse';
            to: 0.6;
            duration: 900;
            easing.type: Easing.InOutQuad;
        }

        NumberAnimation {
            target: batteryRoot;
            property: 'chargePulse';
            to: 1.0;
            duration: 900;
            easing.type: Easing.InOutQuad;
        }

        onRunningChanged: {
            if (!running) batteryRoot.chargePulse = 1.0;
        }
    }

    // border
    Rectangle {
        id: batteryBorder;

        height: parent.height;
        width: parent.width;
        radius: 3;
        color: 'transparent';
        opacity: batteryRoot.idleOpacity;

        border {
            color: shadeColor;
            width: 2;
        }
    }

    // fill level
    Rectangle {
        id: batteryFill;

        color: fillColor;
        opacity: {
            if (charging) return chargePulse;
            if (low) return 1.0;
            return batteryRoot.idleOpacity;
        }

        width: Math.max((isNaN(level) ? 0 : level) * (parent.width - 6), 2);
        height: parent.height - 6;
        radius: 1;

        anchors {
            left: parent.left;
            leftMargin: 3;
            top: parent.top;
            topMargin: 3;
        }

        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad; }
        }

        Behavior on color {
            ColorAnimation { duration: 400; }
        }
    }

    // button
    Rectangle {
        height: parent.height * .42;
        width: parent.height * .14;
        radius: width;
        color: shadeColor;
        opacity: batteryRoot.idleOpacity;

        anchors {
            verticalCenter: parent.verticalCenter;
            left: parent.right;
            leftMargin: 1;
        }
    }
}
