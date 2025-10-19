# ping_go

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.
## Backend local - endpoints de utilidad

Durante desarrollo el backend PHP está en `pingo/backend/` y los endpoints relevantes son:

- `pingo/backend/auth/register.php`  (POST): registrar usuario. Acepta JSON con campos:
	- email, password, name, lastName, phone
	- address (opcional), lat/lng o latitude/longitude, city, state, country, postal_code, is_primary
	Responde JSON { success: bool, message: string, data: { user: {...}, location: {...} } }

- `pingo/backend/auth/profile.php` (GET): obtener perfil por `userId` o `email` en query string.
	Ejemplo: `http://localhost/pingo/backend/auth/profile.php?email=foo@bar.com`

Si usas el emulador Android, desde Flutter usa `http://10.0.2.2/pingo/backend/auth/...` como base.

Prueba rápida con curl (ajusta host/puerto según tu servidor local):

curl -X POST http://localhost/pingo/backend/auth/register.php -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"pass123","name":"Test","lastName":"User","phone":"3001234567","address":"Calle 123","lat":4.711,"lng":-74.072}'


A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
