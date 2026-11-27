import QtQuick 2.15

Item {
    // collection list
    property string titleColor: '#ffffff';
    property double bgOpacity: 1;

    // true for the themes with a dark background (everything but Light and
    // Diamond); used where text colour has to follow the background
    property bool isDark: false;
    // text that reads on this theme's own background colour. focusTextColor is
    // for rows with the (dark) highlight colour behind them and is white in
    // the light themes, so it can't be used on a plain background there
    property string readableTextColor: '#333333';

    // shared
    property string bgColor: '#f3f3f3';
    property string dividerColor: '#20000000';
    property string focusTextColor: '#ffffff';
    property string blurTextColor: '#333333';
    property string dropShadowColor: '#60000000';

    // details
    property string detailsColor: '#333333';

    // settings
    property string highlightColor: '#555555';
    // the theme's own accent, restored when the Accent Color setting is
    // "Default" (see Handler.qml)
    property string defaultAccent: '#2f7bdb';
    property string accentColor: defaultAccent;

    // name filter modal
    property string textInputBackgroundColor: '#dddddd';
    property string textInputBorderColor: '#bbbbbb';
    property string textInputPlaceholderColor: '#bbbbbb';

    // header
    property string defaultHeaderNameColor: '#000000';
    property string batteryColorLight: '#ffffff';
    property string batteryColorDark: '#000000';
    property string clockColorLight: '#ffffff';
    property string clockColorDark: '#000000';
    property string settingsColorLight: '#ffffff';
    property string settingsColorDark: '#000000';
    property string sortColorLight: '#80ffffff';
    property string sortColorDark: '#80000000';
    property string sortButtonColorLight: '#80000000';
    property string sortButtonColorDark: '#ffffff';

    // footer
    property string buttonLetterColor: '#ffffff';
    property string buttonLabelColor: '#80000000';
    property string footerCountColor: '#9b9b9b';
}
