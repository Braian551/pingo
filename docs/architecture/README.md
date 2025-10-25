# Ping Go - Arquitectura del Proyecto

## 🎯 Visión General

Ping Go es una aplicación de transporte construida con **Clean Architecture**, diseñada para ser mantenible, testeable y preparada para escalar desde un monolito modular hacia microservicios en el futuro.

**Estado Actual**: Demo/MVP para un pueblo pequeño  
**Arquitectura**: Monolito modular con Clean Architecture  
**Preparación**: Lista para migrar a microservicios cuando escale

---

## 📚 Documentación

### Documentos Principales

1. **[Clean Architecture](./CLEAN_ARCHITECTURE.md)** - **LEER PRIMERO**
   - Explicación completa de la arquitectura
   - Estructura de carpetas
   - Flujo de datos
   - Guías de implementación

2. **[Migración a Microservicios](./MIGRATION_TO_MICROSERVICES.md)**
   - Cuándo migrar
   - Plan paso a paso
   - Configuración técnica
   - Servicios propuestos

3. **[Registro de Decisiones Arquitectónicas (ADR)](./ADR.md)**
   - Decisiones clave y justificaciones
   - Alternativas consideradas
   - Consecuencias de cada decisión

---

## 🏗️ Estructura del Proyecto (Simplificada)

```
lib/
├── main.dart
├── src/
│   ├── core/                    # Código compartido
│   │   ├── config/              # Configuración centralizada
│   │   ├── di/                  # Inyección de dependencias
│   │   ├── error/               # Manejo de errores (Failures, Exceptions, Result)
│   │   ├── network/             # Utilidades de red
│   │   └── database/            # Configuración de BD
│   │
│   ├── features/                # Módulos por funcionalidad
│   │   ├── conductor/           # Feature: Conductor
│   │   │   ├── domain/          # 🔵 Lógica de negocio pura
│   │   │   │   ├── entities/    # Entidades (ConductorProfile, DriverLicense, Vehicle)
│   │   │   │   ├── repositories/# Contratos abstractos
│   │   │   │   └── usecases/    # Casos de uso (reglas de negocio)
│   │   │   ├── data/            # 🟢 Implementación de persistencia
│   │   │   │   ├── datasources/ # APIs, BD (remote/local)
│   │   │   │   ├── models/      # DTOs con serialización JSON
│   │   │   │   └── repositories/# Implementación de contratos
│   │   │   └── presentation/    # 🟡 UI y estado
│   │   │       ├── providers/   # Gestión de estado (Provider)
│   │   │       ├── screens/     # Pantallas (UI pura)
│   │   │       └── widgets/     # Componentes reutilizables
│   │   ├── auth/                # Feature: Autenticación
│   │   ├── map/                 # Feature: Mapas
│   │   └── admin/               # Feature: Administración
│   │
│   ├── routes/                  # Navegación centralizada
│   └── widgets/                 # Widgets globales
│
└── docs/architecture/           # Esta documentación
```

---

## 🎨 Principios de Arquitectura

### 1. Separación de Capas
```
┌───────────────────────────────────────┐
│      Presentation Layer (UI)          │  ← Flutter widgets, providers
├───────────────────────────────────────┤
│      Domain Layer (Business Logic)    │  ← Entidades, use cases (PURO)
├───────────────────────────────────────┤
│      Data Layer (Implementation)      │  ← APIs, BD, cache
└───────────────────────────────────────┘
```

**Regla de Dependencia**: Las capas internas NO conocen las externas
- ✅ Domain NO depende de Data ni Presentation
- ✅ Data depende de Domain (implementa contratos)
- ✅ Presentation depende de Domain (usa use cases)

### 2. Inversión de Dependencias
```dart
// ❌ MAL: Dependencia directa
class ConductorScreen {
  final api = ConductorAPI(); // Acoplamiento fuerte
}

// ✅ BIEN: Inyección de dependencia + contrato
class ConductorScreen {
  final GetConductorProfile useCase; // Depende de abstracción
  ConductorScreen(this.useCase);
}
```

### 3. Manejo de Errores Funcional
```dart
// Usa Result<T> en lugar de excepciones
final result = await getConductorProfile(id);

result.when(
  success: (profile) => print(profile.nombreCompleto),
  error: (failure) => print('Error: ${failure.message}'),
);
```

---

## 🚀 Flujo de Datos (Ejemplo)

### Cargar Perfil del Conductor

```
1. USER toca "Ver Perfil" en UI
       ↓
2. ConductorProfileScreen invoca:
   provider.loadProfile(conductorId)
       ↓
3. ConductorProfileProvider ejecuta:
   getConductorProfileUseCase(conductorId)
       ↓
4. GetConductorProfile (use case) llama:
   conductorRepository.getProfile(conductorId)
       ↓
5. ConductorRepositoryImpl coordina:
   - Llama remoteDataSource.getProfile()
   - Convierte JSON → Model → Entity
   - Maneja errores → Failures
       ↓
6. ConductorRemoteDataSourceImpl hace:
   HTTP GET → Backend API → JSON response
       ↓
7. Respuesta regresa por las capas:
   JSON → Model → Entity → Use Case → Provider
       ↓
8. Provider notifica cambio (notifyListeners)
       ↓
9. UI se actualiza (Consumer rebuild)
```

---

## 🔧 Preparación para Microservicios

### Estado Actual: Monolito Modular
- ✅ Un solo backend
- ✅ Una base de datos compartida
- ✅ Código organizado en features independientes

### Ventajas de la Arquitectura Actual
1. **Modularidad**: Cada feature puede convertirse en un servicio
2. **Contratos claros**: Repositories definen APIs internas
3. **Abstracciones**: Datasources se pueden cambiar sin tocar dominio
4. **Configuración centralizada**: URLs fáciles de cambiar

### Migración Futura (cuando escale)
```
Monolito actual:
┌─────────────────────────────────────────┐
│         Backend PHP (monolito)          │
│  /conductor  /auth  /map  /admin        │
└─────────────────────────────────────────┘

Microservicios (futuro):
┌─────────────────────────────────────────┐
│           API Gateway                    │
├───────┬────────┬────────┬────────────────┤
│Conduc │ Auth   │ Map    │ Payment │Admin │
│tor    │Service │Service │Service  │Service
│Service│        │        │         │      │
└───────┴────────┴────────┴─────────┴──────┘
```

**Cambio necesario**: Actualizar URLs en `AppConfig`
```dart
// Antes
static const baseUrl = 'http://api.com/backend';

// Después
static const conductorServiceUrl = 'http://api.com/conductor-service/v1';
static const authServiceUrl = 'http://api.com/auth-service/v1';
```

---

## 📊 Decisiones Clave

### ¿Por qué Clean Architecture?
- ✅ Código mantenible y testeable
- ✅ Preparado para escalar sin reescribir
- ✅ Independiente de frameworks
- Ver [ADR-001](./ADR.md#adr-001-implementación-de-clean-architecture)

### ¿Por qué Monolito Ahora?
- ✅ Simple para demo/MVP
- ✅ Equipo pequeño, recursos limitados
- ✅ Suficiente para proyecto de pueblo
- Ver [ADR-003](./ADR.md#adr-003-monolito-modular-como-estado-inicial)

### ¿Cuándo Migrar a Microservicios?
**Solo si**:
- Más de 50,000 usuarios activos
- Necesidad de escalar servicios independientemente
- Equipos grandes (10+ devs)
- Tecnologías heterogéneas (ej. Python para IA)

Ver [Guía de Migración](./MIGRATION_TO_MICROSERVICES.md)

---

## 🧪 Testing

### Estrategia de Testing

```
┌─────────────────────────────────────────────────┐
│  Unit Tests (Domain Layer)                      │
│  - Entidades: Lógica de validación             │
│  - Use Cases: Reglas de negocio                │
│  ✅ 100% cobertura posible (sin dependencias)   │
└─────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────┐
│  Integration Tests (Data Layer)                 │
│  - Repositories con datasources mockeados       │
│  - Conversión Model ↔ Entity                   │
└─────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────┐
│  Widget Tests (Presentation Layer)              │
│  - Screens con providers mockeados              │
│  - Interacciones de usuario                     │
└─────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────┐
│  E2E Tests (Full Flow)                          │
│  - Flujos completos de usuario                  │
│  - Backend real o mockeado                      │
└─────────────────────────────────────────────────┘
```

### Ejemplo: Unit Test
```dart
test('should calculate profile completion correctly', () {
  final profile = ConductorProfile(
    id: 1,
    conductorId: 1,
    nombreCompleto: 'Juan',
    telefono: null, // Falta teléfono
    direccion: 'Calle 123',
    license: DriverLicense(...),
    vehicle: Vehicle(...),
  );

  expect(profile.completionPercentage, 80); // 4/5 campos = 80%
});
```

---

## 🛠️ Herramientas y Tecnologías

### Frontend (Flutter)
- **UI Framework**: Flutter 3.x
- **Gestión de Estado**: Provider (migratable a Riverpod/BLoC)
- **Networking**: http package
- **Routing**: Custom router con named routes

### Backend (Actual)
- **Lenguaje**: PHP
- **Base de Datos**: MySQL/PostgreSQL (compartida)
- **API**: REST

### Backend (Futuro - Microservicios)
- **Lenguajes**: Dart (shelf), Go, Python, Node.js (según servicio)
- **Bases de Datos**: PostgreSQL, Redis, MongoDB (por servicio)
- **Comunicación**: REST + Message Queue (RabbitMQ/Kafka)
- **API Gateway**: Kong / NGINX
- **Containerización**: Docker + Docker Compose
- **Orquestación**: Kubernetes (opcional, para producción)

---

## 📈 Roadmap de Arquitectura

### Fase 1: MVP/Demo (Actual) ✅
- [x] Clean Architecture implementada
- [x] Monolito modular funcional
- [x] Features básicas (conductor, auth, map)
- [x] Documentación completa

### Fase 2: Escalamiento Vertical (Si crece)
- [ ] Optimizar queries de BD
- [ ] Implementar cache (Redis)
- [ ] Mejorar performance de API
- [ ] Agregar más features al monolito

### Fase 3: Preparación Microservicios (50k+ usuarios)
- [ ] Separar bases de datos por dominio
- [ ] Implementar API Gateway
- [ ] Configurar Message Queue
- [ ] Monitoring y observabilidad (Prometheus, Grafana)

### Fase 4: Migración a Microservicios (100k+ usuarios)
- [ ] Extraer Conductor Service
- [ ] Extraer Auth Service
- [ ] Extraer Map Service
- [ ] Implementar Saga Pattern para transacciones distribuidas

---

## 🤝 Contribuir

### Para Nuevos Desarrolladores

1. **Lee la documentación**:
   - [Clean Architecture](./CLEAN_ARCHITECTURE.md) (OBLIGATORIO)
   - [ADR](./ADR.md) para entender decisiones

2. **Sigue la estructura**:
   - Crea features en `lib/src/features/{nombre}/`
   - Respeta las capas: domain → data → presentation

3. **Usa abstracciones**:
   - Define contratos (repositories abstractos)
   - Implementa datasources con interfaces
   - Inyecta dependencias via ServiceLocator

4. **Escribe tests**:
   - Unit tests para domain layer
   - Integration tests para data layer
   - Widget tests para presentation layer

### Agregar Nueva Feature

```bash
# 1. Crear estructura
lib/src/features/nueva_feature/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/

# 2. Implementar capas (orden):
1. Domain: Entidades y contratos
2. Data: Datasources y repositorios
3. Presentation: Providers y UI

# 3. Configurar DI en ServiceLocator

# 4. Agregar rutas en AppRouter

# 5. Escribir tests
```

---

## 📞 Contacto y Soporte

**Documentación**: `docs/architecture/`  
**Issues**: GitHub Issues  
**Preguntas**: Slack #architecture

---

## 📝 Changelog

### v1.0.0 - Octubre 2025
- ✅ Clean Architecture implementada
- ✅ Feature Conductor completamente refactorizada
- ✅ Documentación completa
- ✅ Service Locator para DI
- ✅ Manejo de errores con Result<T>
- ✅ Configuración centralizada
- ✅ Preparado para migración a microservicios

---

**Mantenido por**: Equipo Ping Go  
**Última actualización**: Octubre 2025  
**Versión de documentación**: 1.0.0
