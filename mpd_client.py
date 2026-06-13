#! /usr/bin/python3

"""A small MPD client exposed to QML.

It speaks MPD's native, line-based TCP protocol (default localhost:6600,
also served by myMPD) using a QTcpSocket so everything stays inside the Qt
event loop (no blocking calls). It can start/stop web-radio streams, polls
the current play state and song metadata, and resolves cover art for the
currently-playing song through MusicBrainz and the Cover Art Archive.
"""

import json

from PyQt5.QtCore import (
    QObject,
    QUrl,
    QUrlQuery,
    QTimer,
    pyqtProperty,
    pyqtSignal,
    pyqtSlot,
)
from PyQt5.QtNetwork import (
    QAbstractSocket,
    QNetworkAccessManager,
    QNetworkReply,
    QNetworkRequest,
    QTcpSocket,
)


class MPDClient(QObject):

    titleChanged = pyqtSignal()
    artistChanged = pyqtSignal()
    albumChanged = pyqtSignal()
    stationNameChanged = pyqtSignal()
    stateChanged = pyqtSignal()
    connectedChanged = pyqtSignal()
    coverArtChanged = pyqtSignal()
    currentUrlChanged = pyqtSignal()

    def __init__(self, host="localhost", port=6600, parent=None):
        super().__init__(parent)
        self._host = host
        self._port = port

        self._title = ""
        self._artist = ""
        self._album = ""
        self._station_name = ""
        self._state = "stop"
        self._connected = False
        self._cover_art = ""
        self._current_url = ""

        # protocol state
        self._greeted = False
        self._busy = False
        self._queue = []          # pending (command, callback)
        self._current_cb = None
        self._response_lines = []
        self._buffer = b""
        self._last_cover_key = ""

        # MusicBrainz asks for a descriptive User-Agent with contact info.
        self._user_agent = b"timer-console/1.0 ( severin@guakamole.org )"

        self._socket = QTcpSocket(self)
        self._socket.readyRead.connect(self._on_ready_read)
        self._socket.connected.connect(self._on_socket_connected)
        self._socket.disconnected.connect(self._on_socket_disconnected)

        self._nam = QNetworkAccessManager(self)

        self._poll = QTimer(self)
        self._poll.setInterval(2000)
        self._poll.timeout.connect(self._refresh)

        # keep retrying to (re)connect to MPD if it is not (yet) reachable
        self._reconnect = QTimer(self)
        self._reconnect.setInterval(3000)
        self._reconnect.timeout.connect(self._try_connect)
        self._reconnect.start()

        self._try_connect()

    # ------------------------------------------------------------------ #
    # Connection handling
    # ------------------------------------------------------------------ #
    def _try_connect(self):
        if self._socket.state() == QAbstractSocket.UnconnectedState:
            self._greeted = False
            self._socket.connectToHost(self._host, self._port)

    def _on_socket_connected(self):
        # The MPD greeting ("OK MPD <version>") is awaited in _handle_line.
        pass

    def _on_socket_disconnected(self):
        self._greeted = False
        self._busy = False
        self._queue = []
        self._current_cb = None
        self._response_lines = []
        self._buffer = b""
        self._poll.stop()
        self._set_connected(False)
        self._set_state("stop")

    # ------------------------------------------------------------------ #
    # Protocol parsing
    # ------------------------------------------------------------------ #
    def _on_ready_read(self):
        self._buffer += bytes(self._socket.readAll())
        while b"\n" in self._buffer:
            raw, self._buffer = self._buffer.split(b"\n", 1)
            self._handle_line(raw.decode("utf-8", errors="replace").rstrip("\r"))

    def _handle_line(self, line):
        if not self._greeted:
            if line.startswith("OK MPD"):
                self._greeted = True
                self._set_connected(True)
                self._poll.start()
                self._refresh()
                self._pump()
            return

        if line == "OK":
            cb, lines = self._current_cb, self._response_lines
            self._busy = False
            self._current_cb = None
            self._response_lines = []
            if cb:
                cb(lines)
            self._pump()
        elif line.startswith("ACK"):
            print("MPD error: " + line)
            self._busy = False
            self._current_cb = None
            self._response_lines = []
            self._pump()
        else:
            self._response_lines.append(line)

    def _send(self, command, cb=None):
        self._queue.append((command, cb))
        self._pump()

    def _pump(self):
        if not self._greeted or self._busy or not self._queue:
            return
        command, cb = self._queue.pop(0)
        self._busy = True
        self._current_cb = cb
        self._response_lines = []
        self._socket.write((command + "\n").encode("utf-8"))

    @staticmethod
    def _parse_kv(lines):
        data = {}
        for line in lines:
            key, sep, value = line.partition(": ")
            if sep and key not in data:
                data[key] = value
        return data

    # ------------------------------------------------------------------ #
    # Polling
    # ------------------------------------------------------------------ #
    def _refresh(self):
        if not self._greeted:
            return
        self._send("status", self._parse_status)
        self._send("currentsong", self._parse_currentsong)

    def _parse_status(self, lines):
        data = self._parse_kv(lines)
        self._set_state(data.get("state", "stop"))

    def _parse_currentsong(self, lines):
        data = self._parse_kv(lines)
        title = data.get("Title", "")
        artist = data.get("Artist", "")
        album = data.get("Album", "")

        # web radios usually expose only an ICY title of the form
        # "Artist - Song" with no separate Artist tag: split it for display.
        if not artist and " - " in title:
            artist, _, title = title.partition(" - ")

        self._set_title(title)
        self._set_artist(artist)
        self._set_album(album)
        self._set_station_name(data.get("Name", ""))
        self._maybe_update_cover()

    # ------------------------------------------------------------------ #
    # Cover art (MusicBrainz + Cover Art Archive)
    # ------------------------------------------------------------------ #
    def _maybe_update_cover(self):
        artist = self._artist
        title = self._title
        key = (artist + "|" + title).strip()

        if not artist or not title or key == "|" or key == self._last_cover_key:
            return
        self._last_cover_key = key

        # Look up a matching recording on MusicBrainz to obtain a release MBID,
        # which the Cover Art Archive then maps to the artwork.
        lucene = 'recording:"{}" AND artist:"{}"'.format(
            title.replace('"', " "), artist.replace('"', " ")
        )
        url = QUrl("https://musicbrainz.org/ws/2/recording")
        query = QUrlQuery()
        query.addQueryItem("query", lucene)
        query.addQueryItem("fmt", "json")
        query.addQueryItem("limit", "1")
        url.setQuery(query)

        request = QNetworkRequest(url)
        request.setRawHeader(b"User-Agent", self._user_agent)
        reply = self._nam.get(request)
        reply.finished.connect(lambda r=reply, k=key: self._on_mb_reply(r, k))

    def _on_mb_reply(self, reply, key):
        try:
            if reply.error() != QNetworkReply.NoError:
                return
            if key != self._last_cover_key:
                return  # a newer song arrived while this request was in flight
            payload = json.loads(bytes(reply.readAll()).decode("utf-8", "replace"))
            recordings = payload.get("recordings", [])
            if not recordings:
                self._set_cover_art("")
                return
            releases = recordings[0].get("releases", [])
            if not releases:
                self._set_cover_art("")
                return
            mbid = releases[0].get("id", "")
            if not mbid:
                self._set_cover_art("")
                return
            self._resolve_cover(
                "https://coverartarchive.org/release/{}/front-500".format(mbid), key
            )
        finally:
            reply.deleteLater()

    def _resolve_cover(self, front_url, key):
        # The Cover Art Archive redirects /front* to the real image host; follow
        # it here so QML receives a direct URL (QML's Image does not reliably
        # follow cross-host redirects). A 404 means no art is available.
        request = QNetworkRequest(QUrl(front_url))
        request.setRawHeader(b"User-Agent", self._user_agent)
        request.setAttribute(
            QNetworkRequest.RedirectPolicyAttribute,
            QNetworkRequest.NoLessSafeRedirectPolicy,
        )
        reply = self._nam.head(request)
        reply.finished.connect(lambda r=reply, k=key: self._on_cover_resolved(r, k))

    def _on_cover_resolved(self, reply, key):
        try:
            if key != self._last_cover_key:
                return
            if reply.error() != QNetworkReply.NoError:
                self._set_cover_art("")  # typically a 404: no cover art on file
                return
            self._set_cover_art(reply.url().toString())
        finally:
            reply.deleteLater()

    # ------------------------------------------------------------------ #
    # Slots callable from QML
    # ------------------------------------------------------------------ #
    @pyqtSlot(str)
    def playStation(self, url):
        self._set_current_url(url)
        self._send("clear")
        self._send('add "{}"'.format(url.replace("\\", "\\\\").replace('"', '\\"')))
        self._send("play")
        self._refresh()

    @pyqtSlot()
    def stop(self):
        self._send("stop")
        self._set_current_url("")
        self._refresh()

    # ------------------------------------------------------------------ #
    # Internal setters (emit change notifications)
    # ------------------------------------------------------------------ #
    def _set_title(self, value):
        if value != self._title:
            self._title = value
            self.titleChanged.emit()

    def _set_artist(self, value):
        if value != self._artist:
            self._artist = value
            self.artistChanged.emit()

    def _set_album(self, value):
        if value != self._album:
            self._album = value
            self.albumChanged.emit()

    def _set_station_name(self, value):
        if value != self._station_name:
            self._station_name = value
            self.stationNameChanged.emit()

    def _set_state(self, value):
        if value != self._state:
            self._state = value
            self.stateChanged.emit()

    def _set_connected(self, value):
        if value != self._connected:
            self._connected = value
            self.connectedChanged.emit()

    def _set_cover_art(self, value):
        if value != self._cover_art:
            self._cover_art = value
            self.coverArtChanged.emit()

    def _set_current_url(self, value):
        if value != self._current_url:
            self._current_url = value
            self.currentUrlChanged.emit()

    # ------------------------------------------------------------------ #
    # Properties exposed to QML
    # ------------------------------------------------------------------ #
    @pyqtProperty(str, notify=titleChanged)
    def title(self):
        return self._title

    @pyqtProperty(str, notify=artistChanged)
    def artist(self):
        return self._artist

    @pyqtProperty(str, notify=albumChanged)
    def album(self):
        return self._album

    @pyqtProperty(str, notify=stationNameChanged)
    def stationName(self):
        return self._station_name

    @pyqtProperty(str, notify=stateChanged)
    def state(self):
        return self._state

    @pyqtProperty(bool, notify=connectedChanged)
    def connected(self):
        return self._connected

    @pyqtProperty(str, notify=coverArtChanged)
    def coverArt(self):
        return self._cover_art

    @pyqtProperty(str, notify=currentUrlChanged)
    def currentUrl(self):
        return self._current_url
