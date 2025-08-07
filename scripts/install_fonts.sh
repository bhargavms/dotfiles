#!/bin/bash

FONT_NAME="0xProto"
ZIP_NAME="${FONT_NAME}.zip"
EXPECTED_SHA256="e50e7fec9efbe1eb986b65f01e210098e122a3f495db24e6624bdcbca52da11d"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.zip"
FONT_DIR="$HOME/Library/Fonts"
TEMP_ZIP="/tmp/${ZIP_NAME}"

echo "🔍 Downloading ${FONT_NAME} Nerd Font..."
curl -L --fail -o "$TEMP_ZIP" "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "❌ Download failed."
    exit 1
fi

echo "🔒 Verifying checksum..."
ACTUAL_SHA256=$(shasum -a 256 "$TEMP_ZIP" | awk '{print $1}')

if [ "$EXPECTED_SHA256" != "$ACTUAL_SHA256" ]; then
    echo "❌ Checksum mismatch!"
    echo "Expected: $EXPECTED_SHA256"
    echo "Actual:   $ACTUAL_SHA256"
    rm "$TEMP_ZIP"
    exit 1
fi

echo "📦 Installing font..."
unzip -o "$TEMP_ZIP" -d "$FONT_DIR"
rm "$TEMP_ZIP"

echo "✅ ${FONT_NAME} Nerd Font successfully installed with verified integrity!"

