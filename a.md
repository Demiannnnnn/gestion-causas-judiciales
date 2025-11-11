
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
3.4. Alta Disponibilidad (HA)
¥REQUISITO OBLIGATORIO
1. Replicaci ́on de Base de Datos
✓ Al menos UNA base de datos con r ́eplicas
✓ Configuraci ́on maestro-esclavo o replica set
✓ Failover autom ́atico configurado
Opciones:
PostgreSQL: Streaming Replication (1 master + 1 replica)
MySQL/MariaDB: Master-Slave
MongoDB: Replica Set (3 nodos)
Redis: Sentinel (1 master + 2 replicas + 3 sentinels)
2. Replicaci ́on de Servicios
✓ Al menos 2 servicios cr ́ıticos con m ́ultiples instancias
✓ Load balancer para distribuir tr ́afico
✓ El sistema debe seguir funcionando si cae una r ́eplica
3. Demostraci ́on
Deben mostrar durante la presentaci ́on (y en el documento):
Sistema funcionando con todas las r ́eplicas
Apagar manualmente una r ́eplica o nodo
Sistema sigue operando
R ́eplica se recupera autom ́aticamente
6
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
3.5. Sistema de respaldos
¥REQUISITO OBLIGATORIO
Deben implementar:
1. Scripts de Backup
Script para respaldar base(s) de datos
Script para respaldar archivos (si aplica)
Backups comprimidos
Almacenamiento en volumen externo
2. Automatizaci ́on
Cron job dentro de contenedor
Ejecuta backup diariamente
Retiene  ́ultimos 7 d ́ıas m ́ınimo
3. Recuperaci ́on
Script de restore
Instrucciones paso a paso
Prueba exitosa documentada
Archivos requeridos:
scripts/backup/
backup-db.sh
backup-files.sh (si aplica)
restore-db.sh
README.md
3.6. Monitoreo
ò Informaci ́on
Elijan UNA opci ́on:
1. Prometheus + Grafana
M ́etricas de servicios
Dashboard visual
2. ELK Stack
Logs centralizados
B ́usqueda y an ́alisis
3. Portainer + Logs
Gesti ́on visual de contenedores
Visualizaci ́on de logs
Requisitos m ́ınimos:
Dashboard web accesible
Ver estado de servicios
Consultar logs
7
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
3.7. Integraci ́on de Inteligencia Artificial
 ̆Inteligencia Artificial
Cada equipo debe integrar al menos UNA funcionalidad de IA relevante a su
licitaci ́on.
El componente IA debe:
✓ Resolver un problema real del sistema licitado
✓ Estar containerizado como servicio independiente
✓ Tener API REST para comunicaci ́on
✓ Estar integrado al flujo del sistema
✓ Estar documentado con casos de uso
Opciones de implementaci ́on (elegir seg ́un licitaci ́on):
1. Chatbot / Asistente Virtual
Para atenci ́on de usuarios, FAQs, soporte
LLM local (Ollama) o API externa (OpenAI, Anthropic)
Ejemplos: consultar estado de tr ́amites, responder preguntas frecuentes
2. Clasificaci ́on Autom ́atica
Clasificar documentos, tickets, solicitudes
Asignar categor ́ıas autom ́aticamente
Detectar urgencia o prioridad
3. An ́alisis de Texto
An ́alisis de sentimiento
Extracci ́on de informaci ́on
Generaci ́on de res ́umenes
4. OCR y Procesamiento de Documentos
Extraer texto de documentos escaneados
Validar informaci ́on autom ́aticamente
5. B ́usqueda Inteligente (RAG)
Base de conocimientos con b ́usqueda sem ́antica
Respuestas basadas en documentaci ́on
Vector database (Qdrant, Chroma, Weaviate)
6. Model Context Protocol (MCP)
Servidor MCP con herramientas del sistema
LLM puede ejecutar funciones (consultas, crear registros)
Integraci ́on avanzada con el backend
8
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
3.8. Presupuesto y cotizaci ́on
¥REQUISITO OBLIGATORIO
OBLIGATORIO - An ́alisis Econ ́omico
Como parte de la propuesta a la licitaci ́on, deben incluir un presupuesto deta-
llado en la documentaci ́on.
El presupuesto debe incluir:
1. Costos de Desarrollo (estimaci ́on)
Horas de trabajo por rol (infraestructura, backend, frontend)
Valor hora por rol
Tiempo estimado del proyecto
2. Costos de Infraestructura (a ̃no 1)
Servidores (estimaci ́on seg ́un recursos necesarios)
Almacenamiento
Ancho de banda
Licencias (si aplica, aunque recomendamos open-source)
3. Costos de Operaci ́on y Mantenimiento (anual)
Soporte t ́ecnico
Actualizaciones y mantenci ́on
Monitoreo
Respaldos y recuperaci ́on
4. Costos del Componente IA
API externa (si usan OpenAI/Anthropic): costo mensual estimado
O infraestructura para LLM local
Entrenamiento/fine-tuning (si aplica)
Precio Final de la Propuesta:
L Precio total de implementaci ́on (una vez)
L Precio de mantenimiento (anual)
Justificaci ́on del precio
Comparaci ́on con alternativas del mercado (opcional)
Formato de entrega:
Documento PDF: docs/presupuesto.pdf
O secci ́on en README.md con tabla de costos
Valores en pesos chilenos (CLP)
Nota: Pueden investigar tarifas reales del mercado chileno de desarrollo de software
para hacer estimaciones realistas.
9
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
4. Paso 3: ¿Qu ́e entregar?
4.1. C ́odigo fuente
Repositorio Git (GitHub o GitLab) con:
proyecto/
README.md (documentaci ́on principal)
docker-compose.yml
.env.example
.gitignore
docs/ (documentaci ́on t ́ecnica)
arquitectura.md
licitacion/
diagramas/
presupuesto.md
services/ (c ́odigo de cada servicio)
frontend/
api-gateway/
servicio-1/
servicio-2/
ai-service/
infrastructure/ (configs de BD, cach ́e, etc)
database/
redis/
monitoring/
scripts/ (backup, init, tests)
backup/
4.2. Documentaci ́on (README.md)
El README.md debe explicar:
1. ¿Qu ́e es el proyecto?
Licitaci ́on elegida
Qu ́e resuelve el sistema
Integrantes del equipo
2. Arquitectura
Diagrama de arquitectura
Lista de servicios y qu ́e hace cada uno
Tecnolog ́ıas usadas y por qu ́e
3. Alta Disponibilidad
Qu ́e servicios est ́an replicados
C ́omo funciona el failover
4. Componente IA
10
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
Qu ́e hace
Por qu ́e es  ́util para la licitaci ́on
C ́omo usarlo
5. C ́omo usarlo
Requisitos (Docker version, RAM, etc)
Instrucciones paso a paso para levantar
URLs de acceso
Usuarios y contrase ̃nas de prueba
Comandos  ́utiles
6. Backup y Monitoreo
C ́omo ejecutar backup
C ́omo hacer restore
C ́omo acceder al monitoreo
4.3. Diagramas
Incluir en docs/diagramas/:
Arquitectura general: todos los servicios y c ́omo se relacionan
Redes Docker: qu ́e servicios en cada red
Alta disponibilidad: r ́eplicas y load balancers
Herramientas: Draw.io, Excalidraw, Lucidchart
4.4. Defensa del proyecto
Duraci ́on: 15 minutos
Contenido:
1. Introducci ́on (2 min)
Equipo
Licitaci ́on elegida
Qu ́e construyeron
2. Arquitectura (2 min)
Mostrar diagrama
Explicar microservicios
Justificar decisiones
3. Demo del Sistema (3 min)
Levantar con docker-compose
Navegar por el frontend
Usar funcionalidad principal
Mostrar componente IA funcionando
4. Alta Disponibilidad (2 min)
Mostrar r ́eplicas activas
Tumbar un servicio
Demostrar que sigue funcionando
5. Monitoreo y Backup (1 min)
Mostrar dashboard
11
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
Ejecutar backup
6. Preguntas (5 min)
Responder a las preguntas o realizar cambios sugeridos por el profesor
4.5. Sistema funcional
¥Checklist
El sistema debe:
✓ Levantar con: docker-compose up -d
✓ Todos los servicios corriendo correctamente
✓ Frontend accesible en navegador
✓ Backend respondiendo
✓ Autenticaci ́on funcionando
✓ Al menos una funcionalidad completa (CRUD)
✓ Base de datos con datos de prueba
✓ Replicaci ́on de BD funcionando
✓ M ́ultiples r ́eplicas de servicios activas
✓ IA funcionando y demostrable
✓ Monitoreo accesible
✓ Backup ejecutable
5. ¿C ́omo se eval ́ua?
5.1. Roles sugeridos (3 integrantes)
Estudiante 1: Infraestructura
Docker Compose
Redes y vol ́umenes
Alta disponibilidad
Backup
Estudiante 2: Backend
Microservicios
Bases de datos
Replicaci ́on de BD
APIs
Estudiante 3: Frontend y AI
Interfaz web
Componente IA
Documentaci ́on
Testing
Nota: Todos deben entender toda la arquitectura, no solo su parte.
12
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
Aspecto Puntos
1. An ́alisis y Dise ̃no 20 %
- Buena elecci ́on de licitaci ́on 5 %
- Arquitectura bien dise ̃nada seg ́un requisitos 5 %
- Microservicios bien justificados 5 %
- Diagramas claros 5 %
2. Docker y Containerizaci ́on 20 %
- Dockerfiles correctos 7 %
- Docker Compose bien configurado 7 %
- Redes, vol ́umenes y variables correctos 6 %
3. Alta Disponibilidad 20 %
- Replicaci ́on de BD funcional 8 %
- M ́ultiples r ́eplicas de servicios 6 %
- Load balancing 6 %
4. Backup y Recuperaci ́on 15 %
- Sistema de backup automatizado 8 %
- Restore probado y documentado 7 %
5. Componente de IA 15 %
- Funcional y bien integrado 7 %
- Relevante para la licitaci ́on 5 %
- Bien documentado 3 %
6. Monitoreo 5 %
- Sistema de monitoreo implementado 5 %
7. Documentaci ́on y Presentaci ́on 5 %
- README completo 2 %
- Video demo claro 2 %
- C ́odigo limpio 1 %
TOTAL 100 %
6. Reglas y Restricciones
6.1. Permitido
✓ Cualquier lenguaje de programaci ́on
✓ Cualquier framework web
✓ Software open-source o gratuito
✓ Trabajar en local o en servidores Proxmox
6.2. NO Permitido
; Usar tag :latest en producci ́on
; Subir contrase ̃nas a git
; Exponer bases de datos directamente
13
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
7. Referencias
7.1. Sitios Web
Mercado P ́ublico: https://www.mercadopublico.cl
Docker Docs: https://docs.docker.com
Docker Compose: https://docs.docker.com/compose/
Ollama (IA local): https://ollama.ai
7.2. Herramientas
Docker: Docker Desktop (Windows/Mac) o Docker Engine (Linux)
Editor: VS Code con extensi ́on Docker
Diagramas: Draw.io, Excalidraw
Test APIs: Postman, Insomnia
Gesti ́on Docker: Portainer (opcional)
8. Preguntas frecuentes
P: ¿Cu ́antos microservicios exactamente?
R: M ́ınimo 3 de aplicaci ́on. El total depende de tu licitaci ́on, pero el sistema completo
debe tener 5-10 servicios (incluyendo BD, frontend, etc).
P: ¿Debo implementar todo lo que pide la licitaci ́on?
R: No. Solo las funcionalidades principales para demostrar la arquitectura. El foco es la
infraestructura.
P: ¿Puedo usar tecnolog ́ıas diferentes a las mencionadas?
R: S ́ı, siempre que justifiques por qu ́e.
P: ¿Qu ́e pasa si mi licitaci ́on es muy simple?
R: Busca otra m ́as compleja. Debe justificar una arquitectura de microservicios.
P: ¿La IA debe estar relacionada con la licitaci ́on?
R: S ́ı. Debe resolver un problema real del sistema. Documenta por qu ́e es  ́util.
P: ¿C ́omo demuestro la alta disponibilidad?
R: Muestre las r ́eplicas corriendo, det ́en una. Si todo es correcto, deber ́ıa seguir el sistema
funcionando.
P: ¿Puedo cambiar de licitaci ́on despu ́es de Semana 1?
R: Solo con aprobaci ́on del profesor y justificaci ́on v ́alida. Por eso se selecciona el 20 de
Octubre.
Recomendaciones Finales
1. Empiecen temprano - 3 semanas pasa r ́apido
2. Elijan bien la licitaci ́on - ni muy simple ni imposible
3. Dise ̃nen antes de programar - la arquitectura es clave
4. Dividan el trabajo - aprovechen los 3 integrantes
14
Universidad de Talca - ICC Proyecto U2 - Administraci ́on de Redes
5. Usen Git desde d ́ıa 1 - facilita colaboraci ́on
6. Documenten sobre la marcha - no lo dejen para el final
7. Prueben frecuentemente - no esperen al  ́ultimo d ́ıa
8. Justifiquen decisiones - por qu ́e es importante
9. Pidan ayuda - mejor preguntar que quedarse atascados