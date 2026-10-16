#!/usr/bin/env bash
# ==============================================================================
# Stelar iOS - Script de Compilación y Generación Automática de IPA
# ==============================================================================
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "============================================================"
echo "  STELAR PARA IOS - GENERADOR DE IPA"
echo "============================================================"

# Verificar xcodebuild
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: 'xcodebuild' no está disponible en este sistema."
    echo "   Para compilar la versión de iOS y generar la IPA necesitas macOS con Xcode instalado."
    exit 1
fi

BUILD_DIR="$DIR/build"
ARCHIVE_PATH="$BUILD_DIR/StelarIOS.xcarchive"
PAYLOAD_DIR="$BUILD_DIR/Payload"
OUTPUT_IPA="$BUILD_DIR/Stelar.ipa"

echo "🧹 Limpiando directorio de compilación..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🔨 Compilando archivo .xcarchive en modo Release..."
xcodebuild archive \
    -project "$DIR/StelarIOSApp.xcodeproj" \
    -scheme "StelarIOSApp" \
    -configuration "Release" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY=""

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Error: La compilación del archivo .xcarchive falló."
    exit 1
fi

echo "📦 Empaquetando IPA universal (compatible con AltStore, Sideloadly, TrollStore, SideStore, Scarlet)..."
mkdir -p "$PAYLOAD_DIR"
cp -R "$ARCHIVE_PATH/Products/Applications/StelarIOSApp.app" "$PAYLOAD_DIR/"

# Generar archivo IPA
cd "$BUILD_DIR"
zip -qry "$OUTPUT_IPA" Payload
rm -rf "$PAYLOAD_DIR"

if [ -f "$OUTPUT_IPA" ]; then
    IPA_SIZE=$(du -h "$OUTPUT_IPA" | cut -f1)
    echo "============================================================"
    echo "✅ ¡IPA GENERADA CON ÉXITO!"
    echo "   Ruta: $OUTPUT_IPA"
    echo "   Tamaño: $IPA_SIZE"
    echo "============================================================"
    echo ""
    echo "📱 Cómo instalar la IPA en tu iPhone / iPad:"
    echo "  1. Vía AltStore / SideStore: Envía Stelar.ipa a tu iPhone y ábrelo con AltStore."
    echo "  2. Vía Sideloadly (PC/Mac): Conecta tu iPhone por USB y arrastra Stelar.ipa."
    echo "  3. Vía TrollStore: Si tienes TrollStore, instala Stelar.ipa con un solo toque (firma permanente)."
    echo ""
    echo "🍎 Si deseas firmar con tu cuenta de Desarrollador Oficial de Apple:"
    echo "  Abre StelarIOSApp.xcodeproj en Xcode, selecciona tu Development Team en 'Signing & Capabilities'"
    echo "  y pulsa Product -> Archive -> Distribute App -> Development / App Store."
else
    echo "❌ Error al crear el archivo IPA."
    exit 1
fi
