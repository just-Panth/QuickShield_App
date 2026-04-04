#!/usr/bin/env bash

# Install Flutter inside the frontend folder
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web
flutter config --enable-web

# FIX: ensure web platform exists
flutter create .

# Get dependencies
flutter pub get

# Build web
flutter build web
