#!/bin/bash

# Android Keystore Generation Script
# This script generates a keystore for signing Android release builds

set -e

echo "========================================="
echo "Android Keystore Generation"
echo "========================================="
echo ""
echo "This script will generate a keystore for signing your Android app."
echo "You'll need to provide some information for the certificate."
echo ""

# Set keystore location
KEYSTORE_FILE="android/app/upload-keystore.jks"
KEY_ALIAS="upload"

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  Warning: Keystore already exists at $KEYSTORE_FILE"
    read -p "Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "Aborting."
        exit 1
    fi
    rm "$KEYSTORE_FILE"
fi

echo ""
echo "Generating keystore..."
echo ""

# Generate keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storetype JKS

echo ""
echo "========================================="
echo "✅ Keystore generated successfully!"
echo "========================================="
echo ""
echo "Keystore location: $KEYSTORE_FILE"
echo "Key alias: $KEY_ALIAS"
echo ""
echo "⚠️  IMPORTANT: Keep your keystore and passwords safe!"
echo "   - Never commit the keystore to version control"
echo "   - Store passwords securely (password manager recommended)"
echo "   - Back up the keystore file"
echo "   - If you lose it, you cannot update your app in stores"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo ""
echo "1. Encode the keystore for GitHub Secrets:"
echo ""

# Check OS and provide appropriate command
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   base64 -i $KEYSTORE_FILE | pbcopy"
    echo "   (Copied to clipboard on macOS)"
else
    echo "   base64 -w 0 $KEYSTORE_FILE"
    echo "   (Copy the output)"
fi

echo ""
echo "2. Add the following secrets to your GitHub repository:"
echo "   Go to: Settings > Secrets and variables > Actions > New repository secret"
echo ""
echo "   ANDROID_KEYSTORE_BASE64  = <paste the base64 output>"
echo "   ANDROID_KEYSTORE_PASSWORD = <your keystore password>"
echo "   ANDROID_KEY_PASSWORD     = <your key password>"
echo "   ANDROID_KEY_ALIAS        = $KEY_ALIAS"
echo ""
echo "3. You can now trigger releases from GitHub Actions!"
echo ""

# Optionally encode and copy to clipboard on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "Would you like to encode and copy to clipboard now? (yes/no): " encode
    if [ "$encode" == "yes" ]; then
        base64 -i "$KEYSTORE_FILE" | pbcopy
        echo ""
        echo "✅ Base64 encoded keystore copied to clipboard!"
        echo "   You can now paste it as ANDROID_KEYSTORE_BASE64 secret in GitHub."
    fi
fi

echo ""
echo "Done! 🎉"
