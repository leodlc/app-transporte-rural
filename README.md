# RutaMóvil

**RutaMóvil** es una aplicación de transporte rural inteligente diseñada para conectar usuarios con servicios de transporte gestionados por cooperativas locales. El sistema está compuesto por un frontend desarrollado en Flutter, un backend construido con Node.js y una base de datos alojada en MongoDB Atlas.

---

## 🚀 Tecnologías utilizadas

- **Frontend:** Flutter (soporte multiplataforma: Android, iOS, Web, etc.)
- **Backend:** Node.js con Express.js
- **Base de datos:** MongoDB Atlas
- **Notificaciones:** Firebase Cloud Messaging
- **Sockets:** Comunicación en tiempo real con Socket.io

---

## 📁 Estructura del proyecto

```
leodlc-app-transporte-rural/
├── documentacion/           # Diagramas de actividades y modelo entidad-relación
├── mobile/                  # Aplicación Flutter
├── server/                  # Servidor Node.js (API REST y sockets)
    └── .env                     # Variables de entorno (en la carpeta server/)
```

---

## ⚙️ Configuración del entorno

### 1. Clonar el repositorio

```bash
git clone https://github.com/usuario/rutamovil.git
cd leodlc-app-transporte-rural
```

### 2. Backend

#### Instalación

```bash
cd server
npm install
```

#### Archivo `.env`

Debe estar en `server/.env` con la siguiente estructura:

```
PORT=3000
MONGO_URI=your_mongodb_atlas_uri
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
```

#### Ejecución

```bash
npm run dev
```

### 3. Frontend

```bash
cd mobile
flutter pub get
flutter run
```

> Asegúrate de tener configurado correctamente tu entorno de desarrollo para Flutter.

---

## 🧪 Pruebas

- Pruebas de socket disponibles en `server/tests/socket-tests/`
- Pruebas de widget en `mobile/test/widget_test.dart`

---

## 📊 Documentación

- Diagramas de actividades: `documentacion/diagramas/Diagrama de actividades.bpm`
- Modelo entidad relación (ER): `RutaMovil_ER.*` (formato PowerDesigner)

---

## 👥 Integrantes del equipo

- Christopher Bazurto
- Stephen Drouet
- Leonardo de la Cadena
- Ricardo Rivadeneira
- Andy Pilozo

---

## 📌 Notas

- Este proyecto está en desarrollo activo.
- Se recomienda utilizar cuentas Firebase y MongoDB propias para pruebas locales.

---

## 📄 Licencia

Este proyecto es de uso académico. Para fines comerciales, contactar a los autores.
