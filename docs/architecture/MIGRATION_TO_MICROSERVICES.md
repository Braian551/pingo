# Guía de Migración a Microservicios

## 📋 Índice
1. [¿Cuándo Migrar?](#cuándo-migrar)
2. [Servicios Propuestos](#servicios-propuestos)
3. [Plan de Migración Paso a Paso](#plan-de-migración-paso-a-paso)
4. [Configuración Técnica](#configuración-técnica)
5. [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)

---

## ¿Cuándo Migrar?

### ✅ Señales para Considerar Microservicios

Migra a microservicios cuando detectes estas señales:

1. **Escalabilidad Desigual**
   - Ejemplo: El servicio de mapas recibe 10x más requests que otros
   - Solución: Separar y escalar solo el servicio de mapas

2. **Equipos Grandes**
   - Más de 5-10 desarrolladores trabajando en el mismo código
   - Conflictos frecuentes en Git, merges complicados

3. **Necesidades Tecnológicas Diferentes**
   - Ejemplo: IA para rutas óptimas requiere Python, pero el resto está en Dart/PHP
   - Microservicios permiten stacks heterogéneos

4. **Despliegues Riesgosos**
   - Cambiar una feature pequeña requiere redesplegar toda la app
   - Miedo a romper funcionalidades no relacionadas

5. **Alta Demanda/Tráfico**
   - Más de 100,000 usuarios activos concurrentes
   - Necesidad de alta disponibilidad (99.9% uptime)

### ❌ NO Migres Si:
- ❌ El proyecto es una demo o MVP
- ❌ Equipo pequeño (1-3 devs)
- ❌ Bajo tráfico (menos de 10k usuarios/mes)
- ❌ Presupuesto limitado (microservicios requieren más infraestructura)

**Para Ping Go**: Actualmente es una demo para un pueblo pequeño → **Mantener monolito modular**. Revisar esta decisión si el proyecto escala a nivel nacional.

---

## Servicios Propuestos

### Arquitectura Objetivo

```
┌─────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY                                  │
│                   (Kong / NGINX / AWS API Gateway)                   │
│                   https://api.pingo.com                              │
└─────────────┬───────────────────────────────────────────────────────┘
              │
              ├─── /auth-service/v1/*         → Auth Service (8001)
              ├─── /conductor-service/v1/*    → Conductor Service (8002)
              ├─── /passenger-service/v1/*    → Passenger Service (8003)
              ├─── /map-service/v1/*          → Map Service (8004)
              ├─── /payment-service/v1/*      → Payment Service (8005)
              ├─── /notification-service/v1/* → Notification Service (8006)
              └─── /admin-service/v1/*        → Admin Service (8007)
```

### Servicios Detallados

#### 1. **Auth Service** (Autenticación y Autorización)
- **Responsabilidad**: Login, registro, tokens JWT, refresh tokens
- **Endpoints**:
  - `POST /auth/login`
  - `POST /auth/register`
  - `POST /auth/refresh-token`
  - `POST /auth/logout`
- **Base de datos**: PostgreSQL (`auth_db`)
  - Tablas: `users`, `tokens`, `sessions`
- **Stack sugerido**: Dart (shelf/aqueduct) o Node.js (Express + Passport)

#### 2. **Conductor Service** (Gestión de Conductores)
- **Responsabilidad**: Perfiles, licencias, vehículos, verificación
- **Endpoints**:
  - `GET /conductors/{id}/profile`
  - `PUT /conductors/{id}/profile`
  - `POST /conductors/{id}/license`
  - `POST /conductors/{id}/vehicle`
  - `POST /conductors/{id}/submit-approval`
- **Base de datos**: PostgreSQL (`conductor_db`)
  - Tablas: `conductor_profiles`, `driver_licenses`, `vehicles`
- **Stack sugerido**: Dart (backend nativo) o Go (alta concurrencia)

#### 3. **Passenger Service** (Gestión de Pasajeros)
- **Responsabilidad**: Perfiles de pasajeros, historial de viajes
- **Endpoints**:
  - `GET /passengers/{id}/profile`
  - `PUT /passengers/{id}/profile`
  - `GET /passengers/{id}/trip-history`
- **Base de datos**: PostgreSQL (`passenger_db`)

#### 4. **Map Service** (Mapas y Geolocalización)
- **Responsabilidad**: Geocoding, rutas, ubicaciones en tiempo real
- **Endpoints**:
  - `POST /map/geocode` (dirección → coordenadas)
  - `POST /map/reverse-geocode` (coordenadas → dirección)
  - `POST /map/route` (calcular ruta entre puntos)
  - `POST /map/track-location` (actualizar ubicación en tiempo real)
- **Base de datos**: 
  - Redis (cache de geocoding, sesiones de ubicación)
  - PostgreSQL (historial de rutas)
- **Stack sugerido**: Python (Flask + integración con Mapbox/Google Maps) o Node.js

#### 5. **Payment Service** (Pagos y Transacciones)
- **Responsabilidad**: Procesar pagos, balances, historial de transacciones
- **Endpoints**:
  - `POST /payments/process`
  - `GET /payments/{id}/balance`
  - `GET /payments/{id}/transactions`
- **Base de datos**: PostgreSQL (`payment_db`)
- **Integración**: Stripe, MercadoPago, PayPal
- **Stack sugerido**: Java/Spring Boot o .NET (alta seguridad)

#### 6. **Notification Service** (Notificaciones)
- **Responsabilidad**: Push notifications, emails, SMS
- **Endpoints**:
  - `POST /notifications/send-push`
  - `POST /notifications/send-email`
  - `POST /notifications/send-sms`
- **Base de datos**: MongoDB (logs de notificaciones)
- **Integración**: Firebase Cloud Messaging, SendGrid, Twilio
- **Stack sugerido**: Node.js (manejo asíncrono)

#### 7. **Admin Service** (Panel de Administración)
- **Responsabilidad**: Gestión de usuarios, auditoría, estadísticas
- **Endpoints**:
  - `GET /admin/users`
  - `PUT /admin/users/{id}/approve`
  - `GET /admin/audit-logs`
  - `GET /admin/statistics`
- **Base de datos**: PostgreSQL (`admin_db`)

---

## Plan de Migración Paso a Paso

### Fase 1: Preparación (2-4 semanas)

#### 1.1 Auditoría del Código Actual
- ✅ **YA HECHO**: Estructura con Clean Architecture
- ✅ Verificar dependencias entre módulos
- 📝 Documentar APIs internas (qué llama a qué)

#### 1.2 Definir Límites de Servicios
- Mapear features actuales a servicios:
  ```
  lib/src/features/conductor/ → Conductor Service
  lib/src/features/auth/      → Auth Service
  lib/src/features/map/       → Map Service
  ```

#### 1.3 Configurar Infraestructura Base
- Instalar Docker y Docker Compose
- Configurar repositorios Git por servicio:
  ```
  github.com/pingo/conductor-service
  github.com/pingo/auth-service
  github.com/pingo/map-service
  ```

---

### Fase 2: Extracción del Primer Servicio (4-6 semanas)

**Recomendación**: Empezar con el servicio **menos crítico** (ej. Notification Service) para ganar experiencia.

#### 2.1 Crear Estructura del Servicio

```bash
# Crear repo del servicio
mkdir conductor-service
cd conductor-service

# Estructura básica (Dart + Shelf)
conductor-service/
├── bin/
│   └── server.dart         # Punto de entrada
├── lib/
│   ├── domain/             # Copiar de lib/src/features/conductor/domain/
│   ├── data/               # Copiar de lib/src/features/conductor/data/
│   ├── presentation/       # APIs REST
│   │   ├── routes/
│   │   │   └── conductor_routes.dart
│   │   └── handlers/
│   │       └── conductor_handler.dart
│   └── core/
│       └── config.dart     # Configuración del servicio
├── test/
├── pubspec.yaml
├── Dockerfile
└── docker-compose.yml
```

#### 2.2 Implementar API REST

**Ejemplo**: `conductor_routes.dart`
```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../handlers/conductor_handler.dart';

class ConductorRoutes {
  final ConductorHandler handler;

  ConductorRoutes(this.handler);

  Router get router {
    final router = Router();

    router.get('/v1/conductors/<id>/profile', handler.getProfile);
    router.put('/v1/conductors/<id>/profile', handler.updateProfile);
    router.post('/v1/conductors/<id>/license', handler.updateLicense);
    router.post('/v1/conductors/<id>/vehicle', handler.updateVehicle);
    router.post('/v1/conductors/<id>/submit-approval', handler.submitApproval);

    return router;
  }
}
```

**Ejemplo**: `conductor_handler.dart`
```dart
import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../../domain/usecases/get_conductor_profile.dart';

class ConductorHandler {
  final GetConductorProfile getConductorProfile;
  // Otros use cases...

  ConductorHandler(this.getConductorProfile);

  Future<Response> getProfile(Request request, String id) async {
    try {
      final conductorId = int.parse(id);
      final result = await getConductorProfile(conductorId);

      return result.when(
        success: (profile) => Response.ok(
          jsonEncode({'success': true, 'profile': profile.toJson()}),
          headers: {'Content-Type': 'application/json'},
        ),
        error: (failure) => Response(
          failure.code ?? 500,
          body: jsonEncode({'success': false, 'message': failure.message}),
          headers: {'Content-Type': 'application/json'},
        ),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': e.toString()}),
      );
    }
  }

  // Otros handlers...
}
```

#### 2.3 Dockerizar el Servicio

**Dockerfile**:
```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

EXPOSE 8002
CMD ["/app/bin/server"]
```

**docker-compose.yml** (para desarrollo local):
```yaml
version: '3.8'

services:
  conductor-service:
    build: .
    ports:
      - "8002:8002"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/conductor_db
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres

  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: conductor_db
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - conductor_db_data:/var/lib/postgresql/data

volumes:
  conductor_db_data:
```

#### 2.4 Separar Base de Datos

**Estrategia**:
1. Crear nueva BD: `conductor_db`
2. Migrar esquema:
   ```sql
   -- Copiar estructura de tablas
   CREATE TABLE conductor_profiles (...);
   CREATE TABLE driver_licenses (...);
   CREATE TABLE vehicles (...);
   ```
3. Migrar datos:
   ```sql
   INSERT INTO conductor_db.conductor_profiles
   SELECT * FROM pingo_db.conductor_profiles;
   ```

#### 2.5 Actualizar Flutter App

**Antes** (llamada directa al monolito):
```dart
static const String baseUrl = 'http://10.0.2.2/pingo/backend/conductor';
```

**Después** (llamada al microservicio):
```dart
static const String baseUrl = 'http://10.0.2.2:8002/v1/conductors';
```

O mejor, usar API Gateway:
```dart
static const String baseUrl = 'http://api-gateway.com/conductor-service/v1/conductors';
```

---

### Fase 3: Repetir para Otros Servicios (8-12 semanas)

Repetir **Fase 2** para cada servicio, en orden de prioridad:
1. ✅ Conductor Service (primero)
2. Auth Service (crítico, moverlo temprano)
3. Map Service
4. Passenger Service
5. Payment Service
6. Notification Service
7. Admin Service

---

### Fase 4: Implementar API Gateway (2-3 semanas)

#### Opción 1: Kong (Open Source)
```yaml
# docker-compose.yml con Kong
version: '3.8'

services:
  kong:
    image: kong:latest
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
      KONG_PG_PASSWORD: kong
    ports:
      - "8000:8000"   # Proxy
      - "8001:8001"   # Admin API
    depends_on:
      - kong-database

  kong-database:
    image: postgres:14
    environment:
      POSTGRES_DB: kong
      POSTGRES_USER: kong
      POSTGRES_PASSWORD: kong
```

Configurar rutas en Kong:
```bash
# Ruta para conductor-service
curl -i -X POST http://localhost:8001/services/ \
  --data name=conductor-service \
  --data url='http://conductor-service:8002'

curl -i -X POST http://localhost:8001/services/conductor-service/routes \
  --data 'paths[]=/conductor-service' \
  --data 'strip_path=true'
```

#### Opción 2: NGINX (Más simple)
```nginx
# nginx.conf
http {
  upstream conductor_service {
    server conductor-service:8002;
  }

  upstream auth_service {
    server auth-service:8001;
  }

  server {
    listen 80;

    location /conductor-service/ {
      proxy_pass http://conductor_service/;
    }

    location /auth-service/ {
      proxy_pass http://auth_service/;
    }
  }
}
```

---

### Fase 5: Comunicación Entre Servicios (2-4 semanas)

#### Patrón: Coreografía con Message Queue

**Ejemplo**: Cuando un conductor es aprobado, notificar al servicio de pagos.

1. **Conductor Service** emite evento:
```dart
// Después de aprobar conductor
await messageQueue.publish(
  topic: 'conductor.approved',
  message: jsonEncode({'conductor_id': id, 'timestamp': DateTime.now()}),
);
```

2. **Payment Service** escucha evento:
```dart
messageQueue.subscribe('conductor.approved', (message) async {
  final data = jsonDecode(message);
  final conductorId = data['conductor_id'];
  
  // Crear cuenta de pagos para el conductor
  await createPaymentAccount(conductorId);
});
```

**Tecnologías**:
- **RabbitMQ** (simple, fácil de configurar)
- **Apache Kafka** (alto rendimiento, logs persistentes)
- **AWS SQS** (cloud-native)

---

### Fase 6: Monitoreo y Observabilidad (Ongoing)

#### Herramientas Esenciales:

1. **Logging Centralizado**: ELK Stack (Elasticsearch, Logstash, Kibana)
   ```yaml
   # docker-compose.yml
   elasticsearch:
     image: elasticsearch:8.0.0
   
   logstash:
     image: logstash:8.0.0
   
   kibana:
     image: kibana:8.0.0
     ports:
       - "5601:5601"
   ```

2. **Métricas**: Prometheus + Grafana
   ```yaml
   prometheus:
     image: prom/prometheus
     ports:
       - "9090:9090"
   
   grafana:
     image: grafana/grafana
     ports:
       - "3000:3000"
   ```

3. **Tracing Distribuido**: Jaeger
   ```yaml
   jaeger:
     image: jaegertracing/all-in-one
     ports:
       - "16686:16686"
   ```

---

## Configuración Técnica

### Manejo de Autenticación (JWT)

1. **Auth Service** emite tokens JWT:
```dart
final token = JWT(
  payload: {
    'user_id': user.id,
    'role': user.role,
    'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
  },
  secret: SecretKey('your-secret-key'),
);
```

2. **Otros servicios** validan tokens:
```dart
// Middleware en cada servicio
Middleware validateJWT() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader == null) {
        return Response.unauthorized('Token requerido');
      }

      try {
        final token = authHeader.replaceFirst('Bearer ', '');
        final jwt = JWT.verify(token, SecretKey('your-secret-key'));
        
        // Agregar info del usuario al request context
        return innerHandler(request.change(context: {'user': jwt.payload}));
      } catch (e) {
        return Response.forbidden('Token inválido');
      }
    };
  };
}
```

---

### Manejo de Transacciones Distribuidas

**Problema**: ¿Qué pasa si conductor-service aprueba un conductor, pero payment-service falla al crear la cuenta?

**Solución**: Patrón **Saga**

#### Saga Coreografiada:
```
1. Conductor Service → Aprobar conductor
2. Emitir evento: conductor.approved
3. Payment Service escucha → Crear cuenta
   ├── Éxito: Emitir payment.account.created
   └── Fallo: Emitir payment.account.failed
4. Conductor Service escucha payment.account.failed
   → Revertir aprobación (compensación)
```

#### Implementación:
```dart
// En conductor service
await messageQueue.subscribe('payment.account.failed', (message) async {
  final data = jsonDecode(message);
  final conductorId = data['conductor_id'];
  
  // Compensar: revertir aprobación
  await revertApproval(conductorId);
  print('Aprobación revertida para conductor $conductorId');
});
```

---

## Monitoreo y Observabilidad

### Dashboards Críticos

#### 1. **Health Checks**
Cada servicio debe exponer `/health`:
```dart
router.get('/health', (Request request) {
  return Response.ok(jsonEncode({
    'status': 'healthy',
    'service': 'conductor-service',
    'version': '1.0.0',
    'timestamp': DateTime.now().toIso8601String(),
  }));
});
```

#### 2. **Métricas de Negocio**
- Conductores aprobados/día
- Tiempo promedio de verificación
- Tasa de rechazos

#### 3. **Métricas Técnicas**
- Latencia de requests (p50, p95, p99)
- Tasa de errores (4xx, 5xx)
- Uso de recursos (CPU, RAM, disco)

---

## Checklist de Migración

### Antes de Migrar un Servicio
- [ ] Auditar dependencias con otros módulos
- [ ] Definir API contract (OpenAPI/Swagger)
- [ ] Configurar base de datos separada
- [ ] Escribir tests de integración
- [ ] Preparar plan de rollback

### Durante la Migración
- [ ] Desplegar servicio en paralelo al monolito
- [ ] Usar feature flags para switchear entre monolito/microservicio
- [ ] Monitorear métricas de performance
- [ ] Validar funcionalidad end-to-end

### Después de Migrar
- [ ] Eliminar código del monolito
- [ ] Actualizar documentación
- [ ] Configurar alertas
- [ ] Entrenar equipo en nuevo servicio

---

## Recursos y Referencias

- [Microservices.io - Patterns](https://microservices.io/patterns/)
- [Martin Fowler - Microservices](https://martinfowler.com/articles/microservices.html)
- [Kong API Gateway Docs](https://docs.konghq.com/)
- [Saga Pattern Explained](https://microservices.io/patterns/data/saga.html)

---

**Última actualización**: Octubre 2025  
**Autor**: Equipo Ping Go  
**Versión**: 1.0.0
