import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 1920; height: 1080; color: "#080a12"
    property int sessionIndex: sessionModel.lastIndex
    Image { id: bg; anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop }
    Rectangle { anchors.fill: parent; color: "#38070a12" }
    FastBlur { anchors.fill: card; source: bg; radius: 36; cached: true }
    Rectangle {
        id: card; width: 390; height: 460; radius: 36; anchors.centerIn: parent
        color: "#b8202534"; border.color: "#40ffffff"; border.width: 1
        opacity: 0; scale: .94
        Component.onCompleted: appear.start()
        ParallelAnimation { id: appear; NumberAnimation { target: card; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic } NumberAnimation { target: card; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutBack } }
        Column {
            anchors.centerIn: parent; width: 310; spacing: 18
            Image { source: "logo.png"; width: 104; height: 104; anchors.horizontalCenter: parent.horizontalCenter; fillMode: Image.PreserveAspectFit }
            Text { text: userModel.lastUser || "FeatherOS"; color: "white"; font.family: config.font; font.pixelSize: 22; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            TextField {
                id: password; width: parent.width; height: 54; echoMode: TextInput.Password; placeholderText: "Password"; color: "white"; font.pixelSize: 16
                background: Rectangle { radius: 17; color: "#38ffffff"; border.color: password.activeFocus ? "#788cff" : "#30ffffff"; border.width: 1 }
                Keys.onReturnPressed: sddm.login(userModel.lastUser, password.text, root.sessionIndex)
            }
            Button {
                width: parent.width; height: 52; text: "Sign in"
                onClicked: sddm.login(userModel.lastUser, password.text, root.sessionIndex)
                background: Rectangle { radius: 17; color: parent.down ? "#6477e8" : "#7185ff" }
                contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 16; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Text { id: error; text: ""; color: "#ff8596"; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 30; spacing: 12
        Button { text: "Restart"; onClicked: sddm.reboot() }
        Button { text: "Shut Down"; onClicked: sddm.powerOff() }
    }
    Connections { target: sddm; function onLoginFailed() { error.text = "Incorrect password"; password.selectAll(); password.forceActiveFocus() } }
}

