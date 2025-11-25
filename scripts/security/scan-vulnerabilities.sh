#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
PROJECT_NAME="proyectolicitacion_admin2025_2"
SERVICES="
db-master
db-proxy
db-slave
autenticacion
casos
documentos
notificaciones
ia-seguridad
cron
reportes
frontend
backup-service
failover-daemon
ia_service
notificaciones-deadline-worker
notificaciones-summary-worker
notificaciones-worker
mysql
"
REPORTS_DIR="docs/reportes/vulnerabilidades"
DATE_STAMP=$(date +%Y-%m-%d)
REPORT_FILE="${REPORTS_DIR}/consolidated-scan-report-${DATE_STAMP}.txt"

# --- Main Script ---
echo "==========================================="
echo "Starting Consolidated Vulnerability Scan"
echo "==========================================="

# Ensure the reports directory exists
mkdir -p "$REPORTS_DIR"

# Create/overwrite the report file and add a header
echo "Consolidated Vulnerability Report - $(date)" > "$REPORT_FILE"
echo "===========================================" >> "$REPORT_FILE"

# Loop through each service and scan its Docker image
for SERVICE in $SERVICES; do
  IMAGE_NAME="${PROJECT_NAME}-${SERVICE}:latest"
  SEPARATOR="\n\n--- Scanning: ${IMAGE_NAME} ---\n"

  echo "--- Scanning: ${IMAGE_NAME} ---"

  # Append separator to the report file
  printf "$SEPARATOR" >> "$REPORT_FILE"

  # Run Trivy scan and append the output to the report file
  # Use "|| true" to continue even if vulnerabilities are found (which returns a non-zero exit code)
  docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table --no-progress --severity CRITICAL "$IMAGE_NAME" >> "$REPORT_FILE" || true
done

#docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table --no-progress proyectolicitacion_admin2025_2-frontend:latest

echo "\n==========================================="
echo "All scans completed."
echo "Consolidated report is available at: ${REPORT_FILE}"
echo "==========================================="