# 💸 PresuCompra

> Control de compras y presupuestos en USD y Bolívares. 100% offline. Hecho para Venezuela.

<p align="center">
  <img src="assets/images/Presucompra-sin-fondo.png" alt="PresuCompra Logo" width="140"/>
</p>

<p align="center">
  <a href="https://presucompra.netlify.app">
    <img src="https://img.shields.io/badge/Landing%20Page-presucompra.netlify.app-00FF87?style=for-the-badge&logo=netlify&logoColor=black" alt="Landing Page"/>
  </a>
  <a href="https://github.com/luigi1501/presucompra/releases/latest">
    <img src="https://img.shields.io/badge/Descargar%20APK-v1.0-00FF87?style=for-the-badge&logo=android&logoColor=black" alt="Descargar APK"/>
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.47-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Offline-100%25-00FF87?style=for-the-badge" alt="Offline"/>
  <img src="https://img.shields.io/badge/Venezuela-🇻🇪-CF142B?style=for-the-badge" alt="Venezuela"/>
</p>

---

## ¿Qué es PresuCompra?

**PresuCompra** es una aplicación móvil nativa para Android que te permite controlar tus compras del día a día con presupuestos en dólares y bolívares, pensada 100% para el mercado venezolano.

No necesitas internet. No necesitas registrarte. Funciona de inmediato.

---

## ✨ Funcionalidades Principales

| Función | Descripción |
|---|---|
| 💵 **Calculadora de Caja y Vuelto Mixto** | Calcula cuánto pagas en efectivo USD y cuánto completas en Pago Móvil Bs., con la tasa BCV exacta. |
| 🏛️ **Presupuestos Múltiples** | Crea fondos independientes por categoría (Mercado, Farmacia, Ropa, etc.) con límites propios. |
| 🧠 **Memoria de Precios** | Recuerda el precio anterior de cada producto y te avisa si subió (detector de inflación). |
| 🧾 **Recibos Digitales** | Finaliza la compra y guarda un recibo con la fecha, la tasa del día y el desglose completo. |
| 📡 **Tasa BCV en Vivo** | Consulta la tasa oficial del BCV al abrir la app (con fallback offline si no hay internet). |
| 🌙 **100% Offline** | Toda la data se guarda localmente con SQLite. Sin servidores, sin nube, sin registro. |

---

## 📱 Instalación del APK

> PresuCompra se distribuye directamente como APK. No está en Google Play Store.

1. Descarga el APK desde la sección [**Releases**](https://github.com/luigi1501/presucompra/releases/latest)
2. En tu Android ve a **Ajustes → Seguridad → Instalar apps desconocidas** y actívalo para tu navegador
3. Abre el archivo `.apk` descargado e instala
4. El aviso de **Play Protect** es normal para cualquier APK fuera de Play Store — la app no tiene permisos invasivos

---

## 🛠️ Stack Tecnológico

- **Framework:** Flutter 3.47.9 / Dart 3.13.7
- **Base de datos local:** SQLite (`sqflite` + `sqlite3_flutter_libs`)
- **Gestión de estado:** `provider`
- **Tasa de cambio:** API pública de [ve.dolarapi.com](https://ve.dolarapi.com) (solo para consulta opcional)
- **Compartir recibos:** `share_plus`
- **Target:** Android 5.0+ (API 21+)

---

## 🗂️ Estructura del Proyecto

```
lib/
├── data/
│   ├── datasources/      # database_helper.dart (SQLite)
│   └── models/           # Modelos de datos
├── providers/            # BudgetProvider (estado global)
└── presentation/
    ├── screens/          # HomeScreen, etc.
    └── widgets/          # Modales, loaders, componentes UI

landing/                  # Landing Page oficial (HTML/CSS/JS)
android/                  # Configuración nativa Android
assets/                   # Imágenes y recursos de la app
```

---

## 🚀 Compilar desde el Código Fuente

```powershell
# Requisitos: Flutter 3.47+, Android SDK con NDK 28.2.13676358

# Clonar el repo
git clone https://github.com/luigi1501/presucompra.git
cd presucompra

# Instalar dependencias
flutter pub get

# Correr en modo desarrollo
flutter run

# Compilar APK de Release
flutter build apk --release
# El APK queda en: build\app\outputs\flutter-apk\app-release.apk
```

---

## 🌐 Landing Page

Sitio web oficial en producción: **[presucompra.netlify.app](https://presucompra.netlify.app/)**

La carpeta `landing/` contiene el código fuente de la página web oficial del proyecto (HTML, CSS y JS puro con simulador bimonetario interactivo).

---

## 📄 Licencia

Este proyecto es de uso personal y educativo. Todos los derechos reservados © 2026 PresuCompra.

---

<p align="center">Hecho con ❤️ para Venezuela 🇻🇪</p>
