import docker
import logging
from datetime import datetime
from typing import List, Dict
import psutil

logger = logging.getLogger(__name__)


class HealthMonitor:
    """Monitorea la salud y detecta anomalías en contenedores"""
    
    def __init__(self):
        self.docker_client = docker.from_env()
        self.baseline_metrics = {}
        # Lista de contenedores esperados (se actualiza dinámicamente)
        self.expected_containers = set()
    
    def check_container_health(self, container_name: str) -> Dict:
        """Verifica la salud de un contenedor específico"""
        try:
            container = self.docker_client.containers.get(container_name)
            
            # Obtener estadísticas
            stats = container.stats(stream=False)
            
            # Calcular uso de CPU
            cpu_delta = stats['cpu_stats']['cpu_usage']['total_usage'] - \
                       stats['precpu_stats']['cpu_usage']['total_usage']
            system_delta = stats['cpu_stats']['system_cpu_usage'] - \
                          stats['precpu_stats']['system_cpu_usage']
            cpu_percent = (cpu_delta / system_delta) * 100.0 if system_delta > 0 else 0.0
            
            # Calcular uso de memoria
            memory_usage = stats['memory_stats'].get('usage', 0)
            memory_limit = stats['memory_stats'].get('limit', 1)
            memory_percent = (memory_usage / memory_limit) * 100.0 if memory_limit > 0 else 0.0
            
            # Estado del contenedor
            container_status = container.status
            health_status = container.attrs.get('State', {}).get('Health', {}).get('Status', 'unknown')
            
            return {
                "name": container_name,
                "status": container_status,
                "health": health_status,
                "cpu_percent": round(cpu_percent, 2),
                "memory_usage_mb": round(memory_usage / (1024 * 1024), 2),
                "memory_percent": round(memory_percent, 2),
                "restart_count": container.attrs['RestartCount'],
                "created": container.attrs['Created'],
                "is_healthy": container_status == 'running' and cpu_percent < 80 and memory_percent < 80
            }
            
        except docker.errors.NotFound:
            logger.error(f"Contenedor {container_name} no encontrado")
            return {
                "name": container_name,
                "status": "not_found",
                "is_healthy": False
            }
        except Exception as e:
            logger.error(f"Error checkeando salud de {container_name}: {str(e)}")
            return {
                "name": container_name,
                "status": "error",
                "error": str(e),
                "is_healthy": False
            }
    
    def check_all_containers(self) -> List[Dict]:
        """Verifica la salud de todos los contenedores"""
        containers = self.docker_client.containers.list()
        health_data = []
        
        for container in containers:
            health = self.check_container_health(container.name)
            health_data.append(health)
        
        return health_data
    
    def update_expected_containers(self):
        """Actualiza la lista de contenedores esperados basándose en los contenedores running y stopped"""
        try:
            # Obtener TODOS los contenedores (running + stopped + exited)
            all_containers = self.docker_client.containers.list(all=True)
            # Filtrar solo los contenedores que no son de inicialización (config-init, db-init)
            self.expected_containers = {
                c.name for c in all_containers 
                if not c.name.startswith('config-init') and c.name != 'db-init'
            }
            logger.info(f"Contenedores esperados actualizados: {len(self.expected_containers)} contenedores")
        except Exception as e:
            logger.error(f"Error actualizando contenedores esperados: {str(e)}")
    
    def detect_anomalies(self, container_names: List[str] = None) -> List[Dict]:
        """
        Detecta anomalías en el comportamiento de contenedores
        
        Args:
            container_names: Lista de contenedores a analizar. Si está vacío, analiza todos
        
        Returns:
            Lista de anomalías detectadas
        """
        anomalies = []
        
        # Actualizar lista de contenedores esperados
        self.update_expected_containers()
        
        # Si no se especifican contenedores, usar los esperados
        if not container_names:
            container_names = list(self.expected_containers)
        
        # Obtener contenedores actualmente en ejecución
        running_containers = {c.name for c in self.docker_client.containers.list()}
        
        # Detectar contenedores caídos (esperados pero no running)
        missing_containers = self.expected_containers - running_containers
        for container_name in missing_containers:
            try:
                # Verificar el estado real del contenedor
                container = self.docker_client.containers.get(container_name)
                status = container.status
                
                anomalies.append({
                    "type": "container_down",
                    "container": container_name,
                    "severity": "critical",
                    "description": f"Contenedor {container_name} no está en ejecución (estado: {status})",
                    "timestamp": datetime.now().isoformat()
                })
                logger.warning(f"Contenedor caído detectado: {container_name} (estado: {status})")
            except docker.errors.NotFound:
                anomalies.append({
                    "type": "container_missing",
                    "container": container_name,
                    "severity": "critical",
                    "description": f"Contenedor {container_name} no existe en el sistema",
                    "timestamp": datetime.now().isoformat()
                })
                logger.warning(f"Contenedor faltante detectado: {container_name}")
        
        # Analizar contenedores en ejecución
        # Analizar contenedores en ejecución
        for container_name in container_names:
            if container_name not in running_containers:
                continue  # Ya lo analizamos arriba como contenedor caído
                
            health = self.check_container_health(container_name)
            
            # Detectar contenedor en mal estado
            if health.get('status') not in ['running', 'restarting']:
                anomalies.append({
                    "type": "container_down",
                    "container": container_name,
                    "severity": "critical",
                    "description": f"Contenedor {container_name} no está en ejecución (estado: {health.get('status')})",
                    "timestamp": datetime.now().isoformat()
                })
            
            # Detectar alto uso de CPU
            if health.get('cpu_percent', 0) > 80:
                anomalies.append({
                    "type": "high_cpu_usage",
                    "container": container_name,
                    "severity": "high" if health.get('cpu_percent') < 95 else "critical",
                    "description": f"Uso elevado de CPU: {health.get('cpu_percent')}%",
                    "metric_value": health.get('cpu_percent'),
                    "timestamp": datetime.now().isoformat()
                })
            
            # Detectar alto uso de memoria
            if health.get('memory_percent', 0) > 80:
                anomalies.append({
                    "type": "high_memory_usage",
                    "container": container_name,
                    "severity": "high" if health.get('memory_percent') < 95 else "critical",
                    "description": f"Uso elevado de memoria: {health.get('memory_percent')}%",
                    "metric_value": health.get('memory_percent'),
                    "timestamp": datetime.now().isoformat()
                })
            
            # Detectar múltiples reinicios
            if health.get('restart_count', 0) > 5:
                anomalies.append({
                    "type": "frequent_restarts",
                    "container": container_name,
                    "severity": "medium",
                    "description": f"Contenedor reiniciado {health.get('restart_count')} veces",
                    "metric_value": health.get('restart_count'),
                    "timestamp": datetime.now().isoformat()
                })
        
        return anomalies
    
    def get_system_stats(self) -> Dict:
        """Obtiene estadísticas generales del sistema"""
        try:
            # Estadísticas del host
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            # Estadísticas de Docker
            containers = self.docker_client.containers.list()
            total_containers = len(containers)
            running = len([c for c in containers if c.status == 'running'])
            
            return {
                "host": {
                    "cpu_percent": cpu_percent,
                    "memory_percent": memory.percent,
                    "memory_available_gb": round(memory.available / (1024**3), 2),
                    "disk_percent": disk.percent,
                    "disk_free_gb": round(disk.free / (1024**3), 2)
                },
                "docker": {
                    "total_containers": total_containers,
                    "running": running,
                    "stopped": total_containers - running
                },
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Error obteniendo estadísticas del sistema: {str(e)}")
            return {"error": str(e)}
    
    def store_baseline_metrics(self, container_name: str):
        """Almacena métricas base para detección de anomalías"""
        health = self.check_container_health(container_name)
        
        self.baseline_metrics[container_name] = {
            "cpu_percent": health.get('cpu_percent', 0),
            "memory_percent": health.get('memory_percent', 0),
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(f"Métricas base almacenadas para {container_name}")
    
    def compare_with_baseline(self, container_name: str) -> Dict:
        """Compara métricas actuales con la línea base"""
        if container_name not in self.baseline_metrics:
            return {"error": "No hay métricas base para este contenedor"}
        
        baseline = self.baseline_metrics[container_name]
        current = self.check_container_health(container_name)
        
        cpu_diff = current.get('cpu_percent', 0) - baseline['cpu_percent']
        memory_diff = current.get('memory_percent', 0) - baseline['memory_percent']
        
        return {
            "container": container_name,
            "cpu_diff_percent": round(cpu_diff, 2),
            "memory_diff_percent": round(memory_diff, 2),
            "significant_change": abs(cpu_diff) > 30 or abs(memory_diff) > 30,
            "current": current,
            "baseline": baseline
        }
