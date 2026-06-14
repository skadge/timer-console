import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: radioPage

    // Web radio stations. Stream URLs are plain HTTP(S) streams that MPD can
    // play directly; edit/extend this list as needed.
    property var stations: [
        {"name": "France Inter",   "url": "https://icecast.radiofrance.fr/franceinter-midfi.mp3", "color": "#e2001a"},
        {"name": "France Info",    "url": "https://icecast.radiofrance.fr/franceinfo-midfi.mp3",  "color": "#cc1f2e"},
        {"name": "Radio Paradise", "url": "https://stream.radioparadise.com/mp3-192",             "color": "#3a6ea5"},
        {"name": "BBC Radio 1",    "url": "http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one",   "color": "#d4145a"},
    ]

    // Mirror the station list into MPD stored playlists so other clients
    // (myMPD, mpc, ...) can start the same stations.
    Component.onCompleted: mpd.setStations(radioPage.stations)

    Rectangle {
        anchors.fill: parent
        color: "#141414"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // ---- Cover art + metadata (centre/left) ---------------------- //
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Item {
                id: coverArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                property real side: Math.min(coverArea.width, coverArea.height)

                Rectangle {
                    id: coverPlaceholder
                    anchors.centerIn: parent
                    width: coverArea.side
                    height: coverArea.side
                    radius: 10
                    color: "#262626"
                    border.color: "#3a3a3a"
                    border.width: 1
                    visible: cover.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: "#555"
                        font.pixelSize: coverArea.side * 0.4
                    }
                }

                Image {
                    id: cover
                    anchors.centerIn: parent
                    width: coverArea.side
                    height: coverArea.side
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    source: mpd.coverArt
                }
            }

            Text {
                Layout.fillWidth: true
                text: mpd.title !== "" ? mpd.title : (mpd.state === "play" ? "—" : "Stopped")
                color: "white"
                font.pixelSize: 30
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: mpd.artist
                visible: mpd.artist !== ""
                color: "#b0b0b0"
                font.pixelSize: 22
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: mpd.state === "play" ? "■ Stop" : "▶ Play"
                    font.pixelSize: 22
                    enabled: mpd.connected
                    onClicked: {
                        if (mpd.state === "play") {
                            mpd.stop();
                        } else if (mpd.currentUrl !== "") {
                            mpd.playStation(mpd.currentUrl);
                        } else if (radioPage.stations.length > 0) {
                            mpd.playStation(radioPage.stations[0].url);
                        }
                    }
                }

                Text {
                    text: mpd.connected
                          ? (mpd.stationName !== "" ? mpd.stationName : "Connected")
                          : "MPD not connected"
                    color: mpd.connected ? "#8a8a8a" : "#c06060"
                    font.pixelSize: 18
                }
            }
        }

        // ---- Station list (right) ------------------------------------ //
        Rectangle {
            Layout.preferredWidth: radioPage.width * 0.34
            Layout.fillHeight: true
            color: "#1c1c1c"
            radius: 8

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                clip: true
                model: radioPage.stations
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 72
                    radius: 8
                    property bool current: mpd.currentUrl === modelData.url
                    color: current ? modelData.color : "#2c2c2c"
                    border.color: current ? Qt.lighter(modelData.color, 1.3) : "#3a3a3a"
                    border.width: current ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: modelData.color
                            border.color: "white"
                            border.width: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: "white"
                            font.pixelSize: 24
                            font.bold: current
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "♫"
                            visible: current && mpd.state === "play"
                            color: "white"
                            font.pixelSize: 22
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mpd.playStation(modelData.url)
                    }
                }
            }
        }
    }
}
