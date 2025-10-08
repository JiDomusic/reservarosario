# 🚀 DEPLOY INSTRUCTIONS - SODITA Firebase Hosting

## 📋 Pre-requisitos

1. **Instalar Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login a Firebase:**
   ```bash
   firebase login
   ```

## 🔥 Deploy a Firebase Hosting

### 1. Build la aplicación (ya completado)
```bash
flutter build web --release
```

### 2. Deploy a Firebase Hosting
```bash
firebase deploy --only hosting
```

### 3. Ver tu app desplegada
Una vez completado el deploy, tu app estará disponible en:
**https://sodita-314e6.firebaseapp.com**

## 📊 Firebase Analytics Configurado

La app incluye los siguientes eventos de Analytics:

- `select_table` - Cuando un usuario selecciona una mesa
- `reservation_completed` - Cuando se completa una reserva (BD o fallback)
- `whatsapp_confirmation_sent` - Cuando se envía confirmación por WhatsApp

## 🛠️ Comandos útiles

### Deploy solo hosting:
```bash
firebase deploy --only hosting
```

### Ver logs:
```bash
firebase functions:log
```

### Configurar dominio personalizado:
```bash
firebase hosting:channel:deploy preview
```

## 📁 Estructura de archivos

- `firebase.json` - Configuración de hosting
- `.firebaserc` - Proyecto de Firebase
- `lib/firebase_options.dart` - Configuración de Firebase
- `build/web/` - Archivos compilados para hosting

## 🌐 URL de la aplicación

**Producción:** https://sodita-314e6.firebaseapp.com
**Analytics:** https://console.firebase.google.com/project/sodita-314e6/analytics

## 🔧 Troubleshooting

Si hay problemas con el deploy:

1. Verificar que estás logueado:
   ```bash
   firebase projects:list
   ```

2. Verificar el build:
   ```bash
   ls -la build/web/
   ```

3. Re-deploy:
   ```bash
   firebase deploy --only hosting --force
   ```