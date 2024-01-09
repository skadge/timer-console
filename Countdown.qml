import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 5.15

Rectangle {

    anchors.top: parent.top
    anchors.topMargin: 10
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10

    property string name

    color: "lightgrey"

    property bool isActive: false
    property double timeLeft: 60*60

    Text {
        id: name_label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10

        text:parent.name
        color: parent.isActive ? "red": "black"
        font.pixelSize: 40
    }

    Text {
        id: counter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: name_label.bottom
        anchors.topMargin: 10

        property int hours: Math.floor(Math.abs(parent.timeLeft / 3600))
        property int minutes: Math.floor((Math.abs(parent.timeLeft) - hours * 3600) / 60)
        property int seconds: Math.abs(parent.timeLeft % 60)

        text: (parent.timeLeft < 0 ? "-":"") + hours + ":" + String(minutes).padStart(2,"0") + ":" + String(seconds).padStart(2,"0")
        color: parent.timeLeft > 0 ? "black" : "red"
        font.pixelSize: 40
    }

    Text {
        id: timeout_label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: counter.bottom
        anchors.topMargin: 10
        text: parent.timeLeft < 0 ? "time out!":""
        color: "red"
        font.pixelSize: 30
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeout_label.bottom
        anchors.topMargin: 40

        text: parent.isActive ? "Stop":"Start"
        font.pixelSize: 30
        onPressed: {
            parent.isActive = !parent.isActive;
        }
    }

    SoundEffect {
            id: timeoutSound
            source: "res/bell.wav"
        }

    Timer {
        id: timer
        interval: 1000
        running: parent.isActive
        repeat: true
        onTriggered: {

            parent.timeLeft -= 1;
            if (parent.timeLeft == 0) {
                timeoutSound.play();
            }
      }
    }

function reset(time) {
    console.log("Resetting time for " + name + " to " + time + "s");
    if (timeLeft < 0) {
        // if we were previously overtime, substract this time from the new allowance
        timeLeft = time + timeLeft;
    }
    else {
        timeLeft = time;
    }
}
}
