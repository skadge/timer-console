import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: radioPage

    // Web radio stations. Stream URLs are plain HTTP(S) streams that MPD can
    // play directly; edit/extend this list as needed.
    // BBC streams use the BBC "nonuk" HLS path (the old direct hosts were
    // decommissioned and the standard HLS pools are UK-geo-restricted). The
    // a.files.bbci.co.uk master URL is stable and redirects to the live pool.
    readonly property string bbcHls:
        "https://a.files.bbci.co.uk/ms6/live/3441A116-B12E-4D2F-ACA8-C1984642FA4B/audio/simulcast/hls/nonuk/pc_hd_abr_v2/cf"

    property var stations: [
        {"name": "France Inter",   "url": "https://icecast.radiofrance.fr/franceinter-midfi.mp3", "color": "#e2001a", "logo": "res/logos/logo_france_inter.svg"},
        {"name": "France Info",    "url": "https://icecast.radiofrance.fr/franceinfo-midfi.mp3",  "color": "#cc1f2e", "logo": "res/logos/logo_franceinfo.svg"},
        {"name": "Radio Nova",     "url": "http://novazz.ice.infomaniak.ch/novazz-128.mp3",        "color": "#f0a500", "logo": "res/logos/logo_radio_nova.svg"},
        {"name": "Radio Paradise", "url": "https://stream.radioparadise.com/mp3-192",             "color": "#3a6ea5", "logo": "res/logos/logo_radio_paradise.svg"},
        {"name": "BBC Radio 1",    "url": radioPage.bbcHls + "/bbc_radio_one.m3u8",    "color": "#d4145a", "logo": "res/logos/logo_bbc_radio_1.svg"},
        {"name": "BBC Radio 2",    "url": radioPage.bbcHls + "/bbc_radio_two.m3u8",    "color": "#e94f1d", "logo": "res/logos/logo_bbc_radio_2.svg"},
        {"name": "BBC Radio 3",    "url": radioPage.bbcHls + "/bbc_radio_three.m3u8",  "color": "#009ca6", "logo": "res/logos/logo_bbc_radio_3.svg"},
        {"name": "BBC Radio 4",    "url": radioPage.bbcHls + "/bbc_radio_fourfm.m3u8", "color": "#6b3fa0", "logo": "res/logos/logo_bbc_radio_4.svg"},
    ]

    // Logo of the currently-playing station, used as a fallback when the
    // stream provides no cover art. Re-evaluates when the station changes.
    function logoForUrl(url) {
        for (var i = 0; i < stations.length; i++)
            if (stations[i].url === url)
                return stations[i].logo || "";
        return "";
    }
    readonly property string currentLogo: logoForUrl(mpd.currentUrl)

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
                    // Shown only when there is neither real cover art nor a logo.
                    visible: !cover.visible && !logoCard.visible

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: "#555"
                        font.pixelSize: coverArea.side * 0.4
                    }
                }

                // Real album/cover art from the stream: fills the square.
                Image {
                    id: cover
                    anchors.centerIn: parent
                    width: coverArea.side
                    height: coverArea.side
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    visible: mpd.coverArt !== "" && status === Image.Ready
                    source: mpd.coverArt
                }

                // Station-logo fallback when the stream has no cover art. The
                // logos are designed for light backgrounds, so show them on a
                // white rounded card with padding.
                Rectangle {
                    id: logoCard
                    anchors.centerIn: parent
                    width: coverArea.side
                    height: coverArea.side
                    radius: 10
                    color: "white"
                    visible: mpd.coverArt === "" && logo.status === Image.Ready

                    Image {
                        id: logo
                        anchors.fill: parent
                        anchors.margins: coverArea.side * 0.12
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        source: mpd.coverArt === "" ? radioPage.currentLogo : ""
                        // Render the SVG at display resolution for crisp edges.
                        sourceSize.width: coverArea.side
                        sourceSize.height: coverArea.side
                    }
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
                id: stationList
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                clip: true
                model: radioPage.stations
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: stationList.contentHeight > stationList.height
                            ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    width: 6
                }

                delegate: Rectangle {
                    width: ListView.view.width - (stationList.ScrollBar.vertical.visible ? 10 : 0)
                    height: 54
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
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData.color
                            border.color: "white"
                            border.width: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: "white"
                            font.pixelSize: 20
                            font.bold: current
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "♫"
                            visible: current && mpd.state === "play"
                            color: "white"
                            font.pixelSize: 18
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
