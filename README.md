# 🪐 Orbit - Gestor de aplicaciones y sistema

> **Orbit** es un gestor de paquetes unificado para Ubuntu que combina APT, Snap, Flatpak y repositorios externos en una experiencia simple y coherente.

## ✨ Características Principales

### 🎯 Gestión inteligente de paquetes
- **Instalación automática inteligente**: Orbit decide la mejor fuente (APT, Snap, Flatpak) según políticas configurables
- **Repositorios externos**: Agrega automáticamente repositorios conocidos (VS Code, Chrome, etc.)
- **Trazabilidad completa**: Registra todo lo instalado para fácil gestión y limpieza

### 🔄 Actualizaciones de sistema completo
- **Sistema completo**: Actualiza APT, Snap, Flatpak y aplicaciones registradas
- **Actualizaciones graduales**: Actualizacion de paquetes instalados hasta la actualización completa del sistema
- **Limpieza automática**: Remueve paquetes huérfanos y limpia cachés

### 🛡️ Gestión de repositorios
- **Base de datos de repositorios**: Conoce automáticamente cómo instalar software popular
- **Claves GPG automáticas**: Maneja la verificación de firmas transparentemente
- **Limpieza de repositorios**: Remueve repos cuando desinstala software

### 🧹 Limpieza y mantenimiento
- **Detox del sistema**: Limpieza profunda de paquetes no registrados
- **Diagnóstico de salud**: Verifica el estado del sistema
- **Backup/Restore**: Guarda y restaura configuraciones de Orbit

## 🚀 Instalación Rápida

```bash
# Clonar Orbit
git clone https://github.com/tuusuario/orbit.git
cd orbit

# Hacer ejecutable
chmod +x bin/orbit

# Agregar al PATH (opcional)
echo 'export PATH="$HOME/orbit/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 📖 Uso básico

### Gestión de aplicaciones

```bash
# Instalar una aplicación (Orbit decide la mejor fuente)
orbit install code

# Buscar aplicaciones en todas las fuentes
orbit search browser

# Actualizar una aplicación específica
orbit update code

# Desinstalar completamente
orbit remove code

# Ver aplicaciones instaladas por Orbit
orbit list
```

### Gestión de sistema

```bash
# Actualizar todo el sistema
orbit system update

# Upgrade completo del sistema
orbit system upgrade

# Limpiar sistema (caché, paquetes huérfanos)
orbit system cleanup

# Verificar salud del sistema
orbit system health
```

### Gestión de repositorios

```bash
# Ver repositorios agregados por Orbit
orbit repo list

# Agregar repositorio manualmente
orbit repo add windsurf

# Actualizar índices de repositorios
orbit repo update

# Remover repositorio
orbit repo remove windsurf
```

### Herramientas avanzadas

```bash
# Detox completo (limpia todo lo no registrado)
orbit detox

# Ver historial de instalaciones
orbit history

# Backup de configuración Orbit
orbit backup

# Restaurar desde backup
orbit restore
```

## ⚙️ Configuración

### Políticas de instalación

Edita `config/policies.conf` para personalizar el comportamiento:

```ini
[install_priorities]
# Prioridad para herramientas de desarrollo
dev_tools=apt
# Prioridad para aplicaciones gráficas
gui_apps=flatpak
# Prioridad para software propietario
proprietary=snap

[auto_repo_add]
# Agregar repositorios automáticamente
enabled=true
# Confirmar antes de agregar
confirm_before_add=true

[system_updates]
# Actualizar repositorios automáticamente
auto_update_repos=true
# Instalar actualizaciones de seguridad automáticamente
auto_update_security=true
# Limpieza automática
auto_cleanup=weekly
```

### Base de datos de repositorios

Orbit incluye repositorios predefinidos para software popular:

- **Microsoft**: VS Code, Edge
- **Google**: Chrome
- **Desarrollo**: Windsurf, Warp Terminal, GitHub CLI
- **Media**: Spotify, Discord
- **Y muchos más...**

## 🏗️ Arquitectura del Proyecto

```
orbit/
├── bin/orbit                    # Script principal
├── lib/                         # Bibliotecas principales
│   ├── logger.sh               # Sistema de logging
│   ├── repositories.db         # Base de datos de repos
│   ├── policies.sh             # Políticas de instalación
│   ├── system.sh               # Funciones de sistema
│   └── utils.sh                # Utilidades comunes
├── modules/                     # Módulos de funcionalidad
│   ├── install.sh              # Instalación inteligente
│   ├── update.sh               # Actualización de apps
│   ├── system-update.sh        # Actualización de sistema
│   ├── repo.sh                 # Gestión de repositorios
│   ├── health.sh               # Diagnóstico del sistema
│   └── detox.sh                # Limpieza del sistema
├── config/                      # Configuración
│   ├── orbit.conf              # Configuración principal
│   └── policies.conf           # Políticas personalizables
└── logs/                        # Registros
    ├── orbit-installed.log     # Apps instaladas
    ├── system-updates.log      # Actualizaciones de sistema
    └── repositories.log        # Cambios en repos
```

## 🎯 Casos de uso

### Para desarrolladores
```bash
# Setup completo de desarrollo
orbit install code windsurf git nodejs python3-pip
orbit system update
```

### Para usuarios finales
```bash
# Aplicaciones esenciales
orbit install code chrome spotify discord
orbit install libreoffice gimp
```

### Mantenimiento del sistema
```bash
# Rutina de mantenimiento semanal
orbit system update
orbit system cleanup
orbit detox
```

## 🗺️ Roadmap de desarrollo

### 📋 Fase 1: Fundamentos (Core)
- [X] **Estructura del proyecto**: Crear carpetas y arquitectura básica
- [X] **Script principal**: `bin/orbit` con sistema de comandos
- [ ] **Sistema de logging**: `lib/logger.sh` para trazabilidad
- [ ] **Utilidades base**: `lib/utils.sh` con funciones comunes
- [ ] **Configuración básica**: `config/orbit.conf` y manejo de configuración

### 📦 Fase 2: Gestión básica de paquetes
- [ ] **Instalación simple**: `modules/install.sh` para APT/Snap/Flatpak básico
- [ ] **Búsqueda unificada**: `modules/search.sh` en todas las fuentes
- [ ] **Listado de instalados**: `modules/list.sh` mejorado
- [ ] **Desinstalación**: `modules/remove.sh` con limpieza completa
- [ ] **Registro de aplicaciones**: Sistema de logging mejorado

### 🔧 Fase 3: Repositorios externos
- [ ] **Base de datos de repos**: `lib/repositories.db` con formato definido
- [ ] **Gestión de claves GPG**: Manejo automático de firmas
- [ ] **Módulo de repositorios**: `modules/repo.sh` completo
- [ ] **Auto-detección**: Reconocer apps que necesitan repos externos
- [ ] **Limpieza de repos**: Remover repos al desinstalar apps

### 🧠 Fase 4: Políticas inteligentes
- [ ] **Sistema de políticas**: `lib/policies.sh` con lógica de decisión
- [ ] **Configuración de políticas**: `config/policies.conf` editable
- [ ] **Detección de tipo de app**: Dev tools vs GUI apps vs propietario
- [ ] **Instalación automática**: Decisión inteligente de fuente
- [ ] **Excepciones configurables**: Override de políticas por app

### 🔄 Fase 5: Actualizaciones de sistema
- [ ] **Actualización básica**: `modules/update.sh` mejorado
- [ ] **Actualización de sistema**: `modules/system-update.sh` completo
- [ ] **Actualización por capas**: Repos → Sistema → Apps → Flatpak → Snap
- [ ] **Actualizaciones automáticas**: Configurables por tipo
- [ ] **Logs de actualizaciones**: `logs/system-updates.log`

### 🛡️ Fase 6: Salud y diagnóstico
- [ ] **Diagnóstico del sistema**: `modules/health.sh`
- [ ] **Verificación de integridad**: Validar estado de paquetes
- [ ] **Detección de problemas**: Dependencias rotas, conflictos
- [ ] **Recomendaciones**: Sugerencias de optimización
- [ ] **Reportes de salud**: Informes detallados

### 🧹 Fase 7: Limpieza avanzada
- [ ] **Detox mejorado**: `modules/detox.sh` más inteligente
- [ ] **Limpieza por categorías**: Cache, logs, paquetes, configuraciones
- [ ] **Limpieza programada**: Tareas automáticas configurables
- [ ] **Backup antes de limpieza**: Protección ante errores
- [ ] **Métricas de limpieza**: Espacio liberado, tiempo ahorrado

### 💾 Fase 8: Backup y restauración
- [ ] **Sistema de backup**: `modules/backup.sh`
- [ ] **Backup de configuración**: Orbit settings y listas de apps
- [ ] **Backup selectivo**: Por categorías o apps específicas
- [ ] **Restauración inteligente**: `modules/restore.sh`
- [ ] **Migración entre sistemas**: Transferir setup completo

### 🚀 Fase 9: Funcionalidades avanzadas
- [ ] **Perfiles de instalación**: Sets predefinidos (Developer, Gaming, Office)
- [ ] **Scripts de automatización**: Tareas personalizadas del usuario
- [ ] **Integración con cron**: Mantenimiento automático
- [ ] **API simple**: Para integración con otros scripts
- [ ] **Métricas y estadísticas**: Uso del sistema y aplicaciones

### 🎨 Fase 10: Experiencia de usuario
- [ ] **Interfaz mejorada**: Colores, emojis, mejor UX
- [ ] **Mensajes informativos**: Explicaciones claras de acciones
- [ ] **Progreso visual**: Barras de progreso, indicadores de tiempo
- [ ] **Modo interactivo**: Prompts inteligentes y confirmaciones
- [ ] **Documentación integrada**: Help contextual y ejemplos

### 🔮 Fase 11: Futuro (ideas avanzadas)
- [ ] **Soporte para AppImages**: Gestión de aplicaciones portables
- [ ] **Compilación desde fuente**: Para software muy específico
- [ ] **Contenedores**: Integración con Docker/Podman
- [ ] **Sincronización remota**: Backup en la nube
- [ ] **Plugin system**: Extensibilidad para la comunidad

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

### Agregar Nuevos Repositorios

Para agregar soporte para nuevos repositorios, edita `lib/repositories.db`:

```
nombre_app|línea_repo|url_clave_gpg|descripción
```

## 📝 Licencia

MIT License - ve el archivo [LICENSE](LICENSE) para detalles.

- Inspirado en la necesidad de unificar la gestión de paquetes en Linux
- Construido para maximizar la productividad y minimizar la fricción
- Desarrollado con ❤️ para los usuarios que lo necesiten

---

**¿Listo para orbitar? 🚀**

```bash
orbit install --your-next-adventure
```
