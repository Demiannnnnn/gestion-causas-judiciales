# Contexto del Proyecto para Gemini

## 1. Descripción General

- **Nombre**: Sistema de Gestión de Causas Judiciales.
- **Propósito**: Aplicación web para la gestión integral de causas judiciales, modernizando y digitalizando el proceso.
- **Arquitectura**: Sistema de microservicios orquestado a través de `docker-compose.yml`.

## 2. Stack Tecnológico

- **Backend**: Microservicios en Python con el framework **Flask** y **Flask-SQLAlchemy**.
- **Frontend**: Aplicación de una sola página (SPA) con **React** y **Bootstrap**.
- **Base de Datos**: **MySQL 8** para la persistencia principal.
- **Caché**: **Redis** para almacenamiento en caché.
- **API Gateway**: **Traefik** para enrutar las peticiones a los diferentes microservicios.
- **Orquestación**: **Docker Compose**.
- **Monitoreo**: **Prometheus** y **Grafana**.

## 3. Estructura del Proyecto

El proyecto está organizado en una arquitectura de microservicios contenerizada con Docker.

### 3.1. Backend (`/backend`)

Consiste en varios microservicios de Flask:

- **`autenticacion`**: Gestiona el registro, inicio de sesión y autenticación de usuarios usando JWT.
- **`casos`**: Lógica de negocio principal para la gestión de las causas judiciales.
- **`documentos`**: Maneja la subida y gestión de archivos PDF asociados a las causas.
- **`notificaciones`**: Envía notificaciones (posiblemente por email, a juzgar por la configuración).

Cada microservicio tiene su propio `Dockerfile` y `requirements.txt`.

### 3.2. Frontend (`/frontend`)

- Es una aplicación React (`create-react-app`).
- Utiliza `react-router-dom` para la navegación del lado del cliente.
- La interfaz de usuario está estilizada con `Bootstrap`.
- Se comunica con los microservicios del backend a través del API Gateway.
- El archivo `src/components/` contiene los principales componentes de React, como `Casos.js`, `Login.js`, etc.

### 3.3. Base de Datos (`/db`)

- Se utiliza **MySQL 8** como base de datos relacional.
- El script `db/mysql/init.sql` inicializa el esquema de la base de datos y datos iniciales.

### 3.4. Orquestación y Enrutamiento

- **Docker Compose (`docker-compose.yml`)**: Define y orquesta todos los servicios, redes y volúmenes.
- **Traefik (`gateway`)**: Actúa como un reverse proxy y API gateway, enrutando las peticiones entrantes al servicio correspondiente (frontend o backend) basado en el path (`/api/...`) o el host.

### 3.5. Monitoreo (`/monitoring`)

- **Prometheus**: Recolecta métricas de los servicios.
- **Grafana**: Permite visualizar las métricas recolectadas por Prometheus a través de dashboards.

## 4. Historial de Cambios Recientes

### Corrección de error en `Casos.js`
- **Problema**: La aplicación fallaba con un error `useState is not defined` en la consola del navegador.
- **Causa**: Los hooks `useState` y `useEffect` de React se utilizaban en el componente `Casos.js` sin haber sido importados.
- **Solución**: Se añadió la importación explícita `{ useState, useEffect }` desde la librería `'react'` en el archivo `frontend/src/components/Casos.js`.
