import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.settings 1.0

ApplicationWindow {
    id: window
    width: 800
    height: 480
    visibility: "FullScreen"
    visible: true
    title: qsTr("Timer console")

    property string day: new Date().toLocaleDateString(Qt.locale("fr_FR"),"dddd")

    property var timeAllowances: {
        "lundi": {"maud":30*60, "zoe": 30*60, "elouan": 30*60},
        "mardi": {"maud":30*60, "zoe": 30*60, "elouan": 30*60},
        "mercredi": {"maud":30*60, "zoe": 30*60, "elouan": 30*60},
        "jeudi": {"maud":30*60, "zoe": 30*60, "elouan": 30*60},
        "vendredi": {"maud":30*60, "zoe": 30*60, "elouan": 30*60},
        "samedi": {"maud":90*60, "zoe": 90*60, "elouan": 90*60},
        "dimanche": {"maud":90*60, "zoe": 90*60, "elouan": 90*60},
    }

    property var buses: [
        {"name": "H2", "stop":"3639", "color": Qt.rgba(0.10,0.40,0.90,1)}, // H2 to circus
        {"name": "V23", "stop":"824", "color": Qt.rgba(0.10,0.90,0.30,1)}, // V23 to Mas Casanovas
        {"name": "117", "stop":"824", "color": Qt.rgba(0.90,0.40,0.40,1)}, // 117 to Goya
        {"name": "V25", "stop":"649", "color": Qt.rgba(0.10,0.90,0.30,1)}, // V25 towards center
        {"name": "19", "stop":"649", "color": Qt.rgba(0.90,0.40,0.40,1)}, // 19 towards center
    ]

    function set_times() {
        c_maud.reset(timeAllowances[day]["maud"]);
        c_zoe.reset(timeAllowances[day]["zoe"]);
        c_elouan.reset(timeAllowances[day]["elouan"]);
    }

    Shortcut {
        sequences: [StandardKey.Refresh]
        onActivated: {
            set_times();
        }
    }

    Shortcut {
        sequences: [StandardKey.Copy]
        onActivated: {
            console.log("Switching to " + day);
            day = Object.keys(timeAllowances)[(Object.keys(timeAllowances).indexOf(day) + 1) % Object.keys(timeAllowances).length];
        }
    }

    onDayChanged: {
        console.log("Current day is now: " + day);
        set_times();
    }

    Settings {
        id: settings
        property alias day: window.day

        property alias maud: c_maud.timeLeft
        property alias zoe: c_zoe.timeLeft
        property alias elouan: c_elouan.timeLeft
    }

    Rectangle {
        id: date_label
        width: parent.width
        height: parent.height/6
        color: "grey"

        FontLoader {
            id: myFont
            //source: "res/AH_PUNCH.otf"
            source: "res/BerlinSansFB.ttf"
        }

        Text {
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: window.day
            color: "lightgrey"
            font.pixelSize: 60
            font.family: myFont.name

        }
    }

    Item {
        id: timers
        width: parent.width
        anchors.top: date_label.bottom
        anchors.topMargin: 20
        anchors.bottom: bus_schedule.top
        anchors.bottomMargin: 20

        Countdown {
            id: c_maud
            name: "Maud"
            anchors.left: parent.left
            anchors.leftMargin: parent.width/16
            width: parent.width/4
        }
        Countdown {
            id: c_zoe
            anchors.left: c_maud.right
            anchors.leftMargin: parent.width/16
            name: "Zoé"
            width: parent.width/4
        }
        Countdown {
            id: c_elouan
            anchors.left: c_zoe.right
            anchors.leftMargin: parent.width/16
            name: "Élouan"
            width: parent.width/4
        }
    }

    Rectangle {
        id: bus_schedule
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height / 8
        color: "transparent"

        Row {
            id: busUpdatersRow
            anchors.fill: parent
            spacing: 85

            function createBusUpdaters() {
                let component = Qt.createComponent("Bus.qml");

                for (let idx in buses) {
                    let busUpdater = component.createObject(busUpdatersRow, {
                                                                name: buses[idx]["name"],
                                                                stopCode: buses[idx]["stop"],
                                                                color: buses[idx]["color"]
                                                            });

                    if (busUpdater == null) {
                        // Error Handling
                        console.log("Error creating bus updater for " + name);
                    }
                }
            }

            Component.onCompleted: createBusUpdaters();
        }
    }

    Timer {
        id: day_updater
        interval: 10 * 1000
        running: true
        repeat: true
        onTriggered: {

            var new_day = new Date().toLocaleDateString(Qt.locale("fr_FR"),"dddd");
            if (new_day != day) {
                day = new_day;
            }
        }
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            console.debug("applicationStateChanged: " + Qt.application.state)
            if (Qt.application.state === Qt.ApplicationActive) {
                //applicationWindow.show()
                //we're back from idle
            }
            else {
                //applicationWindow.hide()
                //going to background
            }
        }
    }
}
