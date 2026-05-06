# OssFlow — Guía de despliegue

## Arquitectura

```
Internet → Cloudflare Tunnel → frontend (nginx:80) → /api/* → backend (Spring Boot:8080)
                                                               ↓
                                                         SQLite en volumen Docker
```

Sin puertos expuestos al exterior. TLS gestionado por Cloudflare. IP de origen oculta.

---

## Requisitos del host

- Docker Engine ≥ 24 + Docker Compose v2
- Linux x86_64 (probado en Debian/Ubuntu en Proxmox)
- 1 GB RAM mínimo, 2 GB recomendado
- Dominio gestionado en Cloudflare

---

## Despliegue inicial (prod)

### 1. Clonar el repositorio

```bash
git clone https://github.com/yraedry/ossflow-deploy.git
cd ossflow-deploy
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
nano .env
```

Rellenar obligatoriamente:
- `GITHUB_OWNER` — tu usuario de GitHub
- `CLOUDFLARE_TUNNEL_TOKEN` — token del tunnel (ver sección Cloudflare)

### 3. Crear directorio de datos

```bash
sudo mkdir -p /var/lib/ossflow/data
sudo chown 1000:1000 /var/lib/ossflow/data
```

### 4. Configurar Cloudflare Tunnel

1. Ir a [Cloudflare Zero Trust](https://one.dash.cloudflare.com) → Networks → Tunnels
2. Crear tunnel → copiar el token
3. En "Public Hostnames": `ossflow.tudominio.com → http://frontend:80`
4. Pegar el token en `.env` como `CLOUDFLARE_TUNNEL_TOKEN`

### 5. Arrancar los servicios

```bash
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

### 6. Verificar

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs backend --tail=50
```

La aplicación estará disponible en `https://ossflow.tudominio.com` en unos segundos.

---

## Desarrollo local

Requiere tener los repos `OssFlow` y `OssFlow-frontend` en la misma carpeta padre:

```
repositorio/
├── OssFlow/
├── OssFlow-frontend/
└── ossflow-deploy/   ← aquí
```

```bash
docker compose up --build
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:8080/api/v1
- Swagger UI: http://localhost:8080/swagger-ui.html

---

## Actualizar a una nueva versión

```bash
# Actualizar las versiones en .env
BACKEND_VERSION=v1.2.0
FRONTEND_VERSION=v1.2.0

# Pull de las nuevas imágenes y reinicio
docker compose -f docker-compose.prod.yml --env-file .env pull
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

---

## Backups

### Backup manual

```bash
./scripts/backup-sqlite.sh /var/backups/ossflow
```

### Backup automático con cron (recomendado)

```bash
# Añadir al crontab del sistema (crontab -e)
0 2 * * * /path/to/ossflow-deploy/scripts/backup-sqlite.sh /var/backups/ossflow >> /var/log/ossflow-backup.log 2>&1
```

Los backups se guardan con timestamp y se eliminan automáticamente tras 30 días.

### Restaurar un backup

```bash
./scripts/restore-sqlite.sh /var/backups/ossflow/ossflow_20260506_020000.db
```

---

## Logs

```bash
# Todos los servicios
docker compose -f docker-compose.prod.yml logs -f

# Solo backend
docker compose -f docker-compose.prod.yml logs -f backend

# Solo frontend/nginx
docker compose -f docker-compose.prod.yml logs -f frontend
```

---

## Parar y limpiar

```bash
# Parar (mantiene volúmenes y datos)
docker compose -f docker-compose.prod.yml down

# Parar y eliminar volúmenes (DESTRUYE LOS DATOS)
docker compose -f docker-compose.prod.yml down -v
```

---

## Estructura del repositorio

```
ossflow-deploy/
├── docker-compose.yml          desarrollo local (build desde fuente)
├── docker-compose.prod.yml     producción (imágenes ghcr.io)
├── .env.example                plantilla de variables
├── DEPLOY.md                   esta guía
├── cloudflared/
│   └── config.example.yml      ejemplo de configuración del tunnel
└── scripts/
    ├── backup-sqlite.sh        backup con timestamp + limpieza automática
    └── restore-sqlite.sh       restauración interactiva con backup previo
```
