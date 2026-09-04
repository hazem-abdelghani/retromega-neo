import QtQuick 2.15

// Printed letters for a Nintendo-style pad. These are keyed by *action*
// (the api.keys.isX() the footer entry triggers), not by position, so a
// footer can print the right letter just by asking for the action it fires.
//
// "details" and "filters" print the SAME letters as XboxButtons.qml
// (X and Y respectively) even though those letters sit in different physical
// spots on a Nintendo-style pad (X top, Y left) versus an Xbox pad (X left,
// Y top). api.keys.isDetails()/isFilters() fire off the button's printed
// letter, not its physical position, on both pad types - confirmed on real
// Switch-style hardware, where the physically-top button (printed X) fires
// isDetails(), not isFilters(). Printing a different letter here would be
// wrong, not just cosmetically different, so this file only renames the
// bumpers/triggers (RB/LB/RT/LT -> R/L/ZR/ZL), which really are just
// different printed names for the same physical buttons on both pad types.
Item {
    property string nextPage: 'R';
    property string pageDown: 'ZR';
    property string prevPage: 'L';
    property string pageUp: 'ZL';
    property string details: 'X';
    property string cancel: 'B';
    property string filters: 'Y';
    property string accept: 'A';
}
