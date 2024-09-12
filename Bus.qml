import QtQuick 2.15
import QtQuick.Controls 2.15

import "tmb_api.js" as TMB

Rectangle {

    property string name: "X0"
    property string stopCode: "0000"
    property int updateInterval: 10 // sec
    width: 50
    height: width
    radius: width/2
    color: black

    Label {
        id: lineName
        anchors.centerIn: parent
        text: name
        color: "white"
        font.bold: true
    }

    Label {
        id: etaLabel
        anchors.verticalCenter: lineName.verticalCenter
        anchors.left: lineName.right
        anchors.leftMargin: 20
        text: "N/A"
        color: "black"
    }

    Timer {
        id: bus_updater
        interval: parent.updateInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            console.log("Updating next " + parent.name + " bus time...");

            TMB.getNextBus(parent.stopCode, parent.name,function(response) {

                if (response.length === 0) {
                    console.log(parent.name + ": no bus scheduled");
                    etaLabel.text = "no service";
                    return;
                }

                const result = response.map(item => item["text-ca"]).join(" / ");
                console.log(parent.name + ": " + result);
                etaLabel.text = result;
            });

        }
    }
}
