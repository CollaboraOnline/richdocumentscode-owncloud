#! /bin/bash
#
# Usage: ./build-owncloud-app.sh [-f] [URL-to-AppImage-to-download]
#

# the safest is to build from a clean 'build', warn if it exists

occ=$HOME/bin/occ
cert_dir=$HOME/.owncloud/certificates
app_name=richdocumentscode

test -d "build" -a "$1" != "-f" && {
    cat << EOF
The 'build' subdir already exists.  Please move it away, or run:"

  `basename $0` -f

if you know what you are doing
EOF
    exit 1
}

# remove the -f if present
test "$1" == "-f" && shift

# use the latest, unless URL specified on the command line
APPIMAGE_URL=${1:-https://www.collaboraoffice.com/Collabora-Office-AppImage-Snapshot/collabora-online-snapshot-LATEST.AppImage}

# use the latest proxy.php
PROXY_PHP_URL=https://raw.githubusercontent.com/CollaboraOnline/richdocumentscode/master/proxy.php

echo "Using the AppImage from: $APPIMAGE_URL"
echo

# build in the "build" dir
test -d "build" || mkdir -p "build"
cd "build"

test -d "${app_name}" || mkdir -p "${app_name}"

cp -ra ../appinfo ../l10n ../lib ../templates ${app_name}/
cp -ra ../img ${app_name}/
cp -a ../CHANGELOG.md ../LICENSE ../NOTICES ${app_name}/

# get the appimage
test -d "${app_name}/collabora" || mkdir -p "${app_name}/collabora"
test -f "${app_name}/collabora/Collabora_Online.AppImage" || curl "$APPIMAGE_URL" -o "${app_name}/collabora/Collabora_Online.AppImage"
chmod a+x "${app_name}/collabora/Collabora_Online.AppImage"

# get the proxy.php
test -f "${app_name}/proxy.php" || curl "$PROXY_PHP_URL" -o "${app_name}/proxy.php"

# Create proxy.php and get the version hash from loolwsd into it
HASH=`./${app_name}/collabora/Collabora_Online.AppImage --version-hash`
echo "HASH: $HASH"
sed -i "s/%LOOLWSD_VERSION_HASH%/$HASH/g" ${app_name}/proxy.php

echo "Signing…"
$occ integrity:sign-app --privateKey=${cert_dir}/${app_name}.key --certificate=${cert_dir}/${app_name}.crt --path=$(pwd)/${app_name}
tar czf ${app_name}.tar.gz ${app_name}
openssl dgst -sha512 -sign ${cert_dir}/${app_name}.key ${app_name}.tar.gz | openssl base64

