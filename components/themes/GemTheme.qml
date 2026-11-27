import QtQuick 2.15

// The coloured themes - Sapphire, Ruby, Emerald, Amethyst, Amber and
// Aquamarine. The Dark theme, with its backgrounds, panels, text and accent
// all re-tinted from one hue (0-1 round the colour wheel) so each family hangs
// together. Diamond, the silver one, is the Light theme re-coloured instead
// (see Handler.qml).
DarkTheme {
    // 0 = red, .08 = orange, .12 = amber, .4 = green, .5 = cyan,
    // .6 = blue, .76 = purple
    property real hue: .6;
    // how colourful the dark surfaces are (0 = grey, 1 = fully saturated)
    property real saturation: .7;
    // lightness of the accent; yellows need to be brighter than blues to read
    property real accentLightness: .62;
    // how vivid the accent is. The greens and cyans glow when fully saturated
    // on these dark panels, so those two themes turn it down
    property real accentSaturation: .85;

    function tone(saturationScale, lightness) {
        return String(Qt.hsla(hue, Math.min(1, saturation * saturationScale), lightness, 1));
    }

    // surfaces
    bgColor: tone(.75, .085);
    highlightColor: tone(.7, .22);
    textInputBackgroundColor: tone(.7, .12);
    textInputBorderColor: tone(.6, .26);
    textInputPlaceholderColor: tone(.5, .3);

    // text
    titleColor: tone(.4, .86);
    focusTextColor: tone(.4, .9);
    readableTextColor: tone(.4, .86);
    blurTextColor: tone(.35, .45);
    detailsColor: tone(.3, .66);
    defaultHeaderNameColor: tone(.35, .72);
    footerCountColor: tone(.3, .42);

    // header widgets: the "light" colours sit on dark backgrounds
    batteryColorLight: tone(.4, .86);
    batteryColorDark: tone(.3, .5);
    clockColorLight: tone(.4, .86);
    clockColorDark: tone(.3, .5);
    settingsColorLight: tone(.4, .86);
    settingsColorDark: tone(.3, .5);

    defaultAccent: String(Qt.hsla(hue, accentSaturation, accentLightness, 1));
}
