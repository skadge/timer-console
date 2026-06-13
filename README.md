Timer console
=============

A little touchscreen console (built for a Raspberry Pi screen) with two tabs:

- **Timer**: per-person daily screen-time countdowns.
- **Radio**: control web radios played through MPD, showing the current
  song's cover art and metadata.

The bus schedule status bar stays visible across both tabs.

Radio
-----

The Radio tab talks to a local [MPD](https://www.musicpd.org/) server (also
served by [myMPD](https://github.com/jcorporation/myMPD)) over its native TCP
protocol on `localhost:6600`. Make sure `mpd` is installed and running; if it
is not reachable the rest of the app keeps working and the Radio tab shows
"MPD not connected".

Cover art for the currently-playing song is looked up via
[MusicBrainz](https://musicbrainz.org/) and the
[Cover Art Archive](https://coverartarchive.org/).

Edit the `stations` list at the top of `RadioPage.qml` to change the stations.

Install
-------

To install, copy `ScreenTimer.desktop` to `~/.local/share/applications` (if necessary, adapt the paths in the file first).
