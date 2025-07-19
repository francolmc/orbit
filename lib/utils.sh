#!/bin/bash

# ==========================================
# 🪐 ORBIT - Utilidades Base
# ==========================================
# Funciones comunes y utilidades para todos los módulos
# Versión: 2.0.0
# ==========================================

# Prevenir carga múltiple
if [[ "${ORBIT_UTILS_LOADED:-}" == "true" ]]; then
    return 0
fi
readonly ORBIT_UTILS_LOADED=true

# ==========================================
# VALIDACIONES DEL SISTEMA
# ==========================================

# Verificar si el sistema es compatible
check_system_compatibility() {
    # Verificar distribución
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi

    # Leer información del sistema
    local distro
    distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

    case "$distro" in
        ubuntu|debian|linuxmint|pop|elementary)
            return 0
            ;;
        *)
            log_warn "SYSTEM" "Sistema no completamente soportado: $distro"
            return 1
            ;;
    esac
}

# Verificar dependencias del sistema
check_dependencies() {
    local missing_deps=()
    local required_tools=("apt" "wget" "curl" "gpg")
    local optional_tools=("flatpak" "snap")

    # Verificar herramientas requeridas
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_deps+=("$tool")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "SYSTEM" "Dependencias críticas faltantes: ${missing_deps[*]}"
        return 1
    fi

    # Verificar herramientas opcionales
    local missing_optional=()
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_optional+=("$tool")
        fi
    done

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_warn "SYSTEM" "Herramientas opcionales no disponibles: ${missing_optional[*]}"
    fi

    return 0
}

# Verificar permisos necesarios
check_permissions() {
    local operation="$1"

    case "$operation" in
        "install"|"remove"|"repo")
            # Estas operaciones pueden necesitar sudo
            return 0
            ;;
        "search"|"list"|"status")
            # Estas operaciones no necesitan permisos especiales
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# ==========================================
# UTILIDADES DE RED
# ==========================================

# Verificar conectividad a internet
check_internet_connection() {
    local test_urls=("http://www.google.com" "http://www.github.com" "http://archive.ubuntu.com")

    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 --head "$url" &>/dev/null; then
            return 0
        fi
    done

    log_error "NETWORK" "No se puede conectar a internet"
    return 1
}

# Descargar archivo con reintentos
download_file() {
    local url="$1"
    local output_file="$2"
    local max_attempts="${3:-3}"
    local timeout="${4:-30}"

    for ((i=1; i<=max_attempts; i++)); do
        log_debug "DOWNLOAD" "Attempt $i/$max_attempts: downloading $url"

        if wget -q --timeout="$timeout" -O "$output_file" "$url"; then
            log_info "DOWNLOAD" "Successfully downloaded: $url"
            return 0
        fi

        if [[ $i -lt $max_attempts ]]; then
            log_warn "DOWNLOAD" "Download failed, retrying in 2 seconds..."
            sleep 2
        fi
    done

    log_error "DOWNLOAD" "Failed to download after $max_attempts attempts: $url"
    return 1
}

# ==========================================
# UTILIDADES DE ARCHIVOS
# ==========================================

# Crear backup de un archivo
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.bak}"

    if [[ -f "$file" ]]; then
        local backup_file="${file}${backup_suffix}"
        if cp "$file" "$backup_file"; then
            log_info "BACKUP" "Created backup: $backup_file"
            echo "$backup_file"
            return 0
        else
            log_error "BACKUP" "Failed to create backup of: $file"
            return 1
        fi
    else
        log_warn "BACKUP" "File not found for backup: $file"
        return 1
    fi
}

# Restaurar archivo desde backup
restore_file() {
    local original_file="$1"
    local backup_file="${2:-${original_file}.bak}"

    if [[ -f "$backup_file" ]]; then
        if cp "$backup_file" "$original_file"; then
            log_info "RESTORE" "Restored file: $original_file"
            return 0
        else
            log_error "RESTORE" "Failed to restore: $original_file"
            return 1
        fi
    else
        log_error "RESTORE" "Backup file not found: $backup_file"
        return 1
    fi
}

# Verificar suma de verificación de archivo
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    local algorithm="${3:-sha256}"

    if [[ ! -f "$file" ]]; then
        log_error "CHECKSUM" "File not found: $file"
        return 1
    fi

    local actual_checksum
    case "$algorithm" in
        "md5")
            actual_checksum=$(md5sum "$file" | cut -d' ' -f1)
            ;;
        "sha256")
            actual_checksum=$(sha256sum "$file" | cut -d' ' -f1)
            ;;
        *)
            log_error "CHECKSUM" "Unsupported algorithm: $algorithm"
            return 1
            ;;
    esac

    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        log_info "CHECKSUM" "Checksum verified: $file"
        return 0
    else
        log_error "CHECKSUM" "Checksum mismatch for $file. Expected: $expected_checksum, Got: $actual_checksum"
        return 1
    fi
}

# ==========================================
# UTILIDADES DE CADENAS
# ==========================================

# Limpiar espacios en blanco
trim_whitespace() {
    local string="$1"
    # Remover espacios al principio y al final
    string="${string#"${string%%[![:space:]]*}"}"
    string="${string%"${string##*[![:space:]]}"}"
    echo "$string"
}

# Convertir a minúsculas
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Verificar si una cadena está vacía
is_empty() {
    local string="$1"
    [[ -z "$(trim_whitespace "$string")" ]]
}

# Verificar si una cadena contiene otra
contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]]
}

# Generar string aleatorio
generate_random_string() {
    local length="${1:-8}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# ==========================================
# UTILIDADES DE ARRAYS
# ==========================================

# Verificar si un elemento está en un array
array_contains() {
    local element="$1"
    shift
    local array=("$@")

    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

# Remover duplicados de un array
array_unique() {
    local -A seen
    local result=()

    for item in "$@"; do
        if [[ -z "${seen[$item]:-}" ]]; then
            seen["$item"]=1
            result+=("$item")
        fi
    done

    printf '%s\n' "${result[@]}"
}

# Unir array con delimitador
array_join() {
    local delimiter="$1"
    shift
    local array=("$@")

    local result=""
    for ((i=0; i<${#array[@]}; i++)); do
        if [[ $i -gt 0 ]]; then
            result+="$delimiter"
        fi
        result+="${array[$i]}"
    done

    echo "$result"
}

# ==========================================
# UTILIDADES DE TIEMPO
# ==========================================

# Medir tiempo de ejecución
measure_time() {
    local start_time
    start_time=$(date +%s.%N)

    # Ejecutar comando
    "$@"
    local exit_code=$?

    local end_time
    end_time=$(date +%s.%N)

    local duration
    duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")

    log_debug "TIMING" "Command '$*' took ${duration}s (exit code: $exit_code)"
    return $exit_code
}

# Formatear duración en segundos a formato legible
format_duration() {
    local seconds="$1"

    if [[ -z "$seconds" || "$seconds" == "unknown" ]]; then
        echo "unknown"
        return
    fi

    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    local result=""
    [[ $days -gt 0 ]] && result+="${days}d "
    [[ $hours -gt 0 ]] && result+="${hours}h "
    [[ $minutes -gt 0 ]] && result+="${minutes}m "
    result+="${secs}s"

    echo "$result"
}

# ==========================================
# UTILIDADES DE PROCESO
# ==========================================

# Verificar si un proceso está ejecutándose
is_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" &>/dev/null
}

# Esperar a que termine un proceso
wait_for_process() {
    local process_name="$1"
    local timeout="${2:-60}"
    local interval="${3:-1}"

    local elapsed=0
    while is_process_running "$process_name"; do
        if [[ $elapsed -ge $timeout ]]; then
            log_error "PROCESS" "Timeout waiting for process: $process_name"
            return 1
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    log_info "PROCESS" "Process finished: $process_name"
    return 0
}

# Ejecutar comando con timeout
run_with_timeout() {
    local timeout="$1"
    shift

    timeout "$timeout" "$@"
    local exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        log_error "TIMEOUT" "Command timed out after ${timeout}s: $*"
    fi

    return $exit_code
}

# ==========================================
# UTILIDADES DE CONFIRMACIÓN
# ==========================================

# Pedir confirmación al usuario
confirm() {
    local message="$1"
    local default="${2:-n}"

    # Si está en modo forzado, no pedir confirmación
    if [[ "${ORBIT_FORCE:-false}" == "true" ]]; then
        log_debug "CONFIRM" "Force mode: auto-confirming '$message'"
        return 0
    fi

    # Si está en modo silencioso, usar default
    if [[ "${ORBIT_QUIET:-false}" == "true" ]]; then
        log_debug "CONFIRM" "Quiet mode: using default '$default' for '$message'"
        [[ "$default" == "y" ]]
        return $?
    fi

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    echo -ne "${CYAN}❔ $message $prompt: ${RESET}"
    read -r response

    response=$(to_lowercase "$(trim_whitespace "$response")")

    if [[ -z "$response" ]]; then
        response="$default"
    fi

    [[ "$response" == "y" || "$response" == "yes" ]]
}

# Pedir entrada del usuario con validación
prompt_input() {
    local message="$1"
    local default="${2:-}"
    local validator="${3:-}"

    while true; do
        echo -ne "${CYAN}📝 $message"
        if [[ -n "$default" ]]; then
            echo -ne " [$default]"
        fi
        echo -ne ": ${RESET}"

        read -r input
        input=$(trim_whitespace "$input")

        if [[ -z "$input" && -n "$default" ]]; then
            input="$default"
        fi

        if [[ -z "$validator" ]]; then
            echo "$input"
            return 0
        fi

        # Ejecutar validador
        if eval "$validator" <<< "$input"; then
            echo "$input"
            return 0
        else
            print_message "error" "Entrada inválida. Intenta de nuevo."
        fi
    done
}

# ==========================================
# UTILIDADES DE FORMATO
# ==========================================

# Formatear tamaño de archivo
format_file_size() {
    local bytes="$1"

    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Centrar texto en una línea
center_text() {
    local text="$1"
    local width="${2:-80}"

    local text_length=${#text}
    local padding=$(((width - text_length) / 2))

    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# Crear barra de progreso simple
progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"

    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%" $percentage
}

# ==========================================
# UTILIDADES DE ERROR HANDLING
# ==========================================

# Manejo de errores con cleanup
cleanup_on_exit() {
    local exit_code=$?

    # Ejecutar funciones de cleanup si están definidas
    if declare -f cleanup_function &>/dev/null; then
        cleanup_function
    fi

    if [[ $exit_code -ne 0 ]]; then
        log_error "EXIT" "Script exited with error code: $exit_code"
    fi

    exit $exit_code
}

# Configurar trap para cleanup
setup_error_handling() {
    trap cleanup_on_exit EXIT INT TERM
}

# ==========================================
# FUNCIONES DE INICIALIZACIÓN
# ==========================================

# Inicializar utilidades
init_utils() {
    # Verificar compatibilidad del sistema
    if ! check_system_compatibility; then
        log_warn "INIT" "Sistema no completamente compatible, algunas funciones pueden no funcionar"
    fi

    # Verificar dependencias
    check_dependencies

    # Configurar manejo de errores
    setup_error_handling

    log_debug "INIT" "Utils initialized successfully"
}

# ==========================================
# EXPORTAR FUNCIONES
# ==========================================

# Todas las funciones ya están disponibles globalmente
# Auto-inicializar si no estamos siendo sourced para testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_utils
fi
