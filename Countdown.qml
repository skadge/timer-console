import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 5.15

Rectangle {

    anchors.top: parent.top
    anchors.topMargin: 10
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10

    property string name

    color: "white"

    property bool isActive: false
    property double timeLeft: 60*60

    AnimatedImage {
        id: hourglass
        anchors.horizontalCenter: parent.horizontalCenter
        width: 100
        height: 100
        source: "res/hourglass.gif"
        playing: parent.isActive
        onPlayingChanged: {
            if (!playing) {
                currentFrame = 0;
            }
        }
    }

    Text {
        id: name_label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: hourglass.bottom
        anchors.topMargin: 10

        text:parent.name
        font.family: myFont.name
        color: parent.isActive ? "green": "black"
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
        font.family: myFont.name
        color: parent.timeLeft > 0 ? "black" : "red"
        font.pixelSize: 40
    }

    Text {
        id: timeout_label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: counter.bottom
        anchors.topMargin: 10
        text: parent.timeLeft < 0 ? "time out!":""
        font.family: myFont.name
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

    FontLoader {
        id: myFont
        //source: "res/AH_PUNCH.otf"
        source: "res/BerlinSansFB.ttf"
    }


function reset(fulltime) {
    console.log("Resetting time for " + name + " to " + fulltime + "s");
    //if (timeLeft < 0) {
    //    // if we were previously overtime, substract this time from the new allowance
    //    timeLeft = fulltime + timeLeft;
    //}
    //else {
    //    timeLeft = fulltime;
    //}

    // if overtime the previous day, the overtime is deduced from the available time for this day
    // if time left from previous day, time is added up to a maximum of  2 times the daily time allowance
    timeLeft = Math.min(fulltime + timeLeft, fulltime * 2);
}
}
