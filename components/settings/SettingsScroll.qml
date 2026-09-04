import QtQuick 2.15

Item {
    property alias settingsListView: settingsListView;
    // kept for SettingsItem/PlatformItem's highlight checks; there's no
    // sidebar to steal focus anymore, so this list is always the focused one
    property bool active: true;
    property double itemHeight: {
        return settingsListView.height * .115 * theme.fontScale;
    }
    // section header rows are shorter than a regular setting row
    property double headerHeight: itemHeight * .62;

    // Read as a plain count, deliberately NOT as collectionOrder itself:
    // reordering reassigns collectionOrder but never changes its length, so
    // this doesn't notify and rowModel below isn't rebuilt behind the panel.
    property int platformCount: collectionOrder.length;

    // tracked as a real property so each row's grayed-out state re-evaluates
    // when the Display Mode changes - settings.isRelevant() reads
    // settings.get(), which doesn't notify on its own (see theme.qml's note).
    // Deliberately NOT referenced by rowModel below: rows that don't apply are
    // dimmed rather than removed, so the list's shape stays fixed and the
    // selection can't be knocked off a row that shifted underneath it.
    property string displayMode: settings.get('displayMode');
    function displayModeCallback(value) { displayMode = value; }

    Component.onDestruction: {
        settings.removeCallback('displayMode', displayModeCallback);
    }

    // flattened list mixing non-interactive section-header rows in with the
    // actual setting rows, built from settings.keys/settings.sections so
    // related settings are visually grouped under a title, then the platform
    // reorder rows appended under their own "Reorder" header. Each entry is
    // { isHeader: true, title }, { isLink: true, title } for the Platforms
    // row, or { key } for a plain setting row.
    property var rowModel: {
        let result = [];

        for (const key of settings.keys) {
            const title = settings.sectionTitle(key);
            if (title !== undefined) {
                result.push({ isHeader: true, isLink: false, title: title });
            }
            result.push({ isHeader: false, isLink: false, key: key });
        }

        // the Platforms tab used to live behind a sidebar; it's now a single
        // row at the end of this list that slides PlatformsPane.qml in from
        // the right. Skipped entirely when there's nothing to reorder, so we
        // never show an empty heading.
        if (platformCount > 0) {
            result.push({ isHeader: true, isLink: false, title: 'Reorder' });
            result.push({ isHeader: false, isLink: true, title: 'Platforms' });
        }

        return result;
    }

    // moves currentIndex by the given step (+1/-1), skipping over any
    // header rows so keyboard/gamepad navigation always lands on a real
    // setting or platform rather than a section title
    function moveCurrentIndex(step) {
        let candidate = settingsListView.currentIndex;

        do {
            candidate += step;
            if (candidate < 0 || candidate > rowModel.length - 1) return; // hit an edge, stay put
        } while (rowModel[candidate].isHeader);

        settingsListView.currentIndex = candidate;
    }

    // Identifies each selectable row independently of its position, so a
    // rebuild of rowModel can put the selection back on the same row even if
    // rows above it have changed.
    function rowKey(row) {
        if (row === undefined || row.isHeader) return '';
        return row.isLink ? '#platforms' : row.key;
    }

    // the row the user is actually sitting on. Deliberately only updated for
    // real (non-header, in-range) rows: rowModel is a plain JS array, so
    // replacing it makes the ListView drop its own currentIndex, and that
    // reset must not be allowed to overwrite what we're trying to restore.
    property string currentKey: '';

    Connections {
        target: settingsListView;
        function onCurrentIndexChanged() {
            const key = rowKey(rowModel[settingsListView.currentIndex]);
            if (key === '') return;

            currentKey = key;
        }
    }

    // rowModel is a plain JS array, so replacing it makes the ListView drop
    // its own currentIndex - and the row it resets to is row 0, the
    // "Appearance" header, which the highlight hides itself on, so the
    // selection looks like it vanished. Restoring has to happen *after* the
    // view has taken the new model, hence the 0ms hop: doing it straight from
    // onRowModelChanged runs before the reset and gets overwritten by it.
    onRowModelChanged: rowRestoreTimer.restart();

    Timer {
        id: rowRestoreTimer;

        interval: 0;
        repeat: false;
        onTriggered: restoreCurrentRow();
    }

    function restoreCurrentRow() {
        if (rowModel.length === 0) return;

        let index = -1;

        for (let i = 0; i < rowModel.length; i++) {
            if (rowKey(rowModel[i]) === currentKey) {
                index = i;
                break;
            }
        }

        // the row the user was on no longer exists; fall back to the nearest
        // selectable row instead
        if (index === -1) {
            index = settingsListView.currentIndex;
            if (index < 0 || index > rowModel.length - 1) index = rowModel.length - 1;

            while (index > 0 && rowModel[index].isHeader) index--;
            while (index < rowModel.length - 1 && rowModel[index].isHeader) index++;
        }

        settingsListView.currentIndex = index;
        settingsListView.positionViewAtIndex(index, ListView.Contain);
    }

    Component.onCompleted: {
        settings.addCallback('displayMode', displayModeCallback);

        // start on the first real (non-header) row
        let firstIndex = 0;
        while (firstIndex < rowModel.length && rowModel[firstIndex].isHeader) firstIndex++;

        settingsListView.currentIndex = firstIndex;
        currentKey = rowKey(rowModel[firstIndex]);
        settingsListView.positionViewAtIndex(firstIndex, ListView.Center);
    }

    ListView {
        id: settingsListView;

        model: rowModel;
        delegate: lvSettingsDelegate;
        width: parent.width - 40; // minus the margins
        height: parent.height - 24;
        clip: true;
        highlightMoveDuration: 0;
        preferredHighlightBegin: itemHeight - 12; // height of an item minus top margin
        preferredHighlightEnd: height - (itemHeight + 12); // height of an item plus bottom margin
        // "height", not "parent.height": this range is measured inside the
        // view's own viewport, which is 24px shorter than the parent Item
        // (12px top + 12px bottom margin), so the parent's height pushed the
        // range 24px past the bottom edge
        highlightRangeMode: ListView.ApplyRange;

        anchors {
            left: parent.left;
            leftMargin: 20;
            top: parent.top;
            topMargin: 12;
            bottom: parent.bottom;
            bottomMargin: 12;
            right: parent.right;
            rightMargin: 20;
        }

        // flat, edge-to-edge selection bar (Flat Ozone style); hidden while
        // resting on a (non-selectable) section header row
        highlight: Rectangle {
            visible: active
                && settingsListView.currentIndex >= 0
                && settingsListView.currentIndex < rowModel.length
                && !rowModel[settingsListView.currentIndex].isHeader;
            color: theme.current.highlightColor;
            radius: 0;
            width: settingsListView.width;

            Rectangle {
                // accent-colored indicator on the focused row's leading edge
                width: 4;
                color: theme.current.accentColor;
                anchors {
                    left: parent.left;
                    top: parent.top;
                    bottom: parent.bottom;
                }
            }
        }
    }

    Component {
        id: lvSettingsDelegate;

        Item {
            width: settingsListView.width;
            height: modelData.isHeader ? headerHeight : itemHeight;

            // Every row used to build all three of these and hide two, so a
            // 30-row list carried 90 row items - and each hidden SettingsItem
            // still registered a settings callback and built its own four text
            // items. One Loader picks the right one instead.
            //
            // The three Components are declared in here rather than alongside
            // lvSettingsDelegate so their creation context is this delegate's:
            // the rows read "modelData" and "index" straight out of the model,
            // and hoisting them to the file's root scope would put both out of
            // reach.
            Loader {
                anchors.fill: parent;

                sourceComponent: {
                    // modelData can be momentarily absent while the view is
                    // swapping models out from under its delegates
                    if (!modelData) return null;
                    if (modelData.isHeader) return sectionHeaderRow;
                    if (modelData.isLink) return linkRow;
                    return settingRow;
                }
            }

            Component {
                id: sectionHeaderRow;

                SettingsSectionHeader { title: modelData.title; }
            }

            Component {
                id: linkRow;

                SettingsLinkItem { title: modelData.title; }
            }

            Component {
                id: settingRow;

                SettingsItem {
                    settingKey: modelData.key;
                    // displayMode and showAllGamesSetting are passed through
                    // isRelevant() rather than read inside it, so this binding
                    // actually re-evaluates when they change and the row
                    // dims/undims live
                    rowEnabled: settings.isRelevant(modelData.key, displayMode, showAllGamesSetting);
                }
            }
        }
    }
}
