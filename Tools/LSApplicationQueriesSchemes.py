#!/usr/bin/env python

import plistlib
import os
import sys


project_root = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))

apps_path = os.path.join(project_root, "Ringly", "Ringly", "Apps.plist")
info_path = os.path.join(project_root, "Ringly", "Ringly", "Ringly-Info.plist")

extra_schemes = [
    "fbapi",
    "fbauth2",
    "fbshareextension",
    "fbapi20150629",
    "pinterestsdk.v1"
]

apps = plistlib.readPlist(apps_path)
schemes = [app["Scheme"] for app in apps]

all_schemes = extra_schemes + schemes

info = plistlib.readPlist(info_path)
info["LSApplicationQueriesSchemes"] = all_schemes

plistlib.writePlist(info, info_path)
