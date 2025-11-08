CREATE DATABASE  IF NOT EXISTS `viax` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `viax`;
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: viax
-- ------------------------------------------------------
-- Server version	9.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `asignaciones_conductor`
--

DROP TABLE IF EXISTS `asignaciones_conductor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asignaciones_conductor` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `solicitud_id` bigint unsigned NOT NULL,
  `conductor_id` bigint unsigned NOT NULL,
  `asignado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `llegado_en` timestamp NULL DEFAULT NULL,
  `estado` enum('asignado','llegado','cancelado') DEFAULT 'asignado',
  PRIMARY KEY (`id`),
  KEY `solicitud_id` (`solicitud_id`),
  KEY `conductor_id` (`conductor_id`),
  CONSTRAINT `asignaciones_conductor_ibfk_1` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`) ON DELETE CASCADE,
  CONSTRAINT `asignaciones_conductor_ibfk_2` FOREIGN KEY (`conductor_id`) REFERENCES `usuarios` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asignaciones_conductor`
--

LOCK TABLES `asignaciones_conductor` WRITE;
/*!40000 ALTER TABLE `asignaciones_conductor` DISABLE KEYS */;
INSERT INTO `asignaciones_conductor` VALUES (1,1,7,'2025-10-24 21:28:46','2025-10-24 21:28:46','asignado'),(2,25,7,'2025-11-04 13:48:03',NULL,'asignado'),(3,24,7,'2025-11-04 13:53:15',NULL,'asignado'),(4,26,7,'2025-11-04 14:04:06',NULL,'asignado');
/*!40000 ALTER TABLE `asignaciones_conductor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_direcciones`
--

DROP TABLE IF EXISTS `cache_direcciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_direcciones` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `latitud_origen` decimal(10,8) NOT NULL,
  `longitud_origen` decimal(11,8) NOT NULL,
  `latitud_destino` decimal(10,8) NOT NULL,
  `longitud_destino` decimal(11,8) NOT NULL,
  `distancia` decimal(8,2) NOT NULL,
  `duracion` int NOT NULL,
  `polilinea` text NOT NULL,
  `datos_respuesta` json NOT NULL,
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expira_en` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cache_dir_ruta` (`latitud_origen`,`longitud_origen`,`latitud_destino`,`longitud_destino`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_direcciones`
--

LOCK TABLES `cache_direcciones` WRITE;
/*!40000 ALTER TABLE `cache_direcciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_direcciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_geocodificacion`
--

DROP TABLE IF EXISTS `cache_geocodificacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_geocodificacion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `latitud` decimal(10,8) NOT NULL,
  `longitud` decimal(11,8) NOT NULL,
  `direccion_formateada` varchar(500) NOT NULL,
  `id_lugar` varchar(255) DEFAULT NULL,
  `datos_respuesta` json NOT NULL,
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expira_en` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cache_geo_coordenadas` (`latitud`,`longitud`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_geocodificacion`
--

LOCK TABLES `cache_geocodificacion` WRITE;
/*!40000 ALTER TABLE `cache_geocodificacion` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_geocodificacion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `calificaciones`
--

DROP TABLE IF EXISTS `calificaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `calificaciones` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `solicitud_id` bigint unsigned NOT NULL,
  `usuario_calificador_id` bigint unsigned NOT NULL,
  `usuario_calificado_id` bigint unsigned NOT NULL,
  `calificacion` tinyint NOT NULL,
  `comentarios` text,
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `solicitud_id` (`solicitud_id`),
  KEY `usuario_calificador_id` (`usuario_calificador_id`),
  KEY `usuario_calificado_id` (`usuario_calificado_id`),
  CONSTRAINT `calificaciones_ibfk_1` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`),
  CONSTRAINT `calificaciones_ibfk_2` FOREIGN KEY (`usuario_calificador_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `calificaciones_ibfk_3` FOREIGN KEY (`usuario_calificado_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `calificaciones_chk_1` CHECK (((`calificacion` >= 1) and (`calificacion` <= 5)))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `calificaciones`
--

LOCK TABLES `calificaciones` WRITE;
/*!40000 ALTER TABLE `calificaciones` DISABLE KEYS */;
INSERT INTO `calificaciones` VALUES (1,1,1,7,5,'Excelente conductor!','2025-10-24 21:28:46');
/*!40000 ALTER TABLE `calificaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `configuracion_precios`
--

DROP TABLE IF EXISTS `configuracion_precios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuracion_precios` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tipo_vehiculo` enum('moto') NOT NULL DEFAULT 'moto',
  `tarifa_base` decimal(10,2) NOT NULL DEFAULT '5000.00' COMMENT 'Tarifa m├¡nima del viaje en COP',
  `costo_por_km` decimal(10,2) NOT NULL DEFAULT '2500.00' COMMENT 'Costo por kil├│metro recorrido',
  `costo_por_minuto` decimal(10,2) NOT NULL DEFAULT '300.00' COMMENT 'Costo por minuto de duraci├│n',
  `tarifa_minima` decimal(10,2) NOT NULL DEFAULT '8000.00' COMMENT 'Precio m├¡nimo total del viaje',
  `tarifa_maxima` decimal(10,2) DEFAULT NULL COMMENT 'Precio m├íximo permitido (NULL = sin l├¡mite)',
  `recargo_hora_pico` decimal(5,2) NOT NULL DEFAULT '20.00' COMMENT 'Porcentaje de recargo en hora pico',
  `recargo_nocturno` decimal(5,2) NOT NULL DEFAULT '25.00' COMMENT 'Porcentaje de recargo nocturno (10pm-6am)',
  `recargo_festivo` decimal(5,2) NOT NULL DEFAULT '30.00' COMMENT 'Porcentaje de recargo en d├¡as festivos',
  `descuento_distancia_larga` decimal(5,2) NOT NULL DEFAULT '10.00' COMMENT 'Descuento para viajes > umbral_km',
  `umbral_km_descuento` decimal(10,2) NOT NULL DEFAULT '15.00' COMMENT 'Kil├│metros para aplicar descuento',
  `hora_pico_inicio_manana` time DEFAULT '07:00:00',
  `hora_pico_fin_manana` time DEFAULT '09:00:00',
  `hora_pico_inicio_tarde` time DEFAULT '17:00:00',
  `hora_pico_fin_tarde` time DEFAULT '19:00:00',
  `hora_nocturna_inicio` time DEFAULT '22:00:00',
  `hora_nocturna_fin` time DEFAULT '06:00:00',
  `comision_plataforma` decimal(5,2) NOT NULL DEFAULT '15.00' COMMENT 'Porcentaje de comisi├│n para la plataforma',
  `comision_metodo_pago` decimal(5,2) NOT NULL DEFAULT '2.50' COMMENT 'Comisi├│n adicional por pago digital',
  `distancia_minima` decimal(10,2) NOT NULL DEFAULT '1.00' COMMENT 'Distancia m├¡nima del viaje en km',
  `distancia_maxima` decimal(10,2) NOT NULL DEFAULT '50.00' COMMENT 'Distancia m├íxima del viaje en km',
  `tiempo_espera_gratis` int NOT NULL DEFAULT '3' COMMENT 'Minutos de espera gratuita',
  `costo_tiempo_espera` decimal(10,2) NOT NULL DEFAULT '500.00' COMMENT 'Costo por minuto de espera adicional',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `notas` text COMMENT 'Notas sobre cambios de precios',
  PRIMARY KEY (`id`),
  KEY `idx_tipo_vehiculo` (`tipo_vehiculo`),
  KEY `idx_activo` (`activo`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Configuraci├│n de precios por tipo de veh├¡culo';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion_precios`
--

LOCK TABLES `configuracion_precios` WRITE;
/*!40000 ALTER TABLE `configuracion_precios` DISABLE KEYS */;
INSERT INTO `configuracion_precios` VALUES (5,'moto',4000.00,2000.00,250.00,6000.00,NULL,15.00,20.00,25.00,10.00,15.00,'07:00:00','09:00:00','17:00:00','19:00:00','22:00:00','06:00:00',14.00,2.50,1.00,50.00,3,500.00,1,'2025-10-26 18:40:23','2025-10-27 02:22:19','Configuraci├│n inicial para servicio de moto - Octubre 2025');
/*!40000 ALTER TABLE `configuracion_precios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `configuraciones_app`
--

DROP TABLE IF EXISTS `configuraciones_app`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuraciones_app` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `clave` varchar(100) NOT NULL COMMENT 'Nombre de la configuracion',
  `valor` text COMMENT 'Valor de la configuracion',
  `tipo` enum('string','number','boolean','json') DEFAULT 'string',
  `categoria` varchar(50) DEFAULT NULL COMMENT 'Categoria de la config (pricing, system, etc)',
  `descripcion` text COMMENT 'Descripcion de que hace esta config',
  `es_publica` tinyint(1) DEFAULT '0' COMMENT '1 si puede verse en el frontend',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_clave` (`clave`),
  KEY `idx_categoria` (`categoria`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Configuraciones globales de la aplicacion';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuraciones_app`
--

LOCK TABLES `configuraciones_app` WRITE;
/*!40000 ALTER TABLE `configuraciones_app` DISABLE KEYS */;
INSERT INTO `configuraciones_app` VALUES (1,'app_nombre','Viax','string','sistema','Nombre de la aplicacion',1,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(2,'app_version','1.0.0','string','sistema','Version actual de la aplicacion',1,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(3,'mantenimiento_activo','false','boolean','sistema','Indica si la app esta en mantenimiento',1,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(4,'precio_base_km','2500','number','precios','Precio base por kilometro en COP',0,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(5,'precio_minimo_viaje','5000','number','precios','Precio minimo de un viaje en COP',0,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(6,'comision_plataforma','15','number','precios','Porcentaje de comision de la plataforma',0,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(7,'radio_busqueda_conductores','5000','number','sistema','Radio en metros para buscar conductores',0,'2025-10-22 14:35:57','2025-10-23 14:06:24'),(8,'tiempo_expiracion_solicitud','300','number','sistema','Tiempo en segundos antes de expirar solicitud',0,'2025-10-22 14:35:57','2025-10-23 14:06:24');
/*!40000 ALTER TABLE `configuraciones_app` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalles_conductor`
--

DROP TABLE IF EXISTS `detalles_conductor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalles_conductor` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `licencia_conduccion` varchar(50) NOT NULL,
  `licencia_vencimiento` date NOT NULL,
  `licencia_expedicion` date DEFAULT NULL,
  `licencia_categoria` varchar(10) DEFAULT 'C1',
  `licencia_foto_url` varchar(500) DEFAULT NULL COMMENT 'Ruta de la foto de la licencia',
  `vehiculo_tipo` enum('motocicleta','carro','furgoneta','camion') NOT NULL,
  `vehiculo_marca` varchar(50) DEFAULT NULL,
  `vehiculo_modelo` varchar(50) DEFAULT NULL,
  `vehiculo_anio` int DEFAULT NULL,
  `vehiculo_color` varchar(30) DEFAULT NULL,
  `vehiculo_placa` varchar(20) NOT NULL,
  `aseguradora` varchar(100) DEFAULT NULL,
  `numero_poliza_seguro` varchar(100) DEFAULT NULL,
  `vencimiento_seguro` date DEFAULT NULL,
  `seguro_foto_url` varchar(500) DEFAULT NULL COMMENT 'Ruta de la foto del seguro',
  `soat_numero` varchar(50) DEFAULT NULL,
  `soat_vencimiento` date DEFAULT NULL,
  `soat_foto_url` varchar(500) DEFAULT NULL COMMENT 'Ruta de la foto del SOAT',
  `tecnomecanica_numero` varchar(50) DEFAULT NULL,
  `tecnomecanica_vencimiento` date DEFAULT NULL,
  `tecnomecanica_foto_url` varchar(500) DEFAULT NULL COMMENT 'Ruta de la foto de la tecnomecánica',
  `tarjeta_propiedad_numero` varchar(50) DEFAULT NULL,
  `tarjeta_propiedad_foto_url` varchar(500) DEFAULT NULL COMMENT 'Ruta de la foto de la tarjeta de propiedad',
  `aprobado` tinyint(1) DEFAULT '0',
  `estado_aprobacion` enum('pendiente','aprobado','rechazado') DEFAULT 'pendiente',
  `calificacion_promedio` decimal(3,2) DEFAULT '0.00',
  `total_calificaciones` int DEFAULT '0',
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `disponible` tinyint(1) DEFAULT '0' COMMENT '1 si el conductor esta disponible para recibir solicitudes',
  `latitud_actual` decimal(10,8) DEFAULT NULL COMMENT 'Latitud actual del conductor',
  `longitud_actual` decimal(11,8) DEFAULT NULL COMMENT 'Longitud actual del conductor',
  `ultima_actualizacion` timestamp NULL DEFAULT NULL COMMENT 'Ultima vez que se actualizo la ubicacion',
  `total_viajes` int unsigned DEFAULT '0' COMMENT 'Total de viajes completados',
  `estado_verificacion` enum('pendiente','en_revision','aprobado','rechazado') DEFAULT 'pendiente' COMMENT 'Estado de verificacion de documentos',
  `fecha_ultima_verificacion` timestamp NULL DEFAULT NULL COMMENT 'Fecha de la ultima verificacion',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_detalles_conductor_usuario` (`usuario_id`),
  KEY `idx_disponible` (`disponible`),
  KEY `idx_ubicacion` (`latitud_actual`,`longitud_actual`),
  KEY `idx_licencia` (`licencia_conduccion`),
  KEY `idx_placa` (`vehiculo_placa`),
  KEY `idx_estado_verificacion` (`estado_verificacion`),
  KEY `idx_licencia_vencimiento` (`licencia_vencimiento`),
  KEY `idx_soat_vencimiento` (`soat_vencimiento`),
  KEY `idx_tecnomecanica_vencimiento` (`tecnomecanica_vencimiento`),
  CONSTRAINT `detalles_conductor_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalles_conductor`
--

LOCK TABLES `detalles_conductor` WRITE;
/*!40000 ALTER TABLE `detalles_conductor` DISABLE KEYS */;
INSERT INTO `detalles_conductor` VALUES (1,7,'42424224242','2036-10-25','2020-10-08','C1','uploads/documentos/conductor_7/licencia_1761492375_1a4c4887f68f6988.jpg','motocicleta','toyota','corolla',2020,'Blanco','3232323',NULL,NULL,NULL,NULL,'3232323','2027-10-26','uploads/documentos/conductor_7/soat_1761492819_87a1e30ab2e6b43c.jpg','323232332','2027-10-26','uploads/documentos/conductor_7/tecnomecanica_1761492819_a331dc0207ae3a9d.jpg','32323','uploads/documentos/conductor_7/tarjeta_propiedad_1761492820_ad1097b64c039a5d.jpg',1,'aprobado',0.00,0,'2025-10-24 11:53:16','2025-11-04 18:38:03',1,6.25461830,-75.53955670,'2025-11-04 18:38:03',0,'aprobado','2025-10-26 16:22:01','2025-10-24 11:53:16');
/*!40000 ALTER TABLE `detalles_conductor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalles_paquete`
--

DROP TABLE IF EXISTS `detalles_paquete`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalles_paquete` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `solicitud_id` bigint unsigned NOT NULL,
  `tipo_paquete` enum('documento','pequeno','mediano','grande','fragil','perecedero') NOT NULL,
  `descripcion_paquete` varchar(500) DEFAULT NULL,
  `valor_estimado` decimal(10,2) DEFAULT NULL,
  `peso` decimal(5,2) NOT NULL,
  `largo` decimal(5,2) DEFAULT NULL,
  `ancho` decimal(5,2) DEFAULT NULL,
  `alto` decimal(5,2) DEFAULT NULL,
  `requiere_firma` tinyint(1) DEFAULT '0',
  `seguro_solicitado` tinyint(1) DEFAULT '0',
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `solicitud_id` (`solicitud_id`),
  CONSTRAINT `detalles_paquete_ibfk_1` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalles_paquete`
--

LOCK TABLES `detalles_paquete` WRITE;
/*!40000 ALTER TABLE `detalles_paquete` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalles_paquete` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalles_viaje`
--

DROP TABLE IF EXISTS `detalles_viaje`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalles_viaje` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `solicitud_id` bigint unsigned NOT NULL,
  `numero_pasajeros` int DEFAULT '1',
  `opciones_viaje` json DEFAULT NULL,
  `tarifa_estimada` decimal(8,2) DEFAULT NULL,
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `solicitud_id` (`solicitud_id`),
  CONSTRAINT `detalles_viaje_ibfk_1` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalles_viaje`
--

LOCK TABLES `detalles_viaje` WRITE;
/*!40000 ALTER TABLE `detalles_viaje` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalles_viaje` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documentos_conductor_historial`
--

DROP TABLE IF EXISTS `documentos_conductor_historial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documentos_conductor_historial` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `conductor_id` bigint unsigned NOT NULL,
  `tipo_documento` enum('licencia','soat','tecnomecanica','tarjeta_propiedad','seguro') NOT NULL,
  `url_documento` varchar(500) NOT NULL,
  `fecha_carga` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `activo` tinyint(1) DEFAULT '1' COMMENT '1 si es el documento actual, 0 si fue reemplazado',
  `reemplazado_en` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_conductor_tipo` (`conductor_id`,`tipo_documento`),
  KEY `idx_fecha_carga` (`fecha_carga`),
  KEY `idx_activo` (`activo`),
  CONSTRAINT `fk_doc_historial_conductor` FOREIGN KEY (`conductor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Historial de documentos subidos por conductores';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documentos_conductor_historial`
--

LOCK TABLES `documentos_conductor_historial` WRITE;
/*!40000 ALTER TABLE `documentos_conductor_historial` DISABLE KEYS */;
INSERT INTO `documentos_conductor_historial` VALUES (1,7,'licencia','uploads/documentos/conductor_7/licencia_1761492375_1a4c4887f68f6988.jpg','2025-10-26 15:26:15',1,NULL),(2,7,'soat','uploads/documentos/conductor_7/soat_1761492819_87a1e30ab2e6b43c.jpg','2025-10-26 15:33:39',1,NULL),(3,7,'tecnomecanica','uploads/documentos/conductor_7/tecnomecanica_1761492819_a331dc0207ae3a9d.jpg','2025-10-26 15:33:39',1,NULL),(4,7,'tarjeta_propiedad','uploads/documentos/conductor_7/tarjeta_propiedad_1761492820_ad1097b64c039a5d.jpg','2025-10-26 15:33:40',1,NULL);
/*!40000 ALTER TABLE `documentos_conductor_historial` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `estadisticas_sistema`
--

DROP TABLE IF EXISTS `estadisticas_sistema`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `estadisticas_sistema` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `fecha` date NOT NULL,
  `total_usuarios` int unsigned DEFAULT '0',
  `total_clientes` int unsigned DEFAULT '0',
  `total_conductores` int unsigned DEFAULT '0',
  `total_administradores` int unsigned DEFAULT '0',
  `usuarios_activos_dia` int unsigned DEFAULT '0',
  `nuevos_registros_dia` int unsigned DEFAULT '0',
  `total_solicitudes` int unsigned DEFAULT '0',
  `solicitudes_completadas` int unsigned DEFAULT '0',
  `solicitudes_canceladas` int unsigned DEFAULT '0',
  `ingresos_totales` decimal(10,2) DEFAULT '0.00',
  `ingresos_dia` decimal(10,2) DEFAULT '0.00',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_fecha` (`fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Estadisticas diarias del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `estadisticas_sistema`
--

LOCK TABLES `estadisticas_sistema` WRITE;
/*!40000 ALTER TABLE `estadisticas_sistema` DISABLE KEYS */;
/*!40000 ALTER TABLE `estadisticas_sistema` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_precios`
--

DROP TABLE IF EXISTS `historial_precios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_precios` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `configuracion_id` bigint unsigned NOT NULL,
  `campo_modificado` varchar(100) NOT NULL,
  `valor_anterior` text,
  `valor_nuevo` text,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `fecha_cambio` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `motivo` text COMMENT 'Raz├│n del cambio de precio',
  PRIMARY KEY (`id`),
  KEY `idx_configuracion` (`configuracion_id`),
  KEY `idx_fecha` (`fecha_cambio`),
  KEY `fk_historial_usuario` (`usuario_id`),
  CONSTRAINT `fk_historial_config` FOREIGN KEY (`configuracion_id`) REFERENCES `configuracion_precios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_historial_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Auditor├¡a de cambios en configuraci├│n de precios';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_precios`
--

LOCK TABLES `historial_precios` WRITE;
/*!40000 ALTER TABLE `historial_precios` DISABLE KEYS */;
/*!40000 ALTER TABLE `historial_precios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_seguimiento`
--

DROP TABLE IF EXISTS `historial_seguimiento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_seguimiento` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `solicitud_id` bigint unsigned NOT NULL,
  `conductor_id` bigint unsigned NOT NULL,
  `latitud` decimal(10,8) NOT NULL,
  `longitud` decimal(11,8) NOT NULL,
  `precision_gps` decimal(5,2) DEFAULT NULL,
  `velocidad` decimal(5,2) DEFAULT NULL,
  `direccion` smallint DEFAULT NULL,
  `timestamp_seguimiento` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `conductor_id` (`conductor_id`),
  KEY `idx_seguimiento_solicitud` (`solicitud_id`),
  KEY `idx_seguimiento_timestamp` (`timestamp_seguimiento`),
  CONSTRAINT `historial_seguimiento_ibfk_1` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`) ON DELETE CASCADE,
  CONSTRAINT `historial_seguimiento_ibfk_2` FOREIGN KEY (`conductor_id`) REFERENCES `usuarios` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_seguimiento`
--

LOCK TABLES `historial_seguimiento` WRITE;
/*!40000 ALTER TABLE `historial_seguimiento` DISABLE KEYS */;
/*!40000 ALTER TABLE `historial_seguimiento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs_auditoria`
--

DROP TABLE IF EXISTS `logs_auditoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logs_auditoria` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `accion` varchar(100) NOT NULL COMMENT 'Tipo de accion realizada',
  `entidad` varchar(100) DEFAULT NULL COMMENT 'Tabla o entidad afectada',
  `entidad_id` bigint unsigned DEFAULT NULL COMMENT 'ID del registro afectado',
  `descripcion` text COMMENT 'Descripcion detallada de la accion',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'Direccion IP del usuario',
  `user_agent` varchar(255) DEFAULT NULL COMMENT 'Navegador/dispositivo usado',
  `datos_anteriores` json DEFAULT NULL COMMENT 'Datos antes del cambio',
  `datos_nuevos` json DEFAULT NULL COMMENT 'Datos despues del cambio',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_usuario_id` (`usuario_id`),
  KEY `idx_accion` (`accion`),
  KEY `idx_fecha` (`fecha_creacion`),
  CONSTRAINT `fk_logs_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Registro de todas las acciones importantes del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs_auditoria`
--

LOCK TABLES `logs_auditoria` WRITE;
/*!40000 ALTER TABLE `logs_auditoria` DISABLE KEYS */;
INSERT INTO `logs_auditoria` VALUES (1,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-22 14:37:21'),(2,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-24 11:11:27'),(3,7,'submit_verification','detalles_conductor',7,'Conductor envió perfil para verificación',NULL,NULL,NULL,NULL,'2025-10-25 15:41:26'),(4,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-25 16:08:02'),(5,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-25 18:47:52'),(6,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 15:05:06'),(7,7,'submit_verification','detalles_conductor',7,'Conductor envió perfil para verificación',NULL,NULL,NULL,NULL,'2025-10-26 15:45:50'),(8,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 15:48:18'),(9,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 16:23:40'),(10,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 17:07:32'),(11,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 17:53:51'),(12,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 19:31:37'),(13,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 20:33:37'),(14,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 21:41:51'),(15,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 23:07:04'),(16,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 23:30:41'),(17,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-26 23:52:53'),(18,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 01:00:48'),(19,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 01:10:23'),(20,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 01:16:41'),(21,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 01:19:23'),(22,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 01:27:04'),(23,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 02:01:29'),(24,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 04:01:54'),(25,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 04:15:05'),(26,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 04:17:24'),(27,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 04:18:33'),(28,1,'actualizar_usuario','usuarios',5,'Administrador actualizó datos del usuario',NULL,NULL,NULL,NULL,'2025-10-27 04:26:37'),(29,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 22:09:32'),(30,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 22:11:36'),(31,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-27 22:13:55'),(32,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-10-29 17:47:58'),(33,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-03 15:40:24'),(34,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-03 17:33:35'),(35,1,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-04 01:36:52'),(36,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-04 12:48:54'),(37,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-04 13:41:12'),(38,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-04 18:33:39'),(39,7,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-04 18:36:01'),(40,6,'login',NULL,NULL,'Usuario inició sesión exitosamente','127.0.0.1','Dart/3.9 (dart:io)',NULL,NULL,'2025-11-04 18:40:57');
/*!40000 ALTER TABLE `logs_auditoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `metodos_pago_usuario`
--

DROP TABLE IF EXISTS `metodos_pago_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `metodos_pago_usuario` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `tipo_pago` enum('tarjeta_credito','tarjeta_debito','billetera_digital') NOT NULL,
  `ultimos_cuatro_digitos` varchar(4) DEFAULT NULL,
  `marca_tarjeta` varchar(50) DEFAULT NULL,
  `tipo_billetera` varchar(50) DEFAULT NULL,
  `es_principal` tinyint(1) DEFAULT '0',
  `activo` tinyint(1) DEFAULT '1',
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `metodos_pago_usuario_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metodos_pago_usuario`
--

LOCK TABLES `metodos_pago_usuario` WRITE;
/*!40000 ALTER TABLE `metodos_pago_usuario` DISABLE KEYS */;
/*!40000 ALTER TABLE `metodos_pago_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores_mapa`
--

DROP TABLE IF EXISTS `proveedores_mapa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores_mapa` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `api_key` varchar(255) NOT NULL,
  `activo` tinyint(1) DEFAULT '1',
  `contador_solicitudes` int DEFAULT '0',
  `ultimo_uso` timestamp NULL DEFAULT NULL,
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores_mapa`
--

LOCK TABLES `proveedores_mapa` WRITE;
/*!40000 ALTER TABLE `proveedores_mapa` DISABLE KEYS */;
/*!40000 ALTER TABLE `proveedores_mapa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reglas_precios`
--

DROP TABLE IF EXISTS `reglas_precios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reglas_precios` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tipo_servicio` enum('transporte','envio_paquete') NOT NULL,
  `tipo_vehiculo` enum('motocicleta','carro','furgoneta','camion') NOT NULL,
  `tarifa_base` decimal(8,2) NOT NULL,
  `costo_por_km` decimal(8,2) NOT NULL,
  `costo_por_minuto` decimal(8,2) NOT NULL,
  `tarifa_minima` decimal(8,2) NOT NULL,
  `tarifa_cancelacion` decimal(8,2) DEFAULT '0.00',
  `multiplicador_demanda` decimal(3,2) DEFAULT '1.00',
  `activo` tinyint(1) DEFAULT '1',
  `valido_desde` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `valido_hasta` timestamp NULL DEFAULT NULL,
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reglas_precios`
--

LOCK TABLES `reglas_precios` WRITE;
/*!40000 ALTER TABLE `reglas_precios` DISABLE KEYS */;
/*!40000 ALTER TABLE `reglas_precios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reportes_usuarios`
--

DROP TABLE IF EXISTS `reportes_usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reportes_usuarios` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_reportante_id` bigint unsigned NOT NULL,
  `usuario_reportado_id` bigint unsigned NOT NULL,
  `solicitud_id` bigint unsigned DEFAULT NULL,
  `tipo_reporte` enum('conducta_inapropiada','fraude','seguridad','otro') NOT NULL,
  `descripcion` text NOT NULL,
  `estado` enum('pendiente','en_revision','resuelto','rechazado') DEFAULT 'pendiente',
  `notas_admin` text,
  `admin_revisor_id` bigint unsigned DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_resolucion` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_reportante` (`usuario_reportante_id`),
  KEY `idx_reportado` (`usuario_reportado_id`),
  KEY `idx_estado` (`estado`),
  KEY `fk_reporte_solicitud` (`solicitud_id`),
  KEY `fk_reporte_admin` (`admin_revisor_id`),
  CONSTRAINT `fk_reporte_admin` FOREIGN KEY (`admin_revisor_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reporte_reportado` FOREIGN KEY (`usuario_reportado_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reporte_reportante` FOREIGN KEY (`usuario_reportante_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reporte_solicitud` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Reportes de usuarios sobre comportamiento inadecuado';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reportes_usuarios`
--

LOCK TABLES `reportes_usuarios` WRITE;
/*!40000 ALTER TABLE `reportes_usuarios` DISABLE KEYS */;
/*!40000 ALTER TABLE `reportes_usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `solicitudes_servicio`
--

DROP TABLE IF EXISTS `solicitudes_servicio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solicitudes_servicio` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid_solicitud` varchar(255) NOT NULL,
  `cliente_id` bigint unsigned NOT NULL,
  `tipo_servicio` enum('transporte','envio_paquete') NOT NULL,
  `ubicacion_recogida_id` bigint unsigned DEFAULT NULL,
  `ubicacion_destino_id` bigint unsigned DEFAULT NULL,
  `latitud_recogida` decimal(10,8) NOT NULL,
  `longitud_recogida` decimal(11,8) NOT NULL,
  `direccion_recogida` varchar(500) NOT NULL,
  `latitud_destino` decimal(10,8) NOT NULL,
  `longitud_destino` decimal(11,8) NOT NULL,
  `direccion_destino` varchar(500) NOT NULL,
  `distancia_estimada` decimal(8,2) NOT NULL,
  `tiempo_estimado` int NOT NULL,
  `estado` enum('pendiente','aceptada','conductor_asignado','recogido','en_transito','entregado','completada','cancelada') DEFAULT 'pendiente',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `solicitado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `aceptado_en` timestamp NULL DEFAULT NULL,
  `recogido_en` timestamp NULL DEFAULT NULL,
  `entregado_en` timestamp NULL DEFAULT NULL,
  `completado_en` timestamp NULL DEFAULT NULL,
  `cancelado_en` timestamp NULL DEFAULT NULL,
  `motivo_cancelacion` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid_solicitud` (`uuid_solicitud`),
  KEY `ubicacion_recogida_id` (`ubicacion_recogida_id`),
  KEY `ubicacion_destino_id` (`ubicacion_destino_id`),
  KEY `idx_solicitudes_cliente` (`cliente_id`),
  KEY `idx_solicitudes_estado` (`estado`),
  KEY `idx_solicitudes_fecha` (`solicitado_en`),
  CONSTRAINT `solicitudes_servicio_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `solicitudes_servicio_ibfk_2` FOREIGN KEY (`ubicacion_recogida_id`) REFERENCES `ubicaciones_usuario` (`id`),
  CONSTRAINT `solicitudes_servicio_ibfk_3` FOREIGN KEY (`ubicacion_destino_id`) REFERENCES `ubicaciones_usuario` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `solicitudes_servicio`
--

LOCK TABLES `solicitudes_servicio` WRITE;
/*!40000 ALTER TABLE `solicitudes_servicio` DISABLE KEYS */;
INSERT INTO `solicitudes_servicio` VALUES (1,'test_68fbef8e42782',1,'transporte',NULL,NULL,6.25461800,-75.53955700,'Carrera 18B, Llanaditas',6.24465400,-75.56650400,'Parque Lleras, El Poblado',8.50,25,'completada','2025-10-24 21:28:46','2025-10-24 21:28:46',NULL,NULL,NULL,'2025-10-24 21:28:46',NULL,NULL),(18,'429979c7-ca56-4a01-bf48-ac2d7c30e932',6,'transporte',NULL,NULL,6.25461830,-75.53955670,'Carrera 18B #62 - 191, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia',6.15767810,-75.64338780,'La Estrella, Antioquia',22.38,45,'cancelada','2025-10-27 03:23:37','2025-10-27 03:23:37',NULL,NULL,NULL,NULL,'2025-10-27 03:32:32','Cancelado por el cliente'),(19,'7835502f-7277-4ada-86b6-c78bfbfb0cd7',2,'transporte',NULL,NULL,6.25461830,-75.53955670,'Punto de Recogida - Prueba (cerca del conductor)',6.28461830,-75.51955670,'Punto de Destino - Prueba',4.50,15,'cancelada','2025-10-27 03:33:46','2025-10-27 03:33:46',NULL,NULL,NULL,NULL,'2025-10-27 03:34:06','Cancelado por el cliente'),(20,'e7850bf9-235f-4d47-9b3c-8c3995999fba',6,'transporte',NULL,NULL,6.25461830,-75.53955670,'Carrera 18B #62 - 191, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia',6.15767810,-75.64338780,'La Estrella, Antioquia',22.38,45,'cancelada','2025-10-27 03:40:33','2025-10-27 03:40:33',NULL,NULL,NULL,NULL,'2025-10-27 03:40:45','Cancelado por el cliente'),(21,'fea56501-7e5a-4a40-b319-5f5dc26f8b04',6,'transporte',NULL,NULL,6.25461830,-75.53955670,'Carrera 18B #62 - 191, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia',6.15767810,-75.64338780,'La Estrella, Antioquia',22.38,45,'cancelada','2025-10-27 22:10:51','2025-10-27 22:10:51',NULL,NULL,NULL,NULL,'2025-10-27 22:10:57','Cancelado por el cliente'),(24,'018c4b21-4d6c-42e7-9518-6c9b2bd58f45',2,'transporte',NULL,NULL,6.25461830,-75.53955670,'Punto de Recogida - Prueba (cerca del conductor)',6.28461830,-75.51955670,'Punto de Destino - Prueba',4.50,15,'aceptada','2025-11-04 13:42:09','2025-11-04 13:42:09','2025-11-04 13:53:15',NULL,NULL,NULL,NULL,NULL),(25,'c9d5d015-4a90-48c4-b10f-cce771385247',2,'transporte',NULL,NULL,6.25461830,-75.53955670,'Punto de Recogida - Prueba (cerca del conductor)',6.28461830,-75.51955670,'Punto de Destino - Prueba',4.50,15,'aceptada','2025-11-04 13:44:11','2025-11-04 13:44:11','2025-11-04 13:48:03',NULL,NULL,NULL,NULL,NULL),(26,'3acc2d46-498e-43f7-aff9-a9576666ba1e',2,'transporte',NULL,NULL,6.25461830,-75.53955670,'Punto de Recogida - Prueba (cerca del conductor)',6.28461830,-75.51955670,'Punto de Destino - Prueba',4.50,15,'aceptada','2025-11-04 14:03:51','2025-11-04 14:03:51','2025-11-04 14:04:06',NULL,NULL,NULL,NULL,NULL),(32,'4117a833-abd6-4069-8ebc-5d97d9d7d1e9',2,'transporte',NULL,NULL,6.27961830,-75.51955670,'Punto de Recogida - Prueba (dentro de 5km)',6.31461830,-75.48955670,'Punto de Destino - Prueba',7.00,20,'pendiente','2025-11-04 18:36:28','2025-11-04 18:36:28',NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `solicitudes_servicio` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transacciones`
--

DROP TABLE IF EXISTS `transacciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transacciones` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `solicitud_id` bigint unsigned NOT NULL,
  `cliente_id` bigint unsigned NOT NULL,
  `conductor_id` bigint unsigned NOT NULL,
  `monto_tarifa` decimal(10,2) NOT NULL,
  `tarifa_distancia` decimal(10,2) NOT NULL,
  `tarifa_tiempo` decimal(10,2) NOT NULL,
  `multiplicador_demanda` decimal(3,2) DEFAULT '1.00',
  `tarifa_servicio` decimal(10,2) NOT NULL,
  `monto_total` decimal(10,2) NOT NULL,
  `metodo_pago` enum('efectivo','tarjeta_credito','tarjeta_debito','billetera_digital') NOT NULL,
  `estado_pago` enum('pendiente','procesando','completado','fallido','reembolsado') DEFAULT 'pendiente',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_transaccion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `completado_en` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_transacciones_solicitud` (`solicitud_id`),
  KEY `cliente_id` (`cliente_id`),
  KEY `conductor_id` (`conductor_id`),
  KEY `idx_transacciones_estado_pago` (`estado_pago`),
  CONSTRAINT `transacciones_ibfk_1` FOREIGN KEY (`solicitud_id`) REFERENCES `solicitudes_servicio` (`id`),
  CONSTRAINT `transacciones_ibfk_2` FOREIGN KEY (`cliente_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `transacciones_ibfk_3` FOREIGN KEY (`conductor_id`) REFERENCES `usuarios` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transacciones`
--

LOCK TABLES `transacciones` WRITE;
/*!40000 ALTER TABLE `transacciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `transacciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ubicaciones_usuario`
--

DROP TABLE IF EXISTS `ubicaciones_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ubicaciones_usuario` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `latitud` decimal(10,8) NOT NULL,
  `longitud` decimal(11,8) NOT NULL,
  `direccion` varchar(500) NOT NULL,
  `ciudad` varchar(100) NOT NULL,
  `departamento` varchar(100) DEFAULT NULL,
  `pais` varchar(100) DEFAULT 'Colombia',
  `codigo_postal` varchar(20) DEFAULT NULL,
  `es_principal` tinyint(1) DEFAULT '0',
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `ubicaciones_usuario_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ubicaciones_usuario`
--

LOCK TABLES `ubicaciones_usuario` WRITE;
/*!40000 ALTER TABLE `ubicaciones_usuario` DISABLE KEYS */;
INSERT INTO `ubicaciones_usuario` VALUES (1,1,6.25461830,-75.53955670,'Carrera 18B, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia, Colombia','Perímetro Urbano Medellín','Antioquia','Colombia',NULL,1,'2025-09-29 21:11:52',NULL),(2,2,6.24546848,-75.54230341,'Carrera 24BB, Cra 44BB#56EE 13, El Pinal, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia, Colombia','Perímetro Urbano Medellín','Antioquia','Colombia',NULL,1,'2025-10-06 22:47:34',NULL),(3,3,6.25504918,-75.53958122,'Carrera 18B, Llanaditas, Comuna 8 - Villa Hermosa, Medellín, Antioquia, Colombia','Medellín','Antioquia','Colombia',NULL,1,'2025-10-06 23:13:22',NULL),(4,4,6.25490278,-75.54003060,'Carrera 18B, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia, Colombia','Perímetro Urbano Medellín','Antioquia','Colombia',NULL,1,'2025-10-19 16:39:10',NULL),(5,5,6.29540531,-75.54965768,'Carrera 43B, Granizal, Comuna 1 - Popular, Perímetro Urbano Medellín, Antioquia, Colombia','Perímetro Urbano Medellín','Antioquia','Colombia',NULL,1,'2025-10-20 22:37:37',NULL),(6,6,6.25461830,-75.53955670,'Carrera 18B, 62 - 191, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia, Colombia','Perímetro Urbano Medellín','Antioquia','Colombia',NULL,1,'2025-10-22 14:08:47',NULL),(7,7,6.25461830,-75.53955670,'Carrera 18B, 62 - 191, Llanaditas, Comuna 8 - Villa Hermosa, Perímetro Urbano Medellín, Antioquia, Colombia','Perímetro Urbano Medellín','Antioquia','Colombia',NULL,1,'2025-10-22 14:10:55',NULL),(8,8,6.24465400,-75.56650400,'Dirección de Prueba','Medellín','Antioquia','Colombia',NULL,1,'2025-10-27 00:04:52',NULL),(9,9,6.24465400,-75.56650400,'Dirección de Prueba','Medellín','Antioquia','Colombia',NULL,1,'2025-10-27 00:06:16',NULL);
/*!40000 ALTER TABLE `ubicaciones_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `hash_contrasena` varchar(255) NOT NULL,
  `tipo_usuario` enum('cliente','conductor','administrador') DEFAULT 'cliente',
  `foto_perfil` varchar(500) DEFAULT NULL,
  `fecha_nacimiento` date DEFAULT NULL,
  `es_verificado` tinyint(1) DEFAULT '0',
  `es_activo` tinyint(1) DEFAULT '1',
  `fecha_registro` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `ultimo_acceso_en` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `telefono` (`telefono`),
  KEY `idx_usuarios_email` (`email`),
  KEY `idx_usuarios_telefono` (`telefono`),
  KEY `idx_usuarios_tipo` (`tipo_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'user_68daf618780e50.65802566','braian','oquendo','braianoquen@gmail.com','3013636902','$2y$10$H2Un4DmxCsM6XOGA1fiX8.5VB42Z9v8uwqERrGBms83dk2CQVQKnO','administrador',NULL,NULL,0,1,'2025-09-29 21:11:52','2025-10-22 14:16:12',NULL),(2,'user_68e44706c14db4.53994811','braian890','oquendo','braian890@gmail.com','32323232','$2y$10$NB9S4hWQLrK7HhTjc9yneu9RTb6otip3dtZ1muEgukWWLKcSpxRF6','cliente',NULL,NULL,0,1,'2025-10-06 22:47:34',NULL,NULL),(3,'user_68e44d12079086.97442308','braianoquen79','oquendo','braianoquen79@gmail.com','34343434','$2y$10$6LhMx5vHi.3LrrM/EjFjw.ZztZWhhGQgqf1sD76h2RtJ4B7nN/sjC','cliente',NULL,NULL,0,1,'2025-10-06 23:13:22',NULL,NULL),(4,'user_68f5142e614579.71603626','braianoquen323','oquendo','braianoquen323@gmail.com','213131313131','$2y$10$qSZ1igIQd1BQJmq.MRMwM.2EUfUYhvXhsf4g0h7GJJDJ8uaR66/qy','cliente',NULL,NULL,0,1,'2025-10-19 16:39:10',NULL,NULL),(5,'user_68f6b9b1f1cb28.57297864','braianoquen324','oquendo','braianoquen324@gmail.com','4274672','$2y$10$Oji7gxZcVki50Pyk5aReKexUhCGPbXLGNe.rsnlzAaZvI.Bo.UexS','conductor',NULL,NULL,0,1,'2025-10-20 22:37:37','2025-10-27 04:26:37',NULL),(6,'user_68f8e56f0736b2.62296910','braianoquendurango','oquendo','braianoquendurango@gmail.com','323121','$2y$10$DDOIUEJ8jv1ILAu7PKj3LutCGRru.7sVUs2himDiKZ4yqY.VtvRb6','cliente',NULL,NULL,0,1,'2025-10-22 14:08:47',NULL,NULL),(7,'user_68f8e5efd5f888.59258279','braianoquen2','oqeundo','braianoquen2@gmail.com','3242442','$2y$10$DUUZdDrKiyespZGSJfk9JeGYuvOkAjrlMemg9BA/BZfyXlamgobjW','conductor',NULL,NULL,1,1,'2025-10-22 14:10:55','2025-10-26 16:22:01',NULL),(8,'test_68feb7247e181','Usuario','Prueba','test5300@example.com','3004267353','$2y$12$IaYB.Y6RT7mjqA5ZQCKAi.KhAmswTlSHW2n/k1OY7hXF47knzU8Je','cliente',NULL,NULL,0,1,'2025-10-27 00:04:52',NULL,NULL),(9,'test_68feb77859998','Usuario','Prueba','test9034@example.com','3002706622','$2y$12$moeVRC4/at8LCvDkjHG4O.nGY94exZiqjRxTJc87Qe4BFap1QhgNW','cliente',NULL,NULL,0,1,'2025-10-27 00:06:16',NULL,NULL),(10,'627acc09-0698-4379-849b-5d2fa43ce2ce','Usuario','Prueba','usuario.prueba@test.com','+573001234567','$2y$12$Yop4But6l2Mypc27SOHFneOsCnJ37cQ3ybUF4pV1gn/f9Lg4AIVUO','cliente',NULL,NULL,0,1,'2025-10-27 00:27:44',NULL,NULL),(11,'bd852c00-8127-49ab-a6b1-17bc1128f0cd','Conductor','Prueba','conductor.prueba@test.com','+573009876543','$2y$12$t5I6QV69PHlcY4ozF2G5wObcdn8MK6vOawu0U./aLdWvWrhfxNBvS','conductor',NULL,NULL,0,1,'2025-10-27 00:27:44',NULL,NULL),(12,'bdd5da21-bd46-421b-9995-d6cc91a18703','Usuario','Test','usuario.test@ping.go','+573000000000','$2y$12$hPQETI8DY5/d4z/l4umuRuKQ2.x5WzOtkteWxTLxfNHgYXeKpLjuC','cliente',NULL,NULL,0,1,'2025-10-27 00:34:39',NULL,NULL),(13,'user_69094c4af36515.15515353','usuario','oquendo','usuario@gmail.com','423432443','$2y$10$eRmX0cTeKUxCaqQC2WoymeSwt6vJYWVQc2E6a.Jc4t3owrT7FAglu','cliente',NULL,NULL,0,1,'2025-11-04 00:43:54',NULL,NULL);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios_backup_20251023`
--

DROP TABLE IF EXISTS `usuarios_backup_20251023`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios_backup_20251023` (
  `id` bigint unsigned NOT NULL DEFAULT '0',
  `uuid` varchar(255) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `hash_contrasena` varchar(255) NOT NULL,
  `tipo_usuario` enum('cliente','conductor','administrador') DEFAULT 'cliente',
  `url_imagen_perfil` varchar(500) DEFAULT NULL,
  `fecha_nacimiento` date DEFAULT NULL,
  `verificado` tinyint(1) DEFAULT '0',
  `activo` tinyint(1) DEFAULT '1',
  `creado_en` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `ultimo_acceso_en` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios_backup_20251023`
--

LOCK TABLES `usuarios_backup_20251023` WRITE;
/*!40000 ALTER TABLE `usuarios_backup_20251023` DISABLE KEYS */;
INSERT INTO `usuarios_backup_20251023` VALUES (1,'user_68daf618780e50.65802566','braian','oquendo','braianoquen@gmail.com','3013636902','$2y$10$H2Un4DmxCsM6XOGA1fiX8.5VB42Z9v8uwqERrGBms83dk2CQVQKnO','administrador',NULL,NULL,0,1,'2025-09-29 21:11:52','2025-10-22 14:16:12',NULL),(2,'user_68e44706c14db4.53994811','braian890','oquendo','braian890@gmail.com','32323232','$2y$10$NB9S4hWQLrK7HhTjc9yneu9RTb6otip3dtZ1muEgukWWLKcSpxRF6','cliente',NULL,NULL,0,1,'2025-10-06 22:47:34',NULL,NULL),(3,'user_68e44d12079086.97442308','braianoquen79','oquendo','braianoquen79@gmail.com','34343434','$2y$10$6LhMx5vHi.3LrrM/EjFjw.ZztZWhhGQgqf1sD76h2RtJ4B7nN/sjC','cliente',NULL,NULL,0,1,'2025-10-06 23:13:22',NULL,NULL),(4,'user_68f5142e614579.71603626','braianoquen323','oquendo','braianoquen323@gmail.com','213131313131','$2y$10$qSZ1igIQd1BQJmq.MRMwM.2EUfUYhvXhsf4g0h7GJJDJ8uaR66/qy','cliente',NULL,NULL,0,1,'2025-10-19 16:39:10',NULL,NULL),(5,'user_68f6b9b1f1cb28.57297864','braianoquen324','oquendo','braianoquen324@gmail.com','4274672','$2y$10$Oji7gxZcVki50Pyk5aReKexUhCGPbXLGNe.rsnlzAaZvI.Bo.UexS','cliente',NULL,NULL,0,1,'2025-10-20 22:37:37',NULL,NULL),(6,'user_68f8e56f0736b2.62296910','braianoquendurango','oquendo','braianoquendurango@gmail.com','323121','$2y$10$DDOIUEJ8jv1ILAu7PKj3LutCGRru.7sVUs2himDiKZ4yqY.VtvRb6','cliente',NULL,NULL,0,1,'2025-10-22 14:08:47',NULL,NULL),(7,'user_68f8e5efd5f888.59258279','braianoquen2','oqeundo','braianoquen2@gmail.com','3242442','$2y$10$DUUZdDrKiyespZGSJfk9JeGYuvOkAjrlMemg9BA/BZfyXlamgobjW','conductor',NULL,NULL,0,1,'2025-10-22 14:10:55','2025-10-22 14:15:38',NULL);
/*!40000 ALTER TABLE `usuarios_backup_20251023` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `verification_codes`
--

DROP TABLE IF EXISTS `verification_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `verification_codes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `code` varchar(6) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `used` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_email` (`email`),
  KEY `idx_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `verification_codes`
--

LOCK TABLES `verification_codes` WRITE;
/*!40000 ALTER TABLE `verification_codes` DISABLE KEYS */;
INSERT INTO `verification_codes` VALUES (1,'braianoquen@gmail.com','184773','2025-09-22 00:02:19','2025-09-22 05:12:19',0),(2,'braianoquen@gmail.com','740721','2025-09-22 00:40:36','2025-09-22 05:50:36',0),(3,'braianoquen@gmail.com','470836','2025-09-22 03:16:18','2025-09-22 08:26:18',0),(4,'braianoquen@gmail.com','553736','2025-09-22 03:32:16','2025-09-22 08:42:16',0),(5,'braianoquen@gmail.com','558786','2025-09-22 03:42:09','2025-09-22 08:52:09',0),(6,'braianoquen@gmail.com','871431','2025-09-22 03:44:25','2025-09-22 08:54:25',0),(7,'braianoquen@gmail.com','109811','2025-09-22 03:48:08','2025-09-22 08:58:08',0),(8,'braianoquen@gmail.com','895561','2025-09-22 04:05:48','2025-09-22 09:15:48',0),(9,'traconmaster@gmail.com','517375','2025-09-22 04:09:27','2025-09-22 09:19:27',0),(10,'tracongames2@gmail.com','439802','2025-09-22 04:29:37','2025-09-22 09:39:37',0),(11,'tracongames3@gmail.com','928041','2025-09-22 04:40:27','2025-09-22 09:50:27',0),(12,'braianoquen@gmail.com','471108','2025-09-22 04:50:52','2025-09-22 10:00:52',0),(13,'braianoquen@gmail.com','289263','2025-09-22 04:59:38','2025-09-22 10:09:38',0),(14,'tracon2@gmail.com','972225','2025-09-22 23:15:48','2025-09-23 04:25:48',0),(15,'braianoquen@gmail.com','532386','2025-09-22 23:17:22','2025-09-23 04:27:22',0),(16,'gellen@gmail.com','836288','2025-09-29 16:33:39','2025-09-29 21:43:39',0),(17,'gellen2@gmail.com','618398','2025-09-29 16:42:48','2025-09-29 21:52:48',0),(18,'gellen4@gmail.com','503956','2025-09-29 16:59:45','2025-09-29 22:09:45',0),(19,'gellen4@gmail.com','215305','2025-09-29 17:06:30','2025-09-29 22:16:30',0),(20,'gellen2@gmail.com','309347','2025-09-29 17:12:20','2025-09-29 22:22:20',0),(21,'gellen2@gmail.com','430759','2025-09-29 17:16:52','2025-09-29 22:26:52',0),(22,'gellen2@gmail.com','571778','2025-09-29 17:24:00','2025-09-29 22:34:00',0),(23,'gellen2@gmail.com','641077','2025-09-29 17:30:09','2025-09-29 22:40:09',0),(24,'gellen2@gmail.com','129852','2025-09-29 17:36:07','2025-09-29 22:46:07',0),(25,'gellen2@gmail.com','644993','2025-09-29 17:43:12','2025-09-29 22:53:12',0),(26,'gellen2@gmail.com','931663','2025-09-29 17:47:56','2025-09-29 22:57:56',0),(27,'gellen2@gmail.com','661112','2025-09-29 17:50:41','2025-09-29 23:00:41',0),(28,'gellen2@gmail.com','580543','2025-09-29 17:51:12','2025-09-29 23:01:12',0),(29,'gellen2@gmail.com','105869','2025-09-29 17:55:34','2025-09-29 23:05:34',0),(30,'gellen34@gmail.com','345823','2025-09-29 18:02:16','2025-09-29 23:12:16',0),(31,'gellen2@gmail.com','749371','2025-09-29 18:06:18','2025-09-29 23:16:18',0),(32,'gellen2@gmail.com','108467','2025-09-29 18:11:22','2025-09-29 23:21:22',0),(33,'gellen2@gmail.com','828608','2025-09-29 18:17:44','2025-09-29 23:27:44',0),(34,'andres80@gmail.com','263140','2025-09-29 19:18:28','2025-09-30 00:28:28',0),(35,'braianoquen@gmail.com','891517','2025-09-29 19:26:17','2025-09-30 00:36:17',0),(36,'braianoquen@gmail.com','557643','2025-09-29 19:37:35','2025-09-30 00:47:35',0),(37,'braianoquen@gmail.com','898296','2025-09-29 19:44:37','2025-09-30 00:54:37',0),(38,'braianoquen@gmail.com','750790','2025-09-29 20:11:50','2025-09-30 01:21:50',0),(39,'braianoquendurango@gmail.com','636850','2025-09-29 20:13:08','2025-09-30 01:23:08',0),(40,'braianoquendurango@gmail.com','619818','2025-09-29 20:23:00','2025-09-30 01:33:00',0),(41,'braianoquendurango@gmail.com','906593','2025-09-29 20:29:27','2025-09-30 01:39:27',0),(42,'braianoquen@gmail.com','824558','2025-09-29 20:31:55','2025-09-30 01:41:55',0),(43,'braianoquen@gmail.com','819688','2025-09-29 20:36:15','2025-09-30 01:46:15',0),(44,'braianoquen@gmail.com','311995','2025-09-29 20:37:09','2025-09-30 01:47:09',0),(45,'braianoquen@gmail.com','187066','2025-09-29 20:37:48','2025-09-30 01:47:48',0),(46,'braianoquen@gmail.com','501886','2025-09-29 20:55:37','2025-09-30 02:05:37',0),(47,'braianoquen@gmail.com','274084','2025-09-29 21:02:39','2025-09-30 02:12:39',0),(48,'braianoquen@gmail.com','614962','2025-09-29 21:08:06','2025-09-30 02:18:06',0),(49,'braianoquen@gmail.com','377184','2025-09-29 21:10:58','2025-09-30 02:20:58',0),(50,'braianoquendurango@gmail.com','940771','2025-10-05 12:31:26','2025-10-05 17:41:26',0),(51,'braianoquendurango@gmail.com','156648','2025-10-05 12:33:09','2025-10-05 17:43:09',0),(52,'braianoquendurango@gmail.com','360795','2025-10-05 13:14:57','2025-10-05 18:24:57',0),(53,'braianoquendurango@gmail.com','270293','2025-10-05 13:18:24','2025-10-05 18:28:24',0),(54,'braianoquendurango@gmail.com','366137','2025-10-05 13:22:20','2025-10-05 18:32:20',0),(55,'braianoquendurango@gmail.com','219856','2025-10-05 13:22:53','2025-10-05 18:32:53',0),(56,'braianoquendurango@gmail.com','246651','2025-10-05 13:43:15','2025-10-05 18:53:15',0),(57,'braianoquendurango@gmail.com','170449','2025-10-05 13:48:15','2025-10-05 18:58:15',0),(58,'braianoquendurango@gmail.com','897340','2025-10-05 13:53:37','2025-10-05 19:03:37',0),(59,'braianoquendurango@gmail.com','816291','2025-10-05 13:57:58','2025-10-05 19:07:58',0),(60,'braianoquendurango@gmail.com','834542','2025-10-05 14:02:31','2025-10-05 19:12:31',0),(61,'braianoquendurango@gmail.com','220660','2025-10-05 14:07:14','2025-10-05 19:17:14',0),(62,'braianoquendurango@gmail.com','527698','2025-10-05 16:34:49','2025-10-05 21:44:49',0),(63,'braianoquendurango@gmail.com','947445','2025-10-05 16:46:56','2025-10-05 21:56:56',0),(64,'braianoquendurango@gmail.com','687214','2025-10-05 17:05:14','2025-10-05 22:15:14',0),(65,'braianoquendurango@gmail.com','586620','2025-10-05 17:35:18','2025-10-05 22:45:18',0),(66,'braianoquendurango@gmail.com','476004','2025-10-05 17:42:10','2025-10-05 22:52:10',0),(67,'braianoquen@gmail.com','822586','2025-10-05 18:51:09','2025-10-06 00:01:09',0),(68,'braianoquen@gmail.com','768999','2025-10-05 20:15:24','2025-10-06 01:25:24',0),(69,'braianoquen@gmail.com','635063','2025-10-05 20:16:32','2025-10-06 01:26:32',0),(70,'braianoquen@gmail.com','663502','2025-10-05 20:31:20','2025-10-06 01:41:20',0),(71,'braianoquen@gmail.com','656436','2025-10-05 20:55:10','2025-10-06 02:05:10',0),(72,'braianoquen@gmail.com','950733','2025-10-06 22:42:36','2025-10-07 03:52:36',0),(73,'braianoquen@gmail.com','972074','2025-10-06 22:44:02','2025-10-07 03:54:02',0),(74,'braian890@gmail.com','174360','2025-10-06 22:45:51','2025-10-07 03:55:51',0),(75,'braianoquen@gmail.com','701975','2025-10-06 22:49:07','2025-10-07 03:59:07',0),(76,'braianoquen79@gmail.com','185834','2025-10-06 23:07:49','2025-10-07 04:17:49',0),(77,'braianoquen80@gmail.com','367890','2025-10-17 03:02:29','2025-10-17 08:12:29',0),(78,'braianoquen@gmail.com','893059','2025-10-17 12:40:14','2025-10-17 17:50:14',0),(79,'braianoquen@gmail.com','894968','2025-10-17 12:55:02','2025-10-17 18:05:02',0),(80,'braianoquen@gmail.com','342619','2025-10-17 13:18:43','2025-10-17 18:28:43',0),(81,'braianoquen@gmail.com','575878','2025-10-19 14:35:11','2025-10-19 19:45:11',0),(82,'braaian80@gmail.com','109667','2025-10-19 16:11:09','2025-10-19 21:21:09',0),(83,'braianoquen13231@gmail.com','881509','2025-10-19 16:30:14','2025-10-19 21:40:14',0),(84,'braianoquen323@gmail.com','700367','2025-10-19 16:37:32','2025-10-19 21:47:32',0),(85,'braianoquen324@gmail.com','648366','2025-10-20 22:33:07','2025-10-21 03:43:07',0),(86,'braianoquen2@gmail.com','245192','2025-10-22 14:05:51','2025-10-22 19:15:51',0),(87,'braianoquendurango@gmail.com','948056','2025-10-22 14:07:51','2025-10-22 19:17:51',0),(88,'braianoquen2@gmail.com','607965','2025-10-22 14:10:18','2025-10-22 19:20:18',0),(89,'braianoquen@gmail.com','108760','2025-10-22 14:37:06','2025-10-22 19:47:06',0),(90,'braianoquen2@gmail.com','578807','2025-10-24 11:11:08','2025-10-24 16:21:08',0);
/*!40000 ALTER TABLE `verification_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vista_precios_activos`
--

DROP TABLE IF EXISTS `vista_precios_activos`;
/*!50001 DROP VIEW IF EXISTS `vista_precios_activos`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vista_precios_activos` AS SELECT 
 1 AS `id`,
 1 AS `tipo_vehiculo`,
 1 AS `tarifa_base`,
 1 AS `costo_por_km`,
 1 AS `costo_por_minuto`,
 1 AS `tarifa_minima`,
 1 AS `tarifa_maxima`,
 1 AS `recargo_hora_pico`,
 1 AS `recargo_nocturno`,
 1 AS `recargo_festivo`,
 1 AS `descuento_distancia_larga`,
 1 AS `umbral_km_descuento`,
 1 AS `hora_pico_inicio_manana`,
 1 AS `hora_pico_fin_manana`,
 1 AS `hora_pico_inicio_tarde`,
 1 AS `hora_pico_fin_tarde`,
 1 AS `hora_nocturna_inicio`,
 1 AS `hora_nocturna_fin`,
 1 AS `comision_plataforma`,
 1 AS `comision_metodo_pago`,
 1 AS `distancia_minima`,
 1 AS `distancia_maxima`,
 1 AS `tiempo_espera_gratis`,
 1 AS `costo_tiempo_espera`,
 1 AS `activo`,
 1 AS `fecha_creacion`,
 1 AS `fecha_actualizacion`,
 1 AS `notas`,
 1 AS `periodo_actual`,
 1 AS `recargo_actual`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'viax'
--

--
-- Dumping routines for database 'viax'
--

--
-- Final view structure for view `vista_precios_activos`
--

/*!50001 DROP VIEW IF EXISTS `vista_precios_activos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vista_precios_activos` AS select `cp`.`id` AS `id`,`cp`.`tipo_vehiculo` AS `tipo_vehiculo`,`cp`.`tarifa_base` AS `tarifa_base`,`cp`.`costo_por_km` AS `costo_por_km`,`cp`.`costo_por_minuto` AS `costo_por_minuto`,`cp`.`tarifa_minima` AS `tarifa_minima`,`cp`.`tarifa_maxima` AS `tarifa_maxima`,`cp`.`recargo_hora_pico` AS `recargo_hora_pico`,`cp`.`recargo_nocturno` AS `recargo_nocturno`,`cp`.`recargo_festivo` AS `recargo_festivo`,`cp`.`descuento_distancia_larga` AS `descuento_distancia_larga`,`cp`.`umbral_km_descuento` AS `umbral_km_descuento`,`cp`.`hora_pico_inicio_manana` AS `hora_pico_inicio_manana`,`cp`.`hora_pico_fin_manana` AS `hora_pico_fin_manana`,`cp`.`hora_pico_inicio_tarde` AS `hora_pico_inicio_tarde`,`cp`.`hora_pico_fin_tarde` AS `hora_pico_fin_tarde`,`cp`.`hora_nocturna_inicio` AS `hora_nocturna_inicio`,`cp`.`hora_nocturna_fin` AS `hora_nocturna_fin`,`cp`.`comision_plataforma` AS `comision_plataforma`,`cp`.`comision_metodo_pago` AS `comision_metodo_pago`,`cp`.`distancia_minima` AS `distancia_minima`,`cp`.`distancia_maxima` AS `distancia_maxima`,`cp`.`tiempo_espera_gratis` AS `tiempo_espera_gratis`,`cp`.`costo_tiempo_espera` AS `costo_tiempo_espera`,`cp`.`activo` AS `activo`,`cp`.`fecha_creacion` AS `fecha_creacion`,`cp`.`fecha_actualizacion` AS `fecha_actualizacion`,`cp`.`notas` AS `notas`,(case when (curtime() between `cp`.`hora_pico_inicio_manana` and `cp`.`hora_pico_fin_manana`) then 'hora_pico_manana' when (curtime() between `cp`.`hora_pico_inicio_tarde` and `cp`.`hora_pico_fin_tarde`) then 'hora_pico_tarde' when ((curtime() >= `cp`.`hora_nocturna_inicio`) or (curtime() <= `cp`.`hora_nocturna_fin`)) then 'nocturno' else 'normal' end) AS `periodo_actual`,(case when (curtime() between `cp`.`hora_pico_inicio_manana` and `cp`.`hora_pico_fin_manana`) then `cp`.`recargo_hora_pico` when (curtime() between `cp`.`hora_pico_inicio_tarde` and `cp`.`hora_pico_fin_tarde`) then `cp`.`recargo_hora_pico` when ((curtime() >= `cp`.`hora_nocturna_inicio`) or (curtime() <= `cp`.`hora_nocturna_fin`)) then `cp`.`recargo_nocturno` else 0.00 end) AS `recargo_actual` from `configuracion_precios` `cp` where (`cp`.`activo` = 1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-08 17:12:46
