#!/usr/bin/env bash
set -euo pipefail

# backup-sqlite.sh — crea un backup con timestamp de la base de datos SQLite
# Uso: ./scripts/backup-sqlite.sh [directorio-destino]
# Ejemplo: ./scripts/backup-sqlite.sh /var/backups/ossflow

BACKUP_DIR="${1:-./backups}"
SQLITE_FILE="${SQLITE_DATA_DIR:-/var/lib/ossflow/data}/ossflow.db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/ossflow_${TIMESTAMP}.db"

mkdir -p "${BACKUP_DIR}"

if [ ! -f "${SQLITE_FILE}" ]; then
  echo "ERROR: No se encuentra la base de datos en ${SQLITE_FILE}" >&2
  exit 1
fi

# SQLite permite copiar el archivo si no hay escrituras concurrentes.
# Para mayor seguridad usa sqlite3 .backup si está disponible.
if command -v sqlite3 &>/dev/null; then
  sqlite3 "${SQLITE_FILE}" ".backup '${BACKUP_FILE}'"
else
  cp "${SQLITE_FILE}" "${BACKUP_FILE}"
fi

echo "Backup creado: ${BACKUP_FILE} ($(du -h "${BACKUP_FILE}" | cut -f1))"

# Limpiar backups con más de 30 días
find "${BACKUP_DIR}" -name "ossflow_*.db" -mtime +30 -delete
echo "Backups antiguos (>30 días) eliminados."
