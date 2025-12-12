#!/bin/sh
echo "Script started"

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
PROJECT_NAME="licitacion_sistemacausasjudiciales"
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
redis
gateway
"
REPORTS_DIR="docs/reportes/vulnerabilidades"
DATE_STAMP=$(date +%Y-%m-%d)
BASE_FILENAME="${REPORTS_DIR}/consolidated-scan-report-${DATE_STAMP}"
REPORT_FILE=""

# --- Versioning Logic ---
VERSION=1
while true; do
  TENTATIVE_FILENAME="${BASE_FILENAME}-v${VERSION}.txt"
  if [ ! -f "$TENTATIVE_FILENAME" ]; then
    REPORT_FILE="$TENTATIVE_FILENAME"
    break
  fi
  VERSION=$((VERSION + 1))
done

# --- Main Script ---
echo "==========================================="
echo "Starting Consolidated Vulnerability Scan"
echo "Report will be saved to: ${REPORT_FILE}"
echo "==========================================="

# Ensure the reports directory exists
mkdir -p "$REPORTS_DIR"

# Create the new versioned report file with a header
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
  docker run --rm -v ///var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table --no-progress --severity HIGH,CRITICAL "$IMAGE_NAME" >> "$REPORT_FILE" || true
done

#docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table --no-progress proyectolicitacion_admin2025_2-frontend:latest

# --- Dependency Scan (Trivy) ---
echo "\n--- Scanning Python Dependencies (Trivy) ---\n" >> "$REPORT_FILE"
for req_file in backend/**/requirements.txt; do
  SERVICE_DIR=$(dirname "$req_file")
  echo "--- Scanning dependencies for: ${SERVICE_DIR} ---"
  printf "\n\n--- Dependencies for: ${SERVICE_DIR} ---\n" >> "$REPORT_FILE"
  docker run --rm -v "$(pwd):/scan" aquasec/trivy fs --format table --no-progress --severity HIGH,CRITICAL "/scan/${req_file}" >> "$REPORT_FILE" || true
done

# --- Port Scan (nmap) ---
echo "\n--- Scanning Open Ports (nmap) ---\n" >> "$REPORT_FILE"
echo "--- Running nmap on localhost ---"
docker run --rm --net=host instrumentisto/nmap -sT -p- --open localhost >> "$REPORT_FILE" || true

# --- Web Analysis (nikto) ---
echo "\n--- Basic Web Analysis (nikto) ---\n" >> "$REPORT_FILE"
echo "--- Running nikto on http://localhost:80 ---"
docker run --rm --net=host sudis/nikto -h http://localhost:80 >> "$REPORT_FILE" || true

echo "\n==========================================="
echo "All scans completed."
echo "Consolidated report is available at: ${REPORT_FILE}"
echo "==========================================="