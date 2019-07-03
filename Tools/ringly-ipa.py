#!/usr/bin/env python

from __future__ import print_function

import argparse
import json
import os
import shutil
import subprocess
import tempfile
import zipfile

parser = argparse.ArgumentParser(description='Process IPA files for Ringly')
parser.add_argument('IPAs', nargs='+')
parser.add_argument('--imageoutput')

args = parser.parse_args()

def load_plist(plist_path):
    json_path = os.path.join(tempfile.mkdtemp(), "Info.json")
    args = ['plutil', '-convert', 'json', plist_path, '-o', json_path]
    if subprocess.call(args) is 0:
        with open(json_path) as fd:
            return json.load(fd)
    else:
        print("Failed to convert plist to JSON")
        return None

def process_app(app_dir):
    info_path = os.path.join(app_dir, "Info.plist")
    info = load_plist(info_path)

    print_info(app_dir, info)

    if args.imageoutput:
        copy_icon(app_dir, info, args.imageoutput)

def print_info(app, info):
    print(" {0}".format(info['CFBundleIdentifier']))
    print(" URL Types:")

    try:
        for URLType in info['CFBundleURLTypes']:
            try:
                for scheme in URLType['CFBundleURLSchemes']:
                    print("  {0}".format(scheme))
            except KeyError:
                pass
    except Exception as e:
        print("  Can't support, no URL types!")

def extant_files_with_extensions(files, extensions):
    actual_files = []

    for path in files:
        for extension in extensions:
            full_path = "{0}{1}".format(path, extension)

            if os.path.isfile(full_path):
                actual_files.append(full_path)

    return actual_files

def icon_files(app, info):
    files = []

    try:
        files = info['CFBundleIconFiles']
    except Exception as e:
        files = info['CFBundleIcons']['CFBundlePrimaryIcon']['CFBundleIconFiles']

    files = [os.path.join(app, icon) for icon in files]

    return extant_files_with_extensions(files, ["", ".png", "@2x.png", "@3x.png"])

def copy_icon(app_path, info, output_dir):
    icon_path = reduce(larger_image, icon_files(app_path, info), None)
    filename = "{0}.png".format(os.path.basename(app_path))
    output_path = os.path.join(output_dir, filename)
    shutil.copy2(icon_path, output_path)

def image_height(image_path):
    pixel_height = 'pixelHeight'
    sips = subprocess.check_output(['sips', '-g', pixel_height, image_path])
    location = sips.rfind(pixel_height) + len(pixel_height) + 1

    return int(sips[location:])

def larger_image(image_path_1, image_path_2):
    if image_path_1 is None:
        return image_path_2

    height_1 = image_height(image_path_1)
    height_2 = image_height(image_path_2)

    return image_path_1 if height_1 > height_2 else image_path_2

for IPA in args.IPAs:
    print(os.path.basename(IPA))

    temp = tempfile.mkdtemp()
    zipfile.ZipFile(IPA).extractall(temp)

    payload = os.path.join(temp, "Payload")

    for app in os.listdir(payload):
        app_dir = os.path.join(payload, app)
        process_app(app_dir)
        print()
