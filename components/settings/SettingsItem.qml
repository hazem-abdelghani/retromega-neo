import QtQuick 2.15

Item {
    // the settings key this row represents; empty when this delegate slot
    // is currently showing a section header instead (see SettingsScroll)
    property string settingKey: '';

    property bool isSelect: settingKey !== '' && settings.type(settingKey) === 'select';

    // false when this setting has no effect in the current Display Mode (e.g.
    // Cards Size outside Grid/Gallery). The row still renders and can still be
    // highlighted - it's just dimmed and inert, which keeps the list a fixed
    // shape instead of rows appearing and disappearing under the selection.
    property bool rowEnabled: true;

    // tracked as a real QML property (rather than re-reading settings.get()
    // inline in a binding) so both the value AND theme/light-dark changes
    // keep this row's indicator reactive
    property var currentValue: settingKey !== '' ? settings.get(settingKey) : null;

    function onSettingChanged(value) {
        currentValue = value;
    }

    // The key this row registered its callback under, captured at registration
    // time. Unregistering read "settingKey" back instead, which is only the
    // same string as long as nothing reassigns it - fine while this list
    // rebuilds its delegates from scratch, but it would leak a callback under
    // the old key (and leave the row permanently stale under the new one) the
    // moment delegate reuse was switched on.
    property string registeredKey: '';

    Component.onCompleted: {
        if (settingKey === '') return;

        registeredKey = settingKey;
        settings.addCallback(registeredKey, onSettingChanged);
    }

    Component.onDestruction: {
        if (registeredKey === '') return;

        settings.removeCallback(registeredKey, onSettingChanged);
    }

    MouseArea {
        anchors.fill: parent;
        enabled: settingKey !== '';
        onClicked: {
            let muteSound = false;

            if (settingsListView.currentIndex !== index) {
                settingsListView.currentIndex = index;
                sounds.nav();
                muteSound = true;
            }

            // tapping a dimmed row still moves the selection onto it (so it
            // behaves like every other row), it just doesn't change anything
            if (!rowEnabled) return;

            onAcceptPressed(muteSound);
        }
    }

    // title sits on the left, flush with the row (Flat Ozone-style list item)
    Text {
        id: settingTitle;

        text: settingKey !== '' ? settings.title(settingKey) : '';
        verticalAlignment: Text.AlignVCenter;
        color: (active && settingsListView.currentIndex === index)
            ? theme.current.focusTextColor
            : theme.current.blurTextColor;
        height: parent.height;
        opacity: rowEnabled ? 1.0 : 0.35;

        Behavior on opacity { NumberAnimation { duration: 150; } }

        font {
            pixelSize: parent.height * .43;
            letterSpacing: -0.3;
            bold: true;
        }

        anchors {
            left: parent.left;
            leftMargin: 20;
            right: valueColumn.left;
            rightMargin: 20;
        }
    }

    // shared right-hand indicator column: either an on/off glyph (toggle
    // rows) or the current value's label (select rows, e.g. Font Size,
    // Display Mode), acting like a compact segmented control you tap/press
    // to cycle. Wide enough to fit the longest label ("Sidebar", "Gallery",
    // "Medium") without eliding.
    Item {
        id: valueColumn;

        width: parent.height * 3.2;
        height: parent.height;
        opacity: rowEnabled ? 1.0 : 0.35;

        Behavior on opacity { NumberAnimation { duration: 150; } }

        anchors {
            right: parent.right;
            rightMargin: 20;
        }

        // on/off indicator, reusing this theme's existing icon font.
        // Note: there is no dedicated on/off image asset under assets/images/icons -
        // that folder only holds the per-platform collection logos (nes.png,
        // snes.png, etc) - so the enabled/disabled glyphs already used elsewhere
        // in this theme (favorites, sorting) are reused here instead, colored
        // with the theme's accent color when on, similar to Flat Ozone's toggle look.
        Text {
            visible: !isSelect;
            text: currentValue ? glyphs.enabled : glyphs.disabled;
            verticalAlignment: Text.AlignVCenter;
            horizontalAlignment: Text.AlignRight;
            color: currentValue ? theme.current.accentColor : theme.current.blurTextColor;
            anchors.fill: parent;

            font {
                family: glyphs.name;
                pixelSize: parent.height * .4;
            }
        }

        // current option's label for select rows (e.g. "Normal", "Medium",
        // "Small") - tapping/pressing the row cycles to the next option.
        // Built from the reactive "currentValue" property above rather than
        // calling settings.optionLabel(modelData) directly in this binding -
        // that re-reads the settings store's plain values object, which
        // doesn't notify QML of changes and would leave this label frozen
        // on whatever it showed at first render.
        Text {
            visible: isSelect;
            text: {
                if (settingKey === '') return '';
                const labels = settings.optionLabels[settingKey];
                if (labels === undefined || labels[currentValue] === undefined) return currentValue;
                return labels[currentValue];
            }
            elide: Text.ElideRight;
            verticalAlignment: Text.AlignVCenter;
            horizontalAlignment: Text.AlignRight;
            color: theme.current.accentColor;
            anchors.fill: parent;

            font {
                pixelSize: parent.height * .34;
                letterSpacing: -0.3;
                bold: true;
            }
        }
    }

    // thin separator between rows, matching Flat Ozone's flat divider list;
    // suppressed on the last row and right before the next section header
    // (the header's own spacing/heading already separates the groups)
    Rectangle {
        // rowModel[index + 1] is checked for existence, not just read: when the
        // model shrinks (the Reorder section disappearing, say) a delegate can
        // briefly still be holding an index past the end of the new array, and
        // reading .isHeader off undefined threw
        visible: settingKey !== ''
            && index < rowModel.length - 1
            && rowModel[index + 1] !== undefined
            && !rowModel[index + 1].isHeader;
        color: theme.current.dividerColor;
        height: 1;
        opacity: 0.7;

        anchors {
            left: parent.left;
            right: parent.right;
            leftMargin: 20;
            rightMargin: 20;
            bottom: parent.bottom;
        }
    }
}
