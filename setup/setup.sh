#!/bin/bash

echo Hello and welcome to official Sbinator setup for Linux environment
sleep 2

# Checks what Linux distribution you have and what package manager you use
if command -v apt-get &> /dev/null; then
    DISTRO="debian"
elif command -v dnf &> /dev/null; then
    DISTRO="fedora"
elif command -v pacman &> /dev/null; then
    DISTRO="arch"
elif command -v zypper &> /dev/null; then
    DISTRO="opensuse"
elif command -v eopkg &> /dev/null; then
    DISTRO="solus"
else
    echo This Linux distribution does not have Haxe package available on official repo, so aborting!
    exit 1
fi

HAXE_PACKAGE="haxe" # Haxe package
GPP_PACKAGE="g++" # G++/Clang package

case "$DISTRO" in
    "debian")
        echo Detected Debian-based system. Installing Haxe from Debian"'"s APT repository.
        sudo apt-get update
        sudo apt-get install "$HAXE_PACKAGE" "$GPP_PACKAGE" -y
        ;;
    "fedora")
        echo Detected Fedora-based system. Installing Haxe from Fedora"'"s RPM repository.
        sudo dnf update
        sudo dnf upgrade
        sudo dnf install "$HAXE_PACKAGE" "$GPP_PACKAGE" -y
        ;;
    "arch")
        echo Detected Arch-based system. Installing Haxe from Arch extra repository.
        sudo pacman -Syu
        sudo pacman -S "$HAXE_PACKAGE" --noconfirm
        ;;
    "opensuse")
        echo Detected openSUSE-based system. Installing Haxe from openSUSE"'"s software repository
        sudo zypper install "$HAXE_PACKAGE" "$GPP_PACKAGE"
        ;;
    "solus")
        echo Detected SolusOS-based system. Installing Haxe from Solus EOPKG repository
        sudo eopkg up
        sudo eopkg install "$HAXE_PACKAGE" "$GPP_PACKAGE"
        ;;
    *)
        echo "No specific package manager found for $DISTRO."
        exit 1
        ;;
esac

echo "Haxe is installed sucessfully on $DISTRO!"
sleep 5
echo Making Haxelib directory on home folder and setuping it
mkdir ~/.local/share/haxelib && haxelib setup ~/.local/share/haxelib
sleep 2
echo Updating Haxelib
haxelib --global update haxelib
sleep 2
echo Downloading and installing all required Haxelib libraries for compiling the game "(Note that this will depend on your internet speed)"..
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install lime
haxelib install lime-samples
haxelib install openfl
haxelib install hxcpp
haxelib install hxdiscord_rpc
sleep 2
echo Fixing Haxelib repo
haxelib fixrepo
sleep 2
echo All required libraries for Haxelib are downloaded and installed successfully. Setuping Lime..
haxelib run lime setup
sleep 1
echo Setup is done. You can check library list here
haxelib list
