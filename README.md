# MetroSwap

<a href="https://metroswap-73a05.web.app/">
  <img width="1730" height="1193" alt="image" src="https://github.com/user-attachments/assets/68b46e04-bf03-460f-ab1b-03277c1829d8" />
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

## Credenciales de PayPal de prueba

Ambiente: Sandbox

Usuario: sb-tuscu49992662@personal.example.com
Password: 3L8T%Zmx

Estas credenciales son solo para pruebas y no tienen acceso a datos ni fondos reales.
