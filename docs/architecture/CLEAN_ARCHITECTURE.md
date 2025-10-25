# Clean Architecture - Ping Go

## 📋 Índice
1. [Introducción](#introducción)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Capas de la Arquitectura](#capas-de-la-arquitectura)
4. [Flujo de Datos](#flujo-de-datos)
5. [Preparación para Microservicios](#preparación-para-microservicios)
6. [Guías de Implementación](#guías-de-implementación)

---

## Introducción

Este proyecto implementa **Clean Architecture** (Arquitectura Limpia) propuesta por Robert C. Martin (Uncle Bob). Esta arquitectura separa el código en capas con responsabilidades bien definidas, facilitando:

- ✅ **Mantenibilidad**: Código organizado y fácil de entender
- ✅ **Testabilidad**: Cada capa se puede testear independientemente
- ✅ **Escalabilidad**: Fácil agregar nuevas features sin romper el código existente
- ✅ **Independencia de frameworks**: La lógica de negocio no depende de Flutter, APIs, o BDs
- ✅ **Migración a microservicios**: Preparado para evolucionar a arquitectura distribuida

---

## Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada
├── src/
│   ├── core/                          # Código compartido entre features
│   │   ├── config/
│   │   │   └── app_config.dart        # Configuración centralizada (URLs, constantes)
│   │   ├── di/
│   │   │   └── service_locator.dart   # Inyección de dependencias
│   │   ├── error/
│   │   │   ├── failures.dart          # Errores de dominio
│   │   │   ├── exceptions.dart        # Excepciones técnicas
│   │   │   └── result.dart            # Tipo Result<T> para manejo funcional de errores
│   │   ├── network/
│   │   │   └── network_info.dart      # Chequeo de conectividad
│   │   └── database/
│   │       └── database_config.dart   # Configuración de BD
│   │
│   ├── features/                      # Módulos por funcionalidad
│   │   ├── conductor/                 # Feature: Conductor
│   │   │   ├── domain/                # 🔵 CAPA DE DOMINIO (Lógica de Negocio Pura)
│   │   │   │   ├── entities/          # Entidades de negocio (inmutables, sin dependencias)
│   │   │   │   │   └── conductor_profile.dart
│   │   │   │   ├── repositories/      # Contratos abstractos (interfaces)
│   │   │   │   │   └── conductor_repository.dart
│   │   │   │   └── usecases/          # Casos de uso (reglas de negocio)
│   │   │   │       ├── get_conductor_profile.dart
│   │   │   │       ├── update_conductor_profile.dart
│   │   │   │       ├── update_driver_license.dart
│   │   │   │       ├── update_vehicle.dart
│   │   │   │       └── submit_profile_for_approval.dart
│   │   │   │
│   │   │   ├── data/                  # 🟢 CAPA DE DATOS (Implementación de persistencia)
│   │   │   │   ├── datasources/       # Fuentes de datos (API, BD local, cache)
│   │   │   │   │   ├── conductor_remote_datasource.dart      # Contrato
│   │   │   │   │   └── conductor_remote_datasource_impl.dart # Implementación HTTP
│   │   │   │   ├── models/            # Modelos de datos (DTOs con serialización)
│   │   │   │   │   └── conductor_profile_model.dart
│   │   │   │   └── repositories/      # Implementación de contratos del dominio
│   │   │   │       └── conductor_repository_impl.dart
│   │   │   │
│   │   │   └── presentation/          # 🟡 CAPA DE PRESENTACIÓN (UI y estado)
│   │   │       ├── providers/         # Gestión de estado (Provider/BLoC)
│   │   │       │   └── conductor_profile_provider_refactored.dart
│   │   │       ├── screens/           # Pantallas (UI pura)
│   │   │       │   ├── conductor_profile_screen.dart
│   │   │       │   ├── conductor_home_screen.dart
│   │   │       │   └── ...
│   │   │       └── widgets/           # Componentes reutilizables
│   │   │           ├── conductor_stats_card.dart
│   │   │           └── ...
│   │   │
│   │   ├── auth/                      # Feature: Autenticación (misma estructura)
│   │   ├── map/                       # Feature: Mapas
│   │   ├── admin/                     # Feature: Administración
│   │   └── ...
│   │
│   ├── routes/                        # Navegación centralizada
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   │
│   └── widgets/                       # Widgets globales compartidos
```

---

## Capas de la Arquitectura

### 🔵 1. Capa de Dominio (Domain Layer)
**Ubicación**: `features/{feature}/domain/`

**Responsabilidad**: Contiene la lógica de negocio pura. **NO** depende de Flutter, APIs, bases de datos o frameworks.

#### Componentes:

1. **Entities (Entidades)**
   - Objetos de negocio inmutables
   - Solo contienen datos y lógica de validación simple
   - Ejemplo: `ConductorProfile`, `DriverLicense`, `Vehicle`

2. **Repositories (Contratos)**
   - Interfaces abstractas que definen operaciones de datos
   - NO implementan nada, solo declaran métodos
   - Ejemplo: `abstract class ConductorRepository`

3. **Use Cases (Casos de Uso)**
   - Encapsulan reglas de negocio específicas
   - Un use case = una acción que el usuario puede realizar
   - Invocan repositorios para obtener/persistir datos
   - Ejemplo: `GetConductorProfile`, `SubmitProfileForApproval`

**Ventajas**:
- ✅ Testeable sin dependencias externas (100% unit tests)
- ✅ Reutilizable en otras plataformas (web, desktop)
- ✅ Independiente de cambios en UI o infraestructura

---

### 🟢 2. Capa de Datos (Data Layer)
**Ubicación**: `features/{feature}/data/`

**Responsabilidad**: Implementa cómo se obtienen y persisten los datos. Conecta con APIs, bases de datos, cache, etc.

#### Componentes:

1. **DataSources (Fuentes de Datos)**
   - Implementaciones concretas de comunicación con servicios externos
   - **Remote**: APIs REST, GraphQL, gRPC
   - **Local**: SQLite, SharedPreferences, Hive
   - Ejemplo: `ConductorRemoteDataSourceImpl` (usa HTTP)

2. **Models (Modelos de Datos)**
   - DTOs (Data Transfer Objects) con serialización JSON
   - Extienden las entidades del dominio
   - Saben cómo convertir entre JSON ↔ Objetos Dart
   - Ejemplo: `ConductorProfileModel.fromJson()`

3. **Repository Implementations**
   - Implementan los contratos del dominio
   - Coordinan datasources (pueden usar múltiples fuentes)
   - Convierten excepciones técnicas en `Failures` de dominio
   - Ejemplo: `ConductorRepositoryImpl`

**Ventajas**:
- ✅ Cambiar de API a BD local sin tocar el dominio
- ✅ Fácil mockear datasources para testing
- ✅ Manejo de errores centralizado

---

### 🟡 3. Capa de Presentación (Presentation Layer)
**Ubicación**: `features/{feature}/presentation/`

**Responsabilidad**: Gestiona UI y estado. Invoca use cases y reacciona a cambios.

#### Componentes:

1. **Providers/BLoC**
   - Gestión de estado de la UI
   - Invocan use cases (NO lógica de negocio aquí)
   - Notifican cambios a widgets
   - Ejemplo: `ConductorProfileProvider`

2. **Screens**
   - Pantallas completas de la app
   - UI pura, sin lógica de negocio
   - Consumen providers/state
   - Ejemplo: `ConductorProfileScreen`

3. **Widgets**
   - Componentes reutilizables de UI
   - Ejemplo: `ConductorStatsCard`, `DriverLicenseCard`

**Ventajas**:
- ✅ Separación clara entre UI y lógica
- ✅ Fácil cambiar de Provider a BLoC/Riverpod
- ✅ Widgets testeables con widget tests

---

## Flujo de Datos

### Ejemplo: Cargar Perfil del Conductor

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERACTION                             │
│                    (Tap en pantalla "Perfil")                        │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                               │
│                                                                      │
│  ConductorProfileScreen                                             │
│    ├── Invoca: provider.loadProfile(conductorId)                   │
│    └── Escucha: Consumer<ConductorProfileProvider>                 │
│                                                                      │
│  ConductorProfileProvider                                           │
│    ├── Gestiona: _isLoading, _profile, _errorMessage               │
│    └── Invoca: getConductorProfileUseCase(conductorId)             │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                                   │
│                                                                      │
│  GetConductorProfile (Use Case)                                     │
│    ├── Lógica: Validar conductorId                                 │
│    └── Invoca: conductorRepository.getProfile(conductorId)         │
│                                                                      │
│  ConductorRepository (Interface)                                    │
│    └── Future<Result<ConductorProfile>> getProfile(int id);        │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                    │
│                                                                      │
│  ConductorRepositoryImpl (Implementación)                           │
│    ├── Invoca: remoteDataSource.getProfile(id)                     │
│    ├── Convierte: Model → Entity                                   │
│    └── Maneja: Exceptions → Failures                               │
│                                                                      │
│  ConductorRemoteDataSourceImpl                                      │
│    ├── HTTP GET: http://api.com/conductor/get_profile.php?id=X     │
│    ├── Recibe: JSON                                                 │
│    └── Retorna: Map<String, dynamic>                               │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                               │
│                   (Backend API / Database)                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Flujo de respuesta:
```
API Response (JSON)
    ↓
ConductorProfileModel.fromJson()  [Data Layer]
    ↓
ConductorProfile (Entity)  [Domain Layer]
    ↓
Result<ConductorProfile>  [Use Case]
    ↓
provider._profile = profile  [Presentation Layer]
    ↓
notifyListeners()
    ↓
UI se actualiza (Consumer rebuild)
```

---

## Preparación para Microservicios

### 🔄 Estado Actual: Monolito Modular

Actualmente, el proyecto es un **monolito modular** bien organizado:
- Un solo backend (PHP en `pingo/backend/`)
- Una sola base de datos
- Módulos separados por features (conductor, auth, map)

**Ventajas**:
- ✅ Simple de desarrollar y desplegar
- ✅ Perfecto para MVP y demos
- ✅ Bajo overhead operacional

---

### 🚀 Migración Futura a Microservicios

La arquitectura actual está **preparada para migrar** sin reescribir todo:

#### 1. **Separación por Dominio (Domain-Driven Design)**
Cada feature (`conductor/`, `auth/`, `map/`) puede convertirse en un microservicio independiente:

```
# Servicios propuestos:
├── conductor-service   (Puerto 8001)
├── auth-service        (Puerto 8002)
├── map-service         (Puerto 8003)
├── payment-service     (Puerto 8004)
└── admin-service       (Puerto 8005)
```

#### 2. **Cambios Mínimos Requeridos**

##### A. Actualizar URLs en DataSources
**Antes (Monolito)**:
```dart
static const String baseUrl = 'http://10.0.2.2/pingo/backend/conductor';
```

**Después (Microservicios)**:
```dart
static const String baseUrl = 'http://api-gateway.pingo.com/conductor-service/v1';
```

##### B. Configuración Centralizada
Usar `AppConfig` para gestionar URLs por servicio:

```dart
// core/config/app_config.dart
class AppConfig {
  static const String apiGateway = 'http://api-gateway.pingo.com';
  
  static const String conductorServiceUrl = '$apiGateway/conductor-service/v1';
  static const String authServiceUrl = '$apiGateway/auth-service/v1';
  static const String mapServiceUrl = '$apiGateway/map-service/v1';
}
```

##### C. API Gateway
Implementar un gateway (Kong, NGINX, AWS API Gateway) que enrute requests:

```
Cliente Flutter App
    ↓
API Gateway (http://api-gateway.pingo.com)
    ├── /conductor-service/* → Conductor Service (8001)
    ├── /auth-service/*      → Auth Service (8002)
    ├── /map-service/*       → Map Service (8003)
    └── /payment-service/*   → Payment Service (8004)
```

#### 3. **Orquestación de Servicios**

Si un use case necesita datos de múltiples servicios, el repositorio los coordina:

```dart
// Ejemplo: Obtener perfil completo con balance de pagos
class ConductorRepositoryImpl implements ConductorRepository {
  final ConductorRemoteDataSource conductorDataSource;
  final PaymentRemoteDataSource paymentDataSource;  // Nuevo

  @override
  Future<Result<ConductorProfile>> getProfile(int conductorId) async {
    try {
      // Llamada paralela a dos microservicios
      final results = await Future.wait([
        conductorDataSource.getProfile(conductorId),
        paymentDataSource.getBalance(conductorId),
      ]);
      
      final profileData = results[0];
      final balanceData = results[1];
      
      // Combinar datos de ambos servicios
      final profile = ConductorProfileModel.fromJson(profileData);
      return Success(profile.copyWith(balance: balanceData['balance']));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
```

#### 4. **Base de Datos por Servicio**

**Estrategia de migración gradual**:

1. **Fase 1**: Base de datos compartida (ACTUAL)
   - Todos los servicios usan la misma BD
   - Esquemas separados por feature (prefijos en tablas)

2. **Fase 2**: Bases de datos separadas
   ```
   conductor-service → PostgreSQL (conductor_db)
   auth-service      → PostgreSQL (auth_db)
   map-service       → Redis (cache de ubicaciones)
   payment-service   → PostgreSQL (payment_db)
   ```

3. **Sincronización**: Usar eventos (Message Queue)
   - RabbitMQ, Apache Kafka, AWS SQS
   - Ejemplo: Cuando se aprueba un conductor, el `conductor-service` emite evento `ConductorApproved`, y el `payment-service` lo escucha para crear cuenta.

---

### 📊 Comparación: Monolito vs Microservicios

| Aspecto | Monolito Modular (Actual) | Microservicios (Futuro) |
|---------|---------------------------|-------------------------|
| **Complejidad** | Baja | Alta |
| **Desarrollo** | Rápido, simple | Requiere coordinación |
| **Despliegue** | Un solo deploy | Deploy independiente por servicio |
| **Escalabilidad** | Vertical (más recursos) | Horizontal (más instancias) |
| **Base de datos** | Una compartida | Una por servicio |
| **Testing** | Fácil | Requiere testing de integración |
| **Recomendado para** | MVP, demos, equipos pequeños | Proyectos grandes, alta escala |

---

## Guías de Implementación

### ✅ Buenas Prácticas

1. **Nunca importar capas superiores en inferiores**
   ```
   ✅ domain/ NO importa data/ ni presentation/
   ✅ data/ puede importar domain/ pero NO presentation/
   ✅ presentation/ puede importar domain/ y usar data/ vía DI
   ```

2. **Usar inyección de dependencias**
   ```dart
   // ❌ MAL: Crear instancias directamente
   final repository = ConductorRepositoryImpl();
   
   // ✅ BIEN: Inyectar dependencias
   final repository = ServiceLocator().conductorRepository;
   ```

3. **Manejar errores con Result<T>**
   ```dart
   // ❌ MAL: Excepciones sin control
   ConductorProfile profile = await getProfile(id);
   
   // ✅ BIEN: Manejo explícito de éxito/error
   final result = await getProfile(id);
   result.when(
     success: (profile) => print(profile.nombreCompleto),
     error: (failure) => print('Error: ${failure.message}'),
   );
   ```

4. **Mantener entidades inmutables**
   ```dart
   // ✅ BIEN: Usar copyWith para "modificar"
   final updatedProfile = profile.copyWith(telefono: '123456789');
   ```

5. **Un use case = una responsabilidad**
   ```dart
   // ✅ BIEN: Use cases específicos
   GetConductorProfile()
   UpdateDriverLicense()
   SubmitProfileForApproval()
   
   // ❌ MAL: Use case genérico
   ManageConductor() // Hace muchas cosas
   ```

---

### 🧪 Testing

#### Domain Layer (Unit Tests)
```dart
test('should calculate completion percentage correctly', () {
  final profile = ConductorProfile(
    id: 1,
    conductorId: 1,
    nombreCompleto: 'Juan',
    telefono: '123',
    direccion: 'Calle 123',
    license: DriverLicense(...),
    vehicle: null, // Falta vehículo
  );
  
  expect(profile.completionPercentage, 80); // 4/5 = 80%
});
```

#### Data Layer (Integration Tests)
```dart
test('should return ConductorProfile when API call is successful', () async {
  // Arrange
  final mockClient = MockClient();
  when(mockClient.get(any)).thenAnswer((_) async => 
    http.Response('{"success": true, "profile": {...}}', 200)
  );
  final dataSource = ConductorRemoteDataSourceImpl(client: mockClient);
  
  // Act
  final result = await dataSource.getProfile(1);
  
  // Assert
  expect(result, isA<Map<String, dynamic>>());
  expect(result['nombre_completo'], 'Juan');
});
```

#### Presentation Layer (Widget Tests)
```dart
testWidgets('should display loading indicator when loading', (tester) async {
  // Arrange
  final provider = ConductorProfileProvider(...);
  provider.loadProfile(1); // Inicia loading
  
  // Act
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: ConductorProfileScreen(conductorId: 1),
    ),
  );
  
  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

### 📚 Recursos Adicionales

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Example](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)
- [Microservices Pattern](https://microservices.io/patterns/microservices.html)
- [API Gateway Pattern](https://microservices.io/patterns/apigateway.html)

---

### 🔗 Documentos Relacionados

- [Guía de Migración a Microservicios](./MIGRATION_TO_MICROSERVICES.md)
- [Configuración de Rutas](./ROUTING_GUIDE.md)
- [Inyección de Dependencias](./DEPENDENCY_INJECTION.md)

---

**Última actualización**: Octubre 2025  
**Autor**: Equipo Ping Go  
**Versión**: 1.0.0
