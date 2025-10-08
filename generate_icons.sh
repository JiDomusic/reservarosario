#!/bin/bash

# Script para generar iconos de SODITA en todos los tamaños necesarios
echo "🍶 Generando iconos de SODITA..."

# Verificar si ImageMagick está instalado
if ! command -v convert &> /dev/null; then
    echo "📦 Instalando ImageMagick..."
    sudo apt update && sudo apt install -y imagemagick
fi

# Crear directorio temporal
mkdir -p temp_icons

# Convertir SVG a PNG base de alta resolución
echo "📷 Creando imagen base..."
convert -background transparent sodita_icon.svg -resize 1024x1024 temp_icons/sodita_base.png

# ANDROID - Generar iconos para diferentes densidades
echo "🤖 Generando iconos para Android..."

# mipmap-mdpi (48x48)
convert temp_icons/sodita_base.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png

# mipmap-hdpi (72x72) 
convert temp_icons/sodita_base.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png

# mipmap-xhdpi (96x96)
convert temp_icons/sodita_base.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png

# mipmap-xxhdpi (144x144)
convert temp_icons/sodita_base.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png

# mipmap-xxxhdpi (192x192)
convert temp_icons/sodita_base.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# iOS - Generar iconos para App Store
echo "🍎 Generando iconos para iOS..."

# 1024x1024 (App Store)
cp temp_icons/sodita_base.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

# 20x20
convert temp_icons/sodita_base.png -resize 20x20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
convert temp_icons/sodita_base.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
convert temp_icons/sodita_base.png -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png

# 29x29
convert temp_icons/sodita_base.png -resize 29x29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
convert temp_icons/sodita_base.png -resize 58x58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
convert temp_icons/sodita_base.png -resize 87x87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png

# 40x40
convert temp_icons/sodita_base.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
convert temp_icons/sodita_base.png -resize 80x80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
convert temp_icons/sodita_base.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png

# 60x60
convert temp_icons/sodita_base.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
convert temp_icons/sodita_base.png -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png

# 76x76
convert temp_icons/sodita_base.png -resize 76x76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
convert temp_icons/sodita_base.png -resize 152x152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png

# 83.5x83.5
convert temp_icons/sodita_base.png -resize 167x167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

# WEB - Generar iconos para navegador
echo "🌐 Generando iconos para Web..."

# Favicon
convert temp_icons/sodita_base.png -resize 32x32 web/favicon.png

# PWA Icons
convert temp_icons/sodita_base.png -resize 192x192 web/icons/Icon-192.png
convert temp_icons/sodita_base.png -resize 512x512 web/icons/Icon-512.png
convert temp_icons/sodita_base.png -resize 192x192 web/icons/Icon-maskable-192.png
convert temp_icons/sodita_base.png -resize 512x512 web/icons/Icon-maskable-512.png

# macOS - Generar iconos para Mac
echo "🖥️ Generando iconos para macOS..."

convert temp_icons/sodita_base.png -resize 16x16 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
convert temp_icons/sodita_base.png -resize 32x32 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
convert temp_icons/sodita_base.png -resize 64x64 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
convert temp_icons/sodita_base.png -resize 128x128 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
convert temp_icons/sodita_base.png -resize 256x256 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
convert temp_icons/sodita_base.png -resize 512x512 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
convert temp_icons/sodita_base.png -resize 1024x1024 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png

# Windows - Generar icono para Windows
echo "🪟 Generando iconos para Windows..."

# Crear ICO file con múltiples tamaños
convert temp_icons/sodita_base.png \
    \( -clone 0 -resize 16x16 \) \
    \( -clone 0 -resize 24x24 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 64x64 \) \
    \( -clone 0 -resize 128x128 \) \
    \( -clone 0 -resize 256x256 \) \
    -delete 0 windows/runner/resources/app_icon.ico

# Limpiar archivos temporales
echo "🧹 Limpiando archivos temporales..."
rm -rf temp_icons

echo "✅ ¡Iconos de SODITA generados exitosamente!"
echo "📱 Android: mipmap-*/ic_launcher.png"
echo "🍎 iOS: Assets.xcassets/AppIcon.appiconset/"
echo "🌐 Web: web/icons/ y favicon.png"
echo "🖥️ macOS: Assets.xcassets/AppIcon.appiconset/"
echo "🪟 Windows: resources/app_icon.ico"