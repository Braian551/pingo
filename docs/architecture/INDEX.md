# Documentación del Proyecto Ping Go

## 📋 Índice General

### Arquitectura

1. **[Clean Architecture](CLEAN_ARCHITECTURE.md)**
   - Estructura del proyecto
   - Capas de la arquitectura
   - Flujo de datos
   - Guías de implementación

2. **[Migración a Microservicios](MIGRATION_TO_MICROSERVICES.md)**
   - Cuándo migrar
   - Servicios propuestos
   - Plan de migración paso a paso
   - Configuración técnica
   - Monitoreo y observabilidad

3. **[Migración de Microservicio de Usuarios](USER_MICROSERVICE_MIGRATION.md)** ⭐ NUEVO
   - Resumen de la migración completada
   - Estructura implementada
   - Flujo de datos
   - Guía de uso
   - Próximos pasos

4. **[Limpieza y Reorganización de Microservicios](MICROSERVICES_CLEANUP.md)** ⭐ NUEVO
   - Eliminación de redundancia monolito vs microservicios
   - Centralización de URLs en AppConfig
   - Reorganización de archivos backend
   - Guía de migración

5. **[Guía Rápida de Rutas](GUIA_RAPIDA_RUTAS.md)** ⭐ NUEVO
   - Tabla de referencia de endpoints
   - Uso correcto de AppConfig
   - Ejemplos de migración de código
   - Testing de URLs

6. **[ADR - Architectural Decision Records](ADR.md)**
   - Decisiones arquitectónicas importantes
   - Contexto y justificaciones
   - Consecuencias de cada decisión

7. **[Changelog](CHANGELOG.md)**
   - Historial de cambios
   - Versiones y releases

8. **[Executive Summary](EXECUTIVE_SUMMARY.md)**
   - Resumen ejecutivo del proyecto
   - Visión general de la arquitectura

9. **[Integration Guide](INTEGRATION_GUIDE.md)**
   - Guía de integración con servicios externos
   - APIs de terceros

10. **[Refactoring Summary](REFACTORING_SUMMARY.md)**
   - Resumen de refactorizaciones realizadas

### Módulos

#### Conductor
- **[Backend Endpoints](../conductor/BACKEND_ENDPOINTS.md)** - Documentación de endpoints del conductor
- **[Corrección Registro Vehículos](../conductor/CORRECCION_REGISTRO_VEHICULOS.md)**
- **[Fix Historial Viajes](../conductor/FIX_HISTORIAL_VIAJES.md)**
- **[Guía Rápida](../conductor/GUIA_RAPIDA.md)**
- **[Nuevas Funcionalidades](../conductor/NUEVAS_FUNCIONALIDADES.md)**
- **[Perfil Alerta Dinámica](../conductor/PERFIL_ALERTA_DINAMICA.md)**
- **[Resumen Implementación](../conductor/RESUMEN_IMPLEMENTACION.md)**

#### Mapbox
- **[Cambios Mapbox](../mapbox/CAMBIOS_MAPBOX.md)**
- **[Cheat Sheet](../mapbox/CHEAT_SHEET.md)**
- **[Estructura](../mapbox/ESTRUCTURA.md)**
- **[Implementación Completada](../mapbox/IMPLEMENTACION_COMPLETADA.md)**
- **[Índice Documentación](../mapbox/INDICE_DOCUMENTACION.md)**
- **[Inicio Rápido](../mapbox/INICIO_RAPIDO.md)**
- **[Mapbox Setup](../mapbox/MAPBOX_SETUP.md)**
- **[README Mapbox](../mapbox/README_MAPBOX.md)**
- **[Resumen Ejecutivo](../mapbox/RESUMEN_EJECUTIVO.md)**

#### Home
- **[Home Final Update](../home/HOME_FINAL_UPDATE.md)**
- **[Home Modernization](../home/HOME_MODERNIZATION.md)**

#### Onboarding
- **[Onboarding Design](../onboarding/ONBOARDING_DESIGN.md)**
- **[Onboarding Instructions](../onboarding/ONBOARDING_INSTRUCTIONS.md)**

#### General
- **[README General](../general/README.md)**

### Backend

#### User Microservice (Auth)
- **[README User Microservice](../../pingo/backend/auth/README_USER_MICROSERVICE.md)** ⭐ NUEVO
  - Endpoints disponibles
  - Estructura de requests/responses
  - Base de datos
  - Testing
  - Seguridad

## 🚀 Inicio Rápido

### Para Nuevos Desarrolladores

1. **Lee primero**: [Clean Architecture](CLEAN_ARCHITECTURE.md)
2. **Organización**: [Limpieza de Microservicios](MICROSERVICES_CLEANUP.md)
3. **Rutas y URLs**: [Guía Rápida de Rutas](GUIA_RAPIDA_RUTAS.md)
4. **Entiende el proyecto**: [Executive Summary](EXECUTIVE_SUMMARY.md)
5. **Migración actual**: [Microservicio de Usuarios](USER_MICROSERVICE_MIGRATION.md)
6. **Backend**: [User Microservice Backend](../../pingo/backend/auth/README_USER_MICROSERVICE.md)

### Para Migraciones

1. **Guía general**: [Migración a Microservicios](MIGRATION_TO_MICROSERVICES.md)
2. **Ejemplo completado**: [User Microservice Migration](USER_MICROSERVICE_MIGRATION.md)
3. **Próximo módulo**: Seguir el mismo patrón para Conductores

## 🎯 Estado del Proyecto

### ✅ Completado

- [x] Clean Architecture implementada
- [x] Microservicio de Usuarios (Auth) migrado
- [x] URLs centralizadas en AppConfig
- [x] Backend reorganizado por microservicios
- [x] Archivos PHP movidos a carpetas correctas
- [x] Service Locator configurado
- [x] Documentación completa
- [x] Backend documentado

### 🔄 En Progreso

- [ ] Tests unitarios para User domain
- [ ] Migrar screens de auth al nuevo provider
- [ ] Actualizar home para auto-login

### 📅 Próximos Pasos

1. **Corto Plazo**
   - Migrar screens de auth
   - Implementar tests
   - Agregar JWT tokens

2. **Mediano Plazo**
   - Migrar módulo de Conductores
   - API Gateway
   - Separar base de datos

3. **Largo Plazo**
   - Dockerizar servicios
   - CI/CD
   - Observabilidad (ELK, Prometheus)

## 📚 Recursos Adicionales

### Externos
- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Microservices.io - Patterns](https://microservices.io/patterns/)
- [Martin Fowler - Microservices](https://martinfowler.com/articles/microservices.html)
- [Flutter Clean Architecture](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)

### Internas
- [Mejoras UI Registro](../MEJORAS_UI_REGISTRO.md)
- [Solución Mapbox Error](../SOLUCION_MAPBOX_ERROR.md)

## 🤝 Contribuir

### Agregar Nueva Documentación

1. Crear archivo `.md` en la carpeta apropiada
2. Seguir el formato de documentos existentes
3. Actualizar este `INDEX.md`
4. Hacer commit con mensaje descriptivo

### Convenciones

- Usar Markdown con emojis para mejor legibilidad
- Incluir ejemplos de código
- Documentar decisiones arquitectónicas en ADR
- Mantener changelog actualizado

## 📞 Contacto

- **Equipo**: Ping Go Development Team
- **Proyecto**: Ping Go - Plataforma de Transporte
- **Versión**: 1.0.0
- **Última actualización**: Octubre 2025

---

**Nota**: Este documento es el punto de entrada a toda la documentación. Manténgalo actualizado con cada cambio significativo.
