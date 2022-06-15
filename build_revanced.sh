#!/bin/bash

get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\"sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

if [ ! -f "revanced-cli.jar" ]; then
    echo "Downloading revanced-cli.jar"
    curl -L -o revanced-cli.jar $(get_artifact_download_url "revanced/revanced-cli" "revanced-cli" ".jar")
fi

if [ ! -f "revanced-integrations.apk" ]; then
    echo "Downloading revanced-integrations.apk"
    curl -L -o revanced-integrations.apk $(get_artifact_download_url "revanced/revanced-integrations" "app-release-unsigned" ".apk")
fi

if [ ! -f "revanced-patches.jar" ]; then
    echo "Downloading revanced-patches.jar"
    curl -L -o revanced-patches.jar $(get_artifact_download_url "revanced/revanced-patches" "revanced-patches" ".jar")
fi

# Latest compatible version of apks
# YouTube Music 5.03.50
# YouTube 17.22.36
# Vanced microG 0.2.24.220220

YTM_VERSION="5.03.50"
YT_VERSION="17.22.36"
VMG_VERSION="0.2.24.220220"

if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep"
    curl -L -o apkeep $(get_artifact_download_url "EFForg/apkeep" "apkeep-x86_64-unknown-linux-gnu")
    chmod +x apkeep
fi

# ./apkeep -a com.google.android.youtube@17.22.36 com.google.android.youtube
# ./apkeep -a com.google.android.apps.youtube.music@5.03.50 com.google.android.apps.youtube.music

if [ ! -f "vanced-microG.apk" ]; then
    echo "Downloading Vanced microG"
    ./apkeep -a com.mgoogle.android.gms@$VMG_VERSION .
    mv com.mgoogle.android.gms@$VMG_VERSION.apk vanced-microG.apk
fi

# if [ -f "com.google.android.youtube.xapk" ]
# then
#     unzip com.google.android.youtube.xapk -d youtube
#     yt_apk_path="youtube/com.google.android.youtube.apk"
# elif [ -f "com.google.android.youtube.apk" ]
# then
#     yt_apk_path="com.google.android.youtube.apk"
# else
#     echo "Cannot find APK"
# fi

echo "************************************"
echo "Building YouTube APK"
echo "************************************"

mkdir -p build
available_patches=$(java -jar revanced-cli.jar -b revanced-patches.jar -a a -o b -l | sed -Er  's#\[available\] (.+)#-i \1 #')
# Uncomment and modify the following line to set different patches
# available_patches="-i codecs-unlock -i exclusive-audio-playback -i tasteBuilder-remover -i upgrade-button-remover -i background-play -i general-ads -i video-ads -i seekbar-tapping -i amoled -i premium-heading -i custom-branding -i disable-create-button -i minimized-playback -i old-quality-layout -i shorts-button -i microg-support"

if [ -f "com.google.android.youtube.apk" ]
then
    echo "Building Root APK"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
                               -a com.google.android.youtube.apk -o build/revanced-root.apk
    echo "Building Non-root APK"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
                               $available_patches \
                               -a com.google.android.youtube.apk -o build/revanced-nonroot.apk
else
    echo "Cannot find YouTube APK, skipping build"
fi
echo ""
echo "************************************"
echo "Building YouTube Music APK"
echo "************************************"
if [ -f "com.google.android.apps.youtube.music.apk" ]
then
    echo "Building Root APK"
    java -jar revanced-cli.jar -b revanced-patches.jar \
                               -a com.google.android.apps.youtube.music.apk -o build/revanced-music-root.apk
    echo "Building Non-root APK"
    java -jar revanced-cli.jar -b revanced-patches.jar \
                               $available_patches \
                               -a com.google.android.apps.youtube.music.apk -o build/revanced-music-nonroot.apk
else
    echo "Cannot find YouTube Music APK, skipping build"
fi