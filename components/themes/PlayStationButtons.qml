import QtQuick 2.15

// Button guide for a PlayStation-style pad. The pad sits in the same
// physical spots as an Xbox one (Cross where A is, Circle where B is, Square
// where X is, Triangle where Y is) and fires the same key events, so
// theme.xboxMode stays true for this layout - only what's printed differs.
//
// The face buttons are keyed 'ps:cross' / 'ps:circle' / 'ps:square' /
// 'ps:triangle' rather than a letter: ButtonLegend.qml draws those as the
// coloured shapes, because a text glyph for them depends on the system font.
// The bumpers and triggers are plain text.
Item {
    property string nextPage: 'R1';
    property string pageDown: 'R2';
    property string prevPage: 'L1';
    property string pageUp: 'L2';
    property string details: 'ps:square';
    property string cancel: 'ps:circle';
    property string filters: 'ps:triangle';
    property string accept: 'ps:cross';
}
