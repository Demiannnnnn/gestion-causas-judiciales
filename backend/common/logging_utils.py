import logging
import json
import sys
import datetime

class JsonFormatter(logging.Formatter):
    """
    Formatter that outputs JSON strings after parsing the LogRecord.
    """
    def format(self, record):
        log_record = {
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "logger_name": record.name
        }

        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_record)

def get_logger(name, level=logging.INFO):
    """
    Returns a logger configured to output JSON to stdout.
    """
    logger = logging.getLogger(name)
    
    # If logger is already configured, don't add handlers again
    if logger.hasHandlers():
        return logger
        
    logger.setLevel(level)

    handler = logging.StreamHandler(sys.stdout)
    formatter = JsonFormatter()
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    
    return logger
