import logging
from datetime import datetime
from typing import List, Dict, Optional
import json

logger = logging.getLogger(__name__)


class AlertManager:
    """Gestiona alertas de seguridad y problemas detectados"""
    
    def __init__(self):
        self.alerts = []
        self.alert_id_counter = 1
    
    def create_alert(self, severity: str, title: str, description: str, 
                    container: str, metadata: Optional[Dict] = None):
        """
        Crea una nueva alerta
        
        Args:
            severity: Nivel de severidad (low, medium, high, critical)
            title: Título de la alerta
            description: Descripción detallada
            container: Nombre del contenedor afectado
            metadata: Información adicional opcional
        """
        alert = {
            "id": self.alert_id_counter,
            "severity": severity,
            "title": title,
            "description": description,
            "container": container,
            "status": "open",
            "created_at": datetime.now().isoformat(),
            "resolved_at": None,
            "resolution_note": None,
            "metadata": metadata or {}
        }
        
        self.alerts.append(alert)
        self.alert_id_counter += 1
        
        logger.info(f"Alerta creada: [{severity}] {title} - {container}")
        
        # Si es crítica, loggear con warning
        if severity in ['high', 'critical']:
            logger.warning(f"ALERTA CRÍTICA: {title} en {container}")
        
        return alert
    
    def get_alerts(self, severity: Optional[str] = None, 
                   status: Optional[str] = None,
                   limit: int = 50) -> List[Dict]:
        """
        Obtiene alertas filtradas
        
        Args:
            severity: Filtrar por severidad
            status: Filtrar por estado (open, resolved)
            limit: Número máximo de alertas a retornar
        """
        filtered_alerts = self.alerts.copy()
        
        if severity:
            filtered_alerts = [a for a in filtered_alerts if a['severity'] == severity]
        
        if status:
            filtered_alerts = [a for a in filtered_alerts if a['status'] == status]
        
        # Ordenar por fecha de creación (más recientes primero)
        filtered_alerts.sort(key=lambda x: x['created_at'], reverse=True)
        
        return filtered_alerts[:limit]
    
    def resolve_alert(self, alert_id: int, resolution_note: str = ""):
        """Marca una alerta como resuelta"""
        for alert in self.alerts:
            if alert['id'] == alert_id:
                alert['status'] = 'resolved'
                alert['resolved_at'] = datetime.now().isoformat()
                alert['resolution_note'] = resolution_note
                
                logger.info(f"Alerta {alert_id} resuelta: {resolution_note}")
                return True
        
        logger.warning(f"Alerta {alert_id} no encontrada")
        return False
    
    def get_alert_by_id(self, alert_id: int) -> Optional[Dict]:
        """Obtiene una alerta específica por ID"""
        for alert in self.alerts:
            if alert['id'] == alert_id:
                return alert
        return None
    
    def get_stats(self) -> Dict:
        """Obtiene estadísticas de alertas"""
        total = len(self.alerts)
        open_alerts = len([a for a in self.alerts if a['status'] == 'open'])
        resolved = len([a for a in self.alerts if a['status'] == 'resolved'])
        
        by_severity = {
            'low': len([a for a in self.alerts if a['severity'] == 'low' and a['status'] == 'open']),
            'medium': len([a for a in self.alerts if a['severity'] == 'medium' and a['status'] == 'open']),
            'high': len([a for a in self.alerts if a['severity'] == 'high' and a['status'] == 'open']),
            'critical': len([a for a in self.alerts if a['severity'] == 'critical' and a['status'] == 'open'])
        }
        
        return {
            "total": total,
            "open": open_alerts,
            "resolved": resolved,
            "by_severity": by_severity
        }
    
    def cleanup_old_alerts(self, days: int = 30):
        """Elimina alertas resueltas antiguas"""
        from datetime import timedelta
        
        cutoff_date = datetime.now() - timedelta(days=days)
        initial_count = len(self.alerts)
        
        self.alerts = [
            a for a in self.alerts
            if a['status'] == 'open' or 
            (a['resolved_at'] and datetime.fromisoformat(a['resolved_at']) > cutoff_date)
        ]
        
        removed = initial_count - len(self.alerts)
        if removed > 0:
            logger.info(f"Limpiadas {removed} alertas antiguas")
        
        return removed
