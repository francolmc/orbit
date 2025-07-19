#!/bin/bash

# ==========================================
# 🪐 ORBIT - Sistema de Logging
# ==========================================
# Librería para manejo de logs y trazabilidad
# Versión: 2.0.0
# ==========================================

# Prevenir carga múltiple
if [[ "${ORBIT_LOGGER_LOADED:-}" == "true" ]]; then
    return 0
fi
readonly ORBIT_LOGGER_LOADED=true

# ==========================================
# CONFIGURACIÓN DE LOGGING
# ==========================================

# Niveles de log
readonly LOG_LEVEL_ERROR=0
readonly LOG_LEVEL_WARN=1
readonly LOG_LEVEL_INFO=2
readonly LOG_LEVEL_DEBUG=3

# Nivel actual de logging (se puede cambiar desde configuración)
ORBIT_LOG_LEVEL=${ORBIT_LOG_LEVEL:-$LOG_LEVEL_INFO}

# Archivos de log
readonly LOG_MAIN="${LOGS_DIR}/orbit-installed.log"
readonly LOG_SYSTEM="${LOGS_DIR}/system-updates.log"
readonly LOG_REPOS="${LOGS_DIR}/repositories.log"
readonly LOG_DEBUG="${LOGS_DIR}/orbit-debug.log"
readonly LOG_ERROR="${LOGS_DIR}/orbit-error.log"

# Formato de timestamp
readonly LOG_TIMESTAMP_FORMAT="%Y-%m-%d %H:%M:%S"

# ==========================================
# FUNCIONES DE LOGGING BÁSICO
# ==========================================

# Función para obtener timestamp formateado
get_timestamp() {
    date +"$LOG_TIMESTAMP_FORMAT"
}

# Función para obtener timestamp ISO (para sorting)
get_iso_timestamp() {
    date -Iseconds
}

# Función para obtener información del contexto
get_log_context() {
    local caller_info
    caller_info=$(caller 2 2>/dev/null || echo "unknown unknown")
    local line_number=$(echo "$caller_info" | cut -d' ' -f1)
    local function_name=$(echo "$caller_info" | cut -d' ' -f2)
    local script_name=$(basename "$(echo "$caller_info" | cut -d' ' -f3)")

    echo "[$script_name:$function_name:$line_number]"
}

# Función de logging genérica
write_log() {
    local level="$1"
    local category="$2"
    local message="$3"
    local logfile="$4"
    local include_context="${5:-false}"

    # Verificar nivel de log
    case "$level" in
        "ERROR") local level_num=$LOG_LEVEL_ERROR ;;
        "WARN")  local level_num=$LOG_LEVEL_WARN ;;
        "INFO")  local level_num=$LOG_LEVEL_INFO ;;
        "DEBUG") local level_num=$LOG_LEVEL_DEBUG ;;
        *) local level_num=$LOG_LEVEL_INFO ;;
    esac

    # Solo escribir si el nivel es apropiado
    if [[ $level_num -le $ORBIT_LOG_LEVEL ]]; then
        local timestamp
        timestamp=$(get_timestamp)

        local context=""
        if [[ "$include_context" == "true" ]]; then
            context=" $(get_log_context)"
        fi

        local log_entry="[$timestamp] [$level] [$category]$context $message"

        # Crear directorio del log si no existe
        mkdir -p "$(dirname "$logfile")"

        # Escribir al archivo
        echo "$log_entry" >> "$logfile"

        # Si es error, también escribir a stderr si estamos en modo debug
        if [[ "$level" == "ERROR" && "${ORBIT_DEBUG:-false}" == "true" ]]; then
            echo "$log_entry" >&2
        fi
    fi
}

# ==========================================
# FUNCIONES DE LOGGING POR NIVEL
# ==========================================

# Log de error
log_error() {
    local category="$1"
    local message="$2"
    local logfile="${3:-$LOG_ERROR}"

    write_log "ERROR" "$category" "$message" "$logfile" true

    # También escribir al log principal si no es el mismo archivo
    if [[ "$logfile" != "$LOG_MAIN" ]]; then
        write_log "ERROR" "$category" "$message" "$LOG_MAIN" false
    fi
}

# Log de warning
log_warn() {
    local category="$1"
    local message="$2"
    local logfile="${3:-$LOG_MAIN}"

    write_log "WARN" "$category" "$message" "$logfile" false
}

# Log de información
log_info() {
    local category="$1"
    local message="$2"
    local logfile="${3:-$LOG_MAIN}"

    write_log "INFO" "$category" "$message" "$logfile" false
}

# Log de debug
log_debug() {
    local category="$1"
    local message="$2"
    local logfile="${3:-$LOG_DEBUG}"

    write_log "DEBUG" "$category" "$message" "$logfile" true
}

# ==========================================
# FUNCIONES ESPECIALIZADAS
# ==========================================

# Log para instalaciones de aplicaciones
log_app_install() {
    local app_name="$1"
    local source_type="$2"    # apt, snap, flatpak, etc.
    local install_method="$3" # install, detected, repo-added, etc.
    local extra_info="${4:-}"

    local timestamp
    timestamp=$(get_iso_timestamp)

    local log_entry="$app_name | $source_type | $install_method | $timestamp"
    if [[ -n "$extra_info" ]]; then
        log_entry="$log_entry | $extra_info"
    fi

    echo "$log_entry" >> "$LOG_MAIN"
    log_info "INSTALL" "Installed $app_name via $source_type ($install_method)"
}

# Log para desinstalaciones
log_app_remove() {
    local app_name="$1"
    local source_type="$2"
    local remove_method="${3:-remove}"
    local extra_info="${4:-}"

    local timestamp
    timestamp=$(get_iso_timestamp)

    # Remover del log principal (todas las entradas de esta app)
    if [[ -f "$LOG_MAIN" ]]; then
        sed -i "/^${app_name} |/d" "$LOG_MAIN"
    fi

    # Log de la remoción
    log_info "REMOVE" "Removed $app_name from $source_type ($remove_method)"
}

# Log para actualizaciones de sistema
log_system_update() {
    local update_type="$1"    # repos, apt, snap, flatpak, full
    local status="$2"         # started, completed, failed
    local details="${3:-}"

    local timestamp
    timestamp=$(get_iso_timestamp)

    local log_entry="[$timestamp] [$update_type] [$status] $details"
    echo "$log_entry" >> "$LOG_SYSTEM"

    log_info "SYSTEM" "System update: $update_type - $status"
}

# Log para gestión de repositorios
log_repo_action() {
    local action="$1"         # add, remove, update
    local repo_name="$2"
    local status="$3"         # success, failed
    local details="${4:-}"

    local timestamp
    timestamp=$(get_iso_timestamp)

    local log_entry="[$timestamp] [$action] [$repo_name] [$status] $details"
    echo "$log_entry" >> "$LOG_REPOS"

    log_info "REPO" "Repository $action: $repo_name - $status"
}

# ==========================================
# FUNCIONES DE CONSULTA DE LOGS
# ==========================================

# Verificar si una app está registrada
is_app_registered() {
    local app_name="$1"

    if [[ -f "$LOG_MAIN" ]]; then
        grep -q "^${app_name} |" "$LOG_MAIN"
    else
        return 1
    fi
}

# Obtener información de una app registrada
get_app_info() {
    local app_name="$1"

    if [[ -f "$LOG_MAIN" ]]; then
        grep "^${app_name} |" "$LOG_MAIN" | tail -n 1
    fi
}

# Obtener tipo de instalación de una app
get_app_install_type() {
    local app_name="$1"
    local app_info

    app_info=$(get_app_info "$app_name")
    if [[ -n "$app_info" ]]; then
        echo "$app_info" | cut -d '|' -f 2 | xargs
    fi
}

# Listar todas las apps registradas
list_registered_apps() {
    if [[ -f "$LOG_MAIN" ]]; then
        cut -d '|' -f 1 "$LOG_MAIN" | xargs -I {} echo {} | sort -u
    fi
}

# Obtener estadísticas de instalación
get_install_stats() {
    if [[ ! -f "$LOG_MAIN" ]]; then
        echo "0 0 0 0"
        return
    fi

    local total
    local apt_count
    local snap_count
    local flatpak_count

    total=$(wc -l < "$LOG_MAIN")
    apt_count=$(grep -c "| apt |" "$LOG_MAIN" || echo "0")
    snap_count=$(grep -c "| snap |" "$LOG_MAIN" || echo "0")
    flatpak_count=$(grep -c "| flatpak |" "$LOG_MAIN" || echo "0")

    echo "$total $apt_count $snap_count $flatpak_count"
}

# ==========================================
# FUNCIONES DE MANTENIMIENTO DE LOGS
# ==========================================

# Rotar logs si son muy grandes
rotate_logs() {
    local max_size_kb="${1:-1024}"  # 1MB por defecto

    for logfile in "$LOG_MAIN" "$LOG_SYSTEM" "$LOG_REPOS" "$LOG_DEBUG" "$LOG_ERROR"; do
        if [[ -f "$logfile" ]]; then
            local size_kb
            size_kb=$(du -k "$logfile" | cut -f1)

            if [[ $size_kb -gt $max_size_kb ]]; then
                local backup_file="${logfile}.old"

                # Mantener solo el último backup
                [[ -f "$backup_file" ]] && rm "$backup_file"

                # Rotar
                mv "$logfile" "$backup_file"
                touch "$logfile"

                log_info "MAINTENANCE" "Rotated log file: $(basename "$logfile") (${size_kb}KB)"
            fi
        fi
    done
}

# Limpiar logs antiguos
cleanup_old_logs() {
    local days="${1:-30}"  # 30 días por defecto

    find "$LOGS_DIR" -name "*.log.old" -type f -mtime +$days -delete 2>/dev/null || true
    log_info "MAINTENANCE" "Cleaned logs older than $days days"
}

# Crear backup de logs
backup_logs() {
    local backup_dir="${1:-$LOGS_DIR/backups}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$backup_dir"

    local backup_file="$backup_dir/orbit_logs_$timestamp.tar.gz"

    if tar -czf "$backup_file" -C "$LOGS_DIR" --exclude="backups" . 2>/dev/null; then
        log_info "MAINTENANCE" "Created log backup: $backup_file"
        echo "$backup_file"
    else
        log_error "MAINTENANCE" "Failed to create log backup"
        return 1
    fi
}

# ==========================================
# FUNCIONES DE INICIALIZACIÓN
# ==========================================

# Inicializar sistema de logging
init_logging() {
    # Crear directorios necesarios
    mkdir -p "$LOGS_DIR"
    mkdir -p "$LOGS_DIR/backups"

    # Ajustar nivel de log según configuración
    if [[ "${ORBIT_DEBUG:-false}" == "true" ]]; then
        ORBIT_LOG_LEVEL=$LOG_LEVEL_DEBUG
    elif [[ "${ORBIT_QUIET:-false}" == "true" ]]; then
        ORBIT_LOG_LEVEL=$LOG_LEVEL_ERROR
    fi

    # Log de inicialización
    log_info "SYSTEM" "Orbit logging system initialized"

    # Rotar logs si es necesario
    rotate_logs
}

# ==========================================
# FUNCIONES DE UTILIDAD PARA DEBUGGING
# ==========================================

# Mostrar últimas entradas de log
show_recent_logs() {
    local count="${1:-10}"
    local logfile="${2:-$LOG_MAIN}"

    if [[ -f "$logfile" ]]; then
        echo "📋 Últimas $count entradas de $(basename "$logfile"):"
        tail -n "$count" "$logfile"
    else
        echo "📭 No se encontró el archivo de log: $logfile"
    fi
}

# Buscar en logs
search_logs() {
    local pattern="$1"
    local logfile="${2:-$LOG_MAIN}"

    if [[ -f "$logfile" ]]; then
        echo "🔍 Buscando '$pattern' en $(basename "$logfile"):"
        grep -i "$pattern" "$logfile" || echo "No se encontraron coincidencias"
    else
        echo "📭 No se encontró el archivo de log: $logfile"
    fi
}

# ==========================================
# EXPORTAR FUNCIONES PRINCIPALES
# ==========================================

# Las funciones principales ya están disponibles globalmente
# Inicializar automáticamente si no estamos siendo sourced para testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_logging
fi
