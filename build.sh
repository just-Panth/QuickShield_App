#!/usr/bin/env bash

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web
flutter config --enable-web

cd QuickShield_Frontend

# FIX: ensure web platform exists
flutter create .

# Get dependencies
flutter pub get

# Build web
flutter build web