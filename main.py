#! /usr/bin/python3

import sys

from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine

from mpd_client import MPDClient


app = QGuiApplication(sys.argv)

app.setApplicationName("timer-console")
app.setOrganizationName("guakamole")
app.setOrganizationDomain("org.guakamole")

engine = QQmlApplicationEngine()
engine.quit.connect(app.quit)

mpd = MPDClient()
engine.rootContext().setContextProperty("mpd", mpd)

engine.load('Main.qml')

sys.exit(app.exec())
