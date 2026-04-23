#!/usr/bin/env bash
set -xe

# -------- CONFIG --------

APP_NAME="app"
BASE_APK="base.apk"
SPLITS_DIR="./splits"   # folder with split_config*.apk
BUILD_TOOLS="$HOME/Android/Sdk/build-tools/34.0.0"
KEYSTORE="./my.keystore"
KEY_ALIAS="my"
PACKAGE_NAME="com.intelbras.isiclite"

# -------- CLEAN --------

#rm -rf "$APP_NAME" dist
#mkdir -p dist
#
#echo "[+] Decoding APK..."
#apktool d "$BASE_APK" -o "$APP_NAME"
#
#echo "[+] >>> APPLY YOUR SMALI PATCHES NOW <<<"
#read -p "Press enter when done..."

echo "[+] Rebuilding APK..."
apktool b "$APP_NAME" -o dist/base-unsigned.apk

echo "[+] Aligning base APK..."
"$BUILD_TOOLS/zipalign" -p 4 dist/base-unsigned.apk dist/base-aligned.apk

echo "[+] Signing base APK..."
"$BUILD_TOOLS/apksigner" sign \
--ks "$KEYSTORE" \
--ks-key-alias "$KEY_ALIAS" \
dist/base-aligned.apk 

# -------- HANDLE SPLITS --------

SIGNED_SPLITS=""

for f in "$SPLITS_DIR"/*.apk; do
name=$(basename "$f")
aligned="dist/aligned-$name"

echo "[+] Aligning $name..."
"$BUILD_TOOLS/zipalign" -p 4 "$f" "$aligned"

echo "[+] Signing $name..."
"$BUILD_TOOLS/apksigner" sign \
--ks "$KEYSTORE" \
--ks-key-alias "$KEY_ALIAS" \
"$aligned"

SIGNED_SPLITS="$SIGNED_SPLITS $aligned"
done

# echo "[+] Uninstalling original app (ignore errors)..."
# adb uninstall $PACKAGE_NAME || true

echo "[+] Installing APK set..."
adb install-multiple dist/base-aligned.apk $SIGNED_SPLITS

echo "[+] Done!"
