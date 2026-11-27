import QtQuick 2.15
import QtQuick.Window 2.15

Item {
    property string key: 'X';
    property string title: 'Title';
    property bool square: false;
    readonly property bool isSymbol: key.indexOf('ps:') === 0;
    property double fontSize: {
        return footer.height * .24;
    }
    property double squareWidth: {
        return footer.height * .54;
    }

    height: footer.height * .4;
    width: icon.width + outerText.width + 4;

    // button background
    Rectangle {
        id: icon;

        height: parent.height;
        width: square ? squareWidth : parent.height;
        radius: square ? .2 * squareWidth : parent.height;
        color: '#444444';
        anchors.verticalCenter: parent.verticalCenter;

        // PlayStation face buttons ('ps:cross' and friends, see
        // themes/PlayStationButtons.qml) are drawn as their coloured shapes
        // rather than as text, which would depend on the system font
        Canvas {
            id: symbol;

            visible: isSymbol;
            width: parent.height * .56;
            height: width;
            // drawn at the physical pixel size, so it stays crisp on
            // high-density screens
            canvasSize: Qt.size(Math.max(1, Math.round(width * Screen.devicePixelRatio)),
                                Math.max(1, Math.round(height * Screen.devicePixelRatio)));
            renderTarget: Canvas.Image;
            anchors.centerIn: parent;

            onPaint: {
                const ctx = getContext('2d');
                const w = canvasSize.width;
                const h = canvasSize.height;
                const pad = w * .1;
                const line = w * .16;

                ctx.reset();
                ctx.clearRect(0, 0, w, h);
                ctx.lineWidth = line;
                ctx.lineJoin = 'round';
                ctx.lineCap = 'round';

                if (symbolName === 'cross') {
                    ctx.strokeStyle = '#6e9ae6';
                    ctx.beginPath();
                    ctx.moveTo(pad + line / 2, pad + line / 2);
                    ctx.lineTo(w - pad - line / 2, h - pad - line / 2);
                    ctx.moveTo(w - pad - line / 2, pad + line / 2);
                    ctx.lineTo(pad + line / 2, h - pad - line / 2);
                    ctx.stroke();
                } else if (symbolName === 'circle') {
                    ctx.strokeStyle = '#e8675e';
                    ctx.beginPath();
                    ctx.arc(w / 2, h / 2, w / 2 - pad - line / 2, 0, Math.PI * 2);
                    ctx.stroke();
                } else if (symbolName === 'square') {
                    ctx.strokeStyle = '#d98ac0';
                    ctx.beginPath();
                    ctx.rect(pad + line / 2, pad + line / 2, w - 2 * pad - line, h - 2 * pad - line);
                    ctx.stroke();
                } else if (symbolName === 'triangle') {
                    ctx.strokeStyle = '#4fc3a1';
                    ctx.beginPath();
                    ctx.moveTo(w / 2, pad + line / 2);
                    ctx.lineTo(w - pad - line / 2, h - pad - line / 2);
                    ctx.lineTo(pad + line / 2, h - pad - line / 2);
                    ctx.closePath();
                    ctx.stroke();
                }
            }

            onCanvasSizeChanged: requestPaint()
            onSymbolNameChanged: requestPaint()
            property string symbolName: isSymbol ? key.substring(3) : '';
        }

        // button inner text
        Text {
            visible: !isSymbol;
            text: key;
            color: theme.current.buttonLetterColor;

            font {
                pixelSize: fontSize;
                letterSpacing: -0.3;
                bold: true;
            }

            anchors {
                verticalCenter: parent.verticalCenter;
                horizontalCenter: parent.horizontalCenter;
            }
        }
    }

    // button outer text
    Text {
        id: outerText;

        text: title;
        color: theme.current.buttonLabelColor;

        font {
            pixelSize: fontSize;
            letterSpacing: -0.3;
            bold: true;
        }

        anchors {
            verticalCenter: parent.verticalCenter;
            left: icon.right;
            leftMargin: footer.height * .07;
        }
    }
}
