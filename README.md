# MetroSwap

<a href="https://metroswap-73a05.web.app/">
  <img width="1604" height="1145" alt="image" src="https://github.com/user-attachments/assets/292a58d0-2e54-4fc1-96e9-8409a6a4f0aa" />
</a>

Plataforma web y movil para la comunidad de la Universidad Metropolitana que permite publicar, buscar e intercambiar libros y material academico.

## Funcionalidades

- Registro e inicio de sesion con Firebase Auth
- Publicacion de materiales con imagen y descripcion
- Modalidades: intercambio, venta y donacion
- Gestion de intercambios entre usuarios
- Chat, notificaciones y presencia en tiempo real
- Feedback y calificaciones
- Pagos o contribuciones con PayPal (sandbox)

## Tecnologias

- Flutter
- Firebase
  - Authentication
  - Firestore
  - Storage
  - Realtime Database
  - Cloud Functions
  - Hosting
- TypeScript

## Ejecucion local

```bash
flutter pub get
flutter run -d chrome --web-port 5000
```

Nota: para pruebas locales de login web con Google, usar `localhost:5000`.

Demo: https://metroswap-73a05.web.app/
