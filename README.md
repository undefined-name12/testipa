# Stelar para iOS (iPhone & iPad)

Proyecto nativo en SwiftUI y `WKWebView` para ejecutar Discord móvil con el bundle web completo de Stelar (Vencord + temas + QuickCSS).

No requiere Node.js, pnpm, CocoaPods ni Android Studio. Compatible con iOS 16.0 o superior.

---

## 🚀 Métodos para Generar la IPA

Tienes dos métodos directos para compilar y obtener la IPA de Stelar:

### Método 1: Un Clic / Terminal (Automático - No requiere cuenta de pago)
Genera una IPA lista para instalar vía **AltStore**, **SideStore**, **Sideloadly**, **TrollStore** o **Scarlet**:

1. En macOS, entra en la carpeta `IOS`.
2. Haz doble clic en **`build_ipa.command`** (o ejecuta en terminal `./build_ipa.sh`).
3. El script compilará automáticamente en Release y creará el archivo en:
   ```
   IOS/build/Stelar.ipa
   ```

### Método 2: Desde Xcode (Firma Oficial de Apple)
1. Abre `StelarIOSApp.xcodeproj` en Xcode.
2. Selecciona el esquema **StelarIOSApp** y como destino **Any iOS Device (arm64)**.
3. En la pestaña **Signing & Capabilities**:
   - Marca *Automatically manage signing*.
   - Elige tu **Team** (puede ser tu Apple ID gratuito o cuenta de Apple Developer).
   - Si `com.stelar.ios` está ocupado en tu equipo, cámbialo a un identificador tuyo (ej: `com.tudominio.stelar`).
4. Ve al menú superior: **Product → Archive**.
5. Cuando termine el archivo en el Organizer, pulsa **Distribute App**:
   - Elige **Custom** → **Ad Hoc** o **Development** (o App Store si vas a TestFlight).
   - Pulsa Next hasta finalizar y Xcode guardará tu archivo `Stelar.ipa`.

---

## 📲 Cómo Instalar la IPA en tu Dispositivo

- **AltStore / SideStore:** Comparte `Stelar.ipa` a tu dispositivo (por AirDrop, Telegram, iCloud Drive) y selecciona *Abrir en AltStore*.
- **Sideloadly (Mac / Windows):** Conecta el iPhone por cable USB, abre Sideloadly, arrastra `Stelar.ipa`, introduce tu Apple ID y pulsa Start.
- **TrollStore (iOS 14.0 - 17.0 según versión/jailbreak):** Abre `Stelar.ipa` directamente en TrollStore para instalación permanente sin revocaciones ni límite de 7 días.

---

## 🛠️ Qué Incluye esta Versión iOS

- **Pantalla Completa Nativa (`ignoresSafeArea`):** Se adapta al borde completo de iPhones modernos (Dynamic Island, Notch y barra inferior).
- **Bundle Stelar Completo:** Carga el motor de plugins Vencord, temas y optimizaciones móviles.
- **Editor QuickCSS Integrado:** Botón interactivo para editar, previsualizar y guardar estilos CSS personalizados en caliente.
- **Audio en Segundo Plano (`UIBackgroundModes: audio`):** Mantiene la conexión y el audio de llamadas y canales de voz de Discord incluso con la app en segundo plano.
- **Permisos Completos en Info.plist:**
  - `NSCameraUsageDescription` (cámara para videollamadas).
  - `NSMicrophoneUsageDescription` (micrófono para canales de voz).
  - `NSPhotoLibraryUsageDescription` (acceso a fotos y vídeos para enviar en chats).
  - `NSPhotoLibraryAddUsageDescription` (guardar imágenes adjuntas en la galería).
  - `ITSAppUsesNonExemptEncryption = false` (evita advertencias y bloqueos de cumplimiento de cifrado en Xcode).
  - `NSAppTransportSecurity` (soporte completo para WebSockets y llamadas seguras).
- **Control de Recarga (Pull-to-refresh):** Deslizar hacia abajo permite recargar la vista en caso de desconexión.
- **Enrutamiento Inteligente de Enlaces:** Los enlaces externos compartidos en chats se abren en Safari externo sin cerrar tu sesión de Discord.
- **Soporte de Inspección WebKit (`isInspectable = true`):** En iOS 16.4+, permite conectar Safari Web Inspector en macOS para depuración en vivo de JavaScript y plugins.
