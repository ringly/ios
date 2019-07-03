WORKSPACE_DIRECTORY="$(dirname "$0")/.."

echo WORKSPACE_DIRECTORY

# set the build version if specified
if [ -z ${BUILD_NUMBER+null} ]; then
    echo "No build number set. This is okay - will build without modifying “Info.plist” or badging icon."
else
    /usr/libexec/PlistBuddy -c "Set CFBundleVersion ${BUILD_NUMBER}" "${WORKSPACE_DIRECTORY}/Ringly/Ringly/Ringly-Info.plist"

    # badge the icon files with information
    HASH=`/usr/bin/git rev-parse --short HEAD`
    VERSION=`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${WORKSPACE_DIRECTORY}/Ringly/Ringly/Ringly-Info.plist"`
    echo "${WORKSPACE_DIRECTORY}"
    for line in $(find ../Ringly/Ringly/Images.xcassets/AppIcon.appiconset -iname "*.png"); do
      WIDTH=`/usr/local/bin/identify -format %w ${line}`
      HEIGHT=`/usr/local/bin/identify -format %h ${line}`
      START_Y=`expr ${HEIGHT} - ${HEIGHT} \* 2 / 5`
      POINTSIZE=`expr ${HEIGHT} / 6`

      /usr/local/bin/mogrify \
        -fill 'rgba(0,0,0,0.5)' \
        -draw "rectangle 0,${START_Y} ${WIDTH},${HEIGHT}" \
        -fill 'rgb(255, 255, 255)' \
        -font '/Library/Fonts/Arial.ttf' \
        -pointsize ${POINTSIZE} \
        -antialias \
        -gravity South \
        -draw "text 0,0 '${HASH}'" \
        -gravity North \
        -draw "text 0,${START_Y} '${VERSION} • #${BUILD_NUMBER}'" \
        ${line}
    done
fi