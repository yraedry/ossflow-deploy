#!/usr/bin/env bash
set -euo pipefail

# restore-sqlite.sh — restaura un backup de SQLite
# Uso: ./scripts/restore-sqlite.sh <archivo-backup>
# Ejemplo: ./scripts/restore-sqlite.sh /var/backups/ossflow/ossflow_20260506_120000.db

BACKUP_FILE="${1:-}"
SQLITE_DIR="${SQLITE_DATA_DIR:-/var/lib/ossflow/data}"
SQLITE_FILE="${SQLITE_DIR}/ossflow.db"

if [ -z "${BACKUP_FILE}" ]; then
  echo "Uso: $0 <archivo-backup.db>" >&2
  exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "ERROR: Archivo de backup no encontrado: ${BACKUP_FILE}" >&2
  exit 1
fi

echo "AVISO: Esto reemplazará la base de datos actual."
read -r -p "¿Continuar? [s/N] " confirm
if [[ "${confirm}" != "s" && "${confirm}" != "S" ]]; then
  echo "Operación cancelada."
  exit 0
fi

# Parar el backend antes de restaurar
echo "Parando el backend..."
docker compose -f "$(dirname "$0")/../docker-compose.prod.yml" stop backend 2>/dev/null || true

# Backup del estado actual antes de restaurar
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
if [ -f "${SQLITE_FILE}" ]; then
  cp "${SQLITE_FILE}" "${SQLITE_FILE}.pre-restore-${TIMESTAMP}"
  echo "Backup previo guardado en: ${SQLITE_FILE}.pre-restore-${TIMESTAMP}"
fi

mkdir -p "${SQLITE_DIR}"
cp "${BACKUP_FILE}" "${SQLITE_FILE}"
echo "Base de datos restaurada desde: ${BACKUP_FILE}"

echo "Reiniciando el backend..."
docker compose -f "$(dirname "$0")/../docker-compose.prod.yml" start backend
echo "Restauración completada."
