import QtQuick 2.15
Rectangle {
    width: 800; height: 500; color: "#0b0e17"
    Column { anchors.centerIn: parent; spacing: 24
        Image { source: "logo.png"; width: 128; height: 128; anchors.horizontalCenter: parent.horizontalCenter; fillMode: Image.PreserveAspectFit }
        Text { text: "Installing FeatherOS"; color: "white"; font.pixelSize: 30; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        Text { text: "A calm, fast Plasma desktop — made to feel light."; color: "#bbc3dc"; font.pixelSize: 17; anchors.horizontalCenter: parent.horizontalCenter }
    }
}

