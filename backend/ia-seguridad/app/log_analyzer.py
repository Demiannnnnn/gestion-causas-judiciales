import docker
import google.generativeai as genai
from openai import OpenAI
import os
import logging
from datetime import datetime, timedelta
import re
import time

logger = logging.getLogger(__name__)


class LogAnalyzer:
    """Analiza logs de contenedores usando IA"""
    
    def __init__(self):
        self.docker_client = docker.from_env()
        
        # Rate limiting para Gemini Free Tier: 15 RPM
        self.last_request_time = 0
        self.min_request_interval = 5  # 5 segundos entre requests = 12 RPM (deja margen)
        self.max_containers_per_batch = 5  # Analizar máximo 5 contenedores a la vez
        
        # Configurar Gemini
        gemini_api_key = os.getenv('GEMINI_API_KEY')
        if gemini_api_key:
            genai.configure(api_key=gemini_api_key)
            # Usar gemini-2.0-flash-lite que tiene más requests gratuitos
            self.gemini_model = genai.GenerativeModel('gemini-2.0-flash-lite')
            logger.info("Gemini configurado con modelo: gemini-2.0-flash-lite")
            logger.info(f"Rate limiting activado: {self.min_request_interval}s entre requests, max {self.max_containers_per_batch} contenedores por lote")
        else:
            self.gemini_model = None
            logger.warning("GEMINI_API_KEY no configurada")
        
        # Configurar OpenAI
        openai_api_key = os.getenv('OPENAI_API_KEY')
        if openai_api_key:
            self.openai_client = OpenAI(api_key=openai_api_key)
        else:
            self.openai_client = None
            logger.warning("OPENAI_API_KEY no configurada")
    
    def get_container_logs(self, container_name, since='1h'):
        """Obtiene logs de un contenedor"""
        try:
            container = self.docker_client.containers.get(container_name)
            
            # Obtener los últimos logs (tail) en lugar de usar since
            # Esto asegura que siempre obtengamos logs incluso si el contenedor lleva tiempo sin actividad
            logs = container.logs(
                tail=1000,  # Últimas 1000 líneas
                timestamps=True
            ).decode('utf-8', errors='ignore')
            
            return logs
            
        except docker.errors.NotFound:
            logger.error(f"Contenedor {container_name} no encontrado")
            return None
        except Exception as e:
            logger.error(f"Error obteniendo logs de {container_name}: {str(e)}")
            return None
    
    def _parse_time_string(self, time_str):
        """Convierte string de tiempo (1h, 30m) a segundos"""
        match = re.match(r'(\d+)([hms])', time_str)
        if not match:
            return 3600  # Por defecto 1 hora
        
        value, unit = match.groups()
        value = int(value)
        
        if unit == 'h':
            return value * 3600
        elif unit == 'm':
            return value * 60
        elif unit == 's':
            return value
        
        return 3600
    
    def _rate_limit_wait(self):
        """Espera el tiempo necesario para respetar rate limits"""
        current_time = time.time()
        time_since_last_request = current_time - self.last_request_time
        
        if time_since_last_request < self.min_request_interval:
            wait_time = self.min_request_interval - time_since_last_request
            logger.info(f"Rate limiting: esperando {wait_time:.2f}s antes de siguiente request")
            time.sleep(wait_time)
        
        self.last_request_time = time.time()
    
    def analyze_with_gemini(self, logs, container_name):
        """Analiza logs usando Gemini AI con rate limiting"""
        if not self.gemini_model:
            # Modo de respaldo: análisis básico sin IA
            return self._basic_log_analysis(logs, container_name)
        
        try:
            # RATE LIMITING: Esperar antes de hacer request
            self._rate_limit_wait()
            
            # Limitar tamaño de logs para enviar a la IA
            max_log_size = 10000
            if len(logs) > max_log_size:
                logs = logs[-max_log_size:]
            
            prompt = f"""
Eres un experto en análisis de logs y seguridad de sistemas. Analiza los siguientes logs del contenedor '{container_name}' y proporciona:

1. **Resumen**: Breve descripción del estado del contenedor
2. **Problemas Detectados**: Lista de errores, warnings o problemas encontrados
3. **Nivel de Severidad**: Para cada problema (bajo, medio, alto, crítico)
4. **Recomendaciones**: Acciones sugeridas para resolver problemas
5. **Patrones Sospechosos**: Comportamientos anómalos o potenciales amenazas de seguridad

LOGS:
```
{logs}
```

Responde en formato estructurado y claro.
"""
            
            response = self.gemini_model.generate_content(prompt)
            analysis_text = response.text
            
            # Parsear respuesta para extraer issues críticos
            critical_issues = self._extract_critical_issues(analysis_text, container_name)
            
            return {
                "analysis": analysis_text,
                "critical_issues": critical_issues,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error en análisis con Gemini: {str(e)}")
            # Si falla la IA, usar análisis básico
            return self._basic_log_analysis(logs, container_name)
    
    def analyze_with_openai(self, logs, container_name):
        """Analiza logs usando OpenAI"""
        if not self.openai_client:
            # Modo de respaldo: análisis básico sin IA
            return self._basic_log_analysis(logs, container_name)
        
        try:
            # Limitar tamaño de logs para enviar a la IA
            max_log_size = 10000
            if len(logs) > max_log_size:
                logs = logs[-max_log_size:]
            
            prompt = f"""
Eres un experto en análisis de logs y seguridad de sistemas. Analiza los siguientes logs del contenedor '{container_name}' y proporciona:

1. **Resumen**: Breve descripción del estado del contenedor
2. **Problemas Detectados**: Lista de errores, warnings o problemas encontrados
3. **Nivel de Severidad**: Para cada problema (bajo, medio, alto, crítico)
4. **Recomendaciones**: Acciones sugeridas para resolver problemas
5. **Patrones Sospechosos**: Comportamientos anómalos o potenciales amenazas de seguridad

LOGS:
```
{logs}
```

Responde en formato estructurado y claro.
"""
            
            response = self.openai_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "Eres un experto en análisis de logs y seguridad de sistemas."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=1500
            )
            
            analysis_text = response.choices[0].message.content
            
            # Parsear respuesta para extraer issues críticos
            critical_issues = self._extract_critical_issues(analysis_text, container_name)
            
            return {
                "analysis": analysis_text,
                "critical_issues": critical_issues,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error en análisis con OpenAI: {str(e)}")
            # Si falla la IA, usar análisis básico
            return self._basic_log_analysis(logs, container_name)
    
    def _basic_log_analysis(self, logs, container_name):
        """Análisis básico de logs sin IA (modo respaldo)"""
        try:
            lines = logs.split('\n')
            errors = [line for line in lines if 'error' in line.lower() or 'exception' in line.lower()]
            warnings = [line for line in lines if 'warning' in line.lower() or 'warn' in line.lower()]
            criticals = [line for line in lines if 'critical' in line.lower() or 'fatal' in line.lower()]
            
            analysis = f"""
**ANÁLISIS BÁSICO DE LOGS - {container_name}**
(Modo sin IA - API Key no disponible)

**Resumen:**
- Total de líneas analizadas: {len(lines)}
- Errores encontrados: {len(errors)}
- Warnings encontrados: {len(warnings)}
- Mensajes críticos: {len(criticals)}

**Problemas Detectados:**
"""
            
            if criticals:
                analysis += "\n**CRÍTICO:**\n"
                for critical in criticals[:5]:
                    analysis += f"- {critical.strip()}\n"
            
            if errors:
                analysis += "\n**ERRORES:**\n"
                for error in errors[:10]:
                    analysis += f"- {error.strip()}\n"
            
            if warnings:
                analysis += "\n**WARNINGS:**\n"
                for warning in warnings[:5]:
                    analysis += f"- {warning.strip()}\n"
            
            if not errors and not warnings and not criticals:
                analysis += "\n✅ No se detectaron problemas evidentes en los logs recientes."
            
            analysis += "\n\n**Recomendación:** Configure una API key válida de Gemini para obtener análisis detallados con IA."
            
            critical_issues = []
            for critical in criticals[:3]:
                critical_issues.append({
                    "title": f"Problema crítico en {container_name}",
                    "description": critical.strip(),
                    "container": container_name,
                    "severity": "critical"
                })
            
            return {
                "analysis": analysis,
                "critical_issues": critical_issues,
                "timestamp": datetime.now().isoformat(),
                "mode": "basic"
            }
        except Exception as e:
            logger.error(f"Error en análisis básico: {str(e)}")
            return {
                "error": str(e),
                "analysis": "No se pudo realizar el análisis",
                "critical_issues": []
            }
    
    def _extract_critical_issues(self, analysis_text, container_name):
        """Extrae problemas críticos del análisis"""
        critical_issues = []
        
        # Buscar palabras clave de problemas críticos
        critical_keywords = [
            'crítico', 'critical', 'error fatal', 'down', 'caído',
            'no responde', 'timeout', 'failed', 'crashed'
        ]
        
        lines = analysis_text.lower().split('\n')
        for line in lines:
            if any(keyword in line for keyword in critical_keywords):
                critical_issues.append({
                    "title": f"Problema crítico en {container_name}",
                    "description": line.strip(),
                    "container": container_name,
                    "severity": "critical"
                })
        
        return critical_issues[:5]  # Máximo 5 issues críticos
    
    def analyze_containers(self, container_names=None, since='1h', ai_provider='gemini'):
        """
        Analiza logs de múltiples contenedores con rate limiting
        
        Args:
            container_names: Lista de nombres de contenedores. Si está vacío, analiza solo los más importantes
            since: Tiempo atrás para obtener logs (1h, 30m, 24h)
            ai_provider: Proveedor de IA (gemini, openai)
        
        Returns:
            dict con resultados del análisis
        """
        try:
            # Si no se especifican contenedores, analizar solo los más críticos
            if not container_names:
                # Contenedores prioritarios para análisis automático
                priority_containers = [
                    'db-master', 'db-slave', 'proxysql',
                    'redis', 'redis-replica',
                    'gateway'
                ]
                
                # Obtener todos los contenedores
                all_containers = self.docker_client.containers.list()
                all_container_names = [c.name for c in all_containers]
                
                # Filtrar solo los prioritarios que existan
                container_names = [name for name in priority_containers if name in all_container_names]
                
                logger.info(f"Análisis automático: limitado a {len(container_names)} contenedores prioritarios")
            
            # LÍMITE DE LOTE: Analizar máximo N contenedores a la vez
            if len(container_names) > self.max_containers_per_batch:
                logger.warning(f"Solicitados {len(container_names)} contenedores, limitando a {self.max_containers_per_batch}")
                container_names = container_names[:self.max_containers_per_batch]
            
            results = {
                "containers_analyzed": [],
                "critical_issues": [],
                "warnings": [],
                "summary": {},
                "rate_limited": len(container_names) > self.max_containers_per_batch
            }
            
            logger.info(f"Analizando {len(container_names)} contenedores con {ai_provider}")
            
            for i, container_name in enumerate(container_names, 1):
                logger.info(f"[{i}/{len(container_names)}] Analizando contenedor: {container_name}")
                
                # Obtener logs
                logs = self.get_container_logs(container_name, since)
                
                if not logs:
                    results["warnings"].append(f"No se pudieron obtener logs de {container_name}")
                    continue
                
                # Analizar con IA
                if ai_provider == 'gemini':
                    analysis = self.analyze_with_gemini(logs, container_name)
                elif ai_provider == 'openai':
                    analysis = self.analyze_with_openai(logs, container_name)
                else:
                    analysis = {"analysis": "Proveedor de IA no soportado"}
                
                # Agregar resultados
                results["containers_analyzed"].append({
                    "name": container_name,
                    "analysis": analysis.get("analysis", ""),
                    "log_size": len(logs),
                    "mode": analysis.get("mode", "ai")
                })
                
                # Agregar issues críticos
                if "critical_issues" in analysis:
                    results["critical_issues"].extend(analysis["critical_issues"])
            
            # Generar resumen
            results["summary"] = {
                "total_containers": len(container_names),
                "analyzed": len(results["containers_analyzed"]),
                "critical_issues_found": len(results["critical_issues"]),
                "warnings": len(results["warnings"]),
                "timestamp": datetime.now().isoformat(),
                "rate_limit_info": {
                    "min_interval_seconds": self.min_request_interval,
                    "max_batch_size": self.max_containers_per_batch
                }
            }
            
            return results
            
        except Exception as e:
            logger.error(f"Error en análisis de contenedores: {str(e)}")
            return {
                "error": str(e),
                "containers_analyzed": [],
                "critical_issues": []
            }
    
    def get_error_patterns(self, logs):
        """Detecta patrones de errores comunes en los logs"""
        patterns = {
            "connection_errors": r"(connection.*refused|connection.*timeout|unable to connect)",
            "memory_errors": r"(out of memory|memory.*exceeded|oom)",
            "permission_errors": r"(permission denied|access denied|forbidden)",
            "database_errors": r"(database.*error|sql.*error|query.*failed)",
            "timeout_errors": r"(timeout|timed out|deadline exceeded)",
            "crash_errors": r"(crash|segfault|core dump)"
        }
        
        detected_patterns = {}
        
        for pattern_name, pattern_regex in patterns.items():
            matches = re.findall(pattern_regex, logs, re.IGNORECASE)
            if matches:
                detected_patterns[pattern_name] = len(matches)
        
        return detected_patterns
