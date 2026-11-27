import QtQuick 2.15

// True black for OLED screens: the Dark theme with a pure #000000 background
// (so unlit pixels stay off) and correspondingly darker panels.

Item {
    // collection list
    property string titleColor: '#cccccc';
    property double bgOpacity: 0.7;

    // true for the themes with a dark background (everything but Light and
    // Diamond); used where text colour has to follow the background
    property bool isDark: true;
    // text that reads on this theme's own background colour. focusTextColor is
    // for rows with the (dark) highlight colour behind them and is white in
    // the light themes, so it can't be used on a plain background there
    property string readableTextColor: '#cccccc';

    // shared
    property string bgColor: '#000000';
    property string dividerColor: '#20ffffff';
    property string focusTextColor: '#cccccc';
    property string blurTextColor: '#555555';
    property string dropShadowColor: '#a0000000';

    // details
    property string detailsColor: '#999999';

    // settings
    property string highlightColor: '#1f1f1f';
    // the theme's own accent, restored when the Accent Color setting is
    // "Default" (see Handler.qml)
    property string defaultAccent: '#5b9bf0';
    property string accentColor: defaultAccent;

    // name filter modal
    property string textInputBackgroundColor: '#101010';
    property string textInputBorderColor: '#333333';
    property string textInputPlaceholderColor: '#444444';

    // header
    property string defaultHeaderNameColor: '#aaaaaa';
    property string batteryColorLight: '#cccccc';
    property string batteryColorDark: '#777777';
    property string clockColorLight: '#cccccc';
    property string clockColorDark: '#777777';
    property string settingsColorLight: '#cccccc';
    property string settingsColorDark: '#777777';
    property string sortColorLight: '#80cccccc';
    property string sortColorDark: '#80777777';
    property string sortButtonColorLight: '#80000000';
    property string sortButtonColorDark: '#cccccc';

    // footer
    property string buttonLetterColor: '#000000';
    property string buttonLabelColor: '#80ffffff';
    property string footerCountColor: '#646464';
}
