#!/bin/bash
set -e

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

flutter config --enable-web
flutter pub get

# Write .env from Vercel environment variables
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
ANON_KEY=${ANON_KEY}
EOF

flutter build web --release
