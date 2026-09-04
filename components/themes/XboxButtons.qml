import QtQuick 2.15

// Printed letters for an Xbox-style pad, keyed by action - see
// SwitchButtons.qml for why "details"/"filters" differ between the two.
Item {
    property string nextPage: 'RB';
    property string pageDown: 'RT';
    property string prevPage: 'LB';
    property string pageUp: 'LT';
    property string details: 'X';
    property string cancel: 'B';
    property string filters: 'Y';
    property string accept: 'A';
}
