# 🤖 Azure DevOps Coding Agent gracias a GitHub Copilot CLI

<div align="center">

[![YouTube Channel Subscribers](https://img.shields.io/youtube/channel/subscribers/UC140iBrEZbOtvxWsJ-Tb0lQ?style=for-the-badge&logo=youtube&logoColor=white&color=red)](https://www.youtube.com/c/GiselaTorres?sub_confirmation=1)
[![GitHub followers](https://img.shields.io/github/followers/0GiS0?style=for-the-badge&logo=github&logoColor=white)](https://github.com/0GiS0)
[![LinkedIn Follow](https://img.shields.io/badge/LinkedIn-Sígueme-blue?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/giselatorresbuitrago/)
[![X Follow](https://img.shields.io/badge/X-Sígueme-black?style=for-the-badge&logo=x&logoColor=white)](https://twitter.com/0GiS0)

**📖 Idiomas:** 🇪🇸 **Español** | [🇬🇧 English](README.en.md)

</div>

¡Hola developer 👋🏻! Este repositorio implementa un flujo en Azure Pipelines 🚀 que integra **GitHub Copilot CLI** 🤖 para generar código automáticamente a partir de Work Items 📋. El código del mismo fue utilizado para mi vídeo: 🚀 Lleva Azure DevOps al siguiente nivel con GitHub Copilot CLI 🤖


<a href="https://youtu.be/ZS0LQA2_zZQ">
 <img src="https://img.youtube.com/vi/ZS0LQA2_zZQ/maxresdefault.jpg" alt="🚀 Lleva Azure DevOps al siguiente nivel con GitHub Copilot CLI 🤖" width="100%" />
</a>

### 🎯 Objetivos

- ✅ Automatizar la creación de código mediante IA (GitHub Copilot)
- ✅ Integrar GitHub Copilot CLI con Azure DevOps
- ✅ Gestionar flujos de trabajo automáticos desde WebHooks
- ✅ Crear ramas de características, commits y Pull Requests de forma automática
- ✅ Vincular cambios con elementos de trabajo de Azure DevOps

## 🚀 ¿Qué hace?

El pipeline se activa mediante un **WebHook desde Azure DevOps** y realiza el siguiente flujo:

1. 📖 **Lee el elemento de trabajo** - Obtiene la descripción y requisitos
2. 🌿 **Crea una rama de características** - `copilot/<work-item-id>`
3. 🤖 **Ejecuta GitHub Copilot CLI** - Genera el código automáticamente
4. 💾 **Realiza un commit** - Guarda los cambios con mensajes descriptivos
5. 🚀 **Hace push de la rama** - Sube los cambios al repositorio
6. 📬 **Crea un Pull Request** - Abre la PR automáticamente
7. 🔗 **Vincula todo en Azure DevOps** - Conecta la rama, commit y PR con el work item

## 🛠️ Tecnologías Utilizadas

- **Azure DevOps** - Gestión de work items y pipelines
- **GitHub Copilot CLI** - Generación automática de código con IA
- **Bash Scripts** - Automatización y orquestación
- **Node.js 22.x** - Runtime para Copilot CLI
- **Python 3.x** - Herramientas auxiliares
- **MCP Servers** - Context7 para documentación actualizada

## 📦 Estructura del Proyecto

```
├── azure-pipelines.yml          # Definición del pipeline
├── mcp-config.json              # Configuración de MCP Servers
├── .github/
│   └── copilot-instructions.md  # Instrucciones para Copilot
└── scripts/                     # Scripts de automatización
    ├── clone-target-repo.sh
    ├── create-pr-and-link.sh
    ├── push-branch.sh
    └── ...
```

## ⚙️ Configuración Requerida

### Variables de Entorno

- `GH_TOKEN` - Token de GitHub con el permiso Copilot Requests
- `AZURE_DEVOPS_PAT` - Personal Access Token de Azure DevOps del usuario que simula GitHub Copilot CLI
- `CONTEXT7_API_KEY` - API key para Context7 (documentación)
- `COPILOT_VERSION` - Versión de Copilot CLI a instalar, para evitar que deje de funcionar el flujo si algo importante ha cambiado
- `MODEL` - Modelo de lenguaje a utilizar (ej. claude-sonnet-4)

### WebHook de Azure DevOps

El pipeline se activa mediante un WebHook configurado en Azure DevOps que dispara cuando se crean o actualizan elementos de trabajo.

Si quieres ver cómo se configura el mismo puedes echar un vistazo a mi artículo [Cómo ejecutar un flujo de Azure Pipelines 🚀 cuando se crea un work item](https://www.returngis.net/2025/10/como-ejecutar-un-flujo-de-azure-pipelines-%f0%9f%9a%80-cuando-se-crea-un-work-item/)

## 📝 Cómo Funciona el Pipeline - Paso a Paso

El pipeline ejecuta los siguientes pasos de forma automática:

### 🔧 Preparación del Entorno
1. **🚀 Iniciar Pipeline** - Inicia el flujo de trabajo
2. **🐍 Setup Python** - Instala Python 3.x
3. **📦 Instalar uv/uvx** - Gestor de paquetes rápido
4. **⚙️ Setup Node.js 22.x** - Instala Node.js para Copilot CLI
5. **🔍 Detectar Ruta NPM** - Localiza la ruta global de NPM
6. **📦 Cache de Paquetes NPM** - Cachea paquetes globales para acelerar ejecuciones futuras
7. **📦 Instalar Copilot CLI** - Instala @github/copilot en la versión especificada

### 📋 Procesamiento del Work Item
8. **📋 Parsear Datos del Webhook** - Extrae información del evento (ID, título, descripción, etc.)
9. **🛎️ Clonar Repositorio** - Clona el repositorio destino donde se generará el código
10. **📖 Leer Detalles del Work Item** - Obtiene toda la información del work item desde Azure DevOps
11. **🚀 Inicializar Work Item** - Cambia el estado a "Development" y prepara el work item

### 🔐 Configuración de Seguridad y Herramientas
12. **⚙️ Configurar MCP Servers** - Copia la configuración de MCP (Context7, etc.) a ~/.config/
13. **🧰 Verificar Acceso a MCP** - Comprueba que todos los MCP servers están disponibles

### 💻 Generación de Código
14. **🌿 Crear Rama de Características** - Crea `copilot/<work-item-id>`
15. **🤖 Ejecutar GitHub Copilot CLI** - Genera el código basado en la descripción del work item
    - Copia las instrucciones de Copilot al repositorio
    - Ejecuta Copilot con el modelo especificado (ej: claude-sonnet-4)
    - Registra todos los logs detallados

### 📤 Commit y Publicación
16. **💾 Preparar y Realizar Commit** - Crea un commit con el código generado
    - Genera `copilot-summary.md` (descripción de cambios)
    - Genera `commit-message.md` (mensaje de commit)
17. **🚀 Push de la Rama** - Sube la rama al repositorio remoto

### 🔗 Integración y Vinculación
18. **� Vincular Rama al Work Item** - Vincula la rama de características con el work item
19. **🔧 Actualizar Actividad del Work Item** - Marca la actividad como "Development"
20. **📬 Crear PR y Vincularla** - Crea un Pull Request y la vincula al work item

### 🎉 Finalización
21. **💬 Añadir Comentario de Finalización** - Comenta en el work item con el enlace a la PR
22. **📦 Publicar Logs** - Guarda todos los logs del pipeline como artefactos

## 🔄 Flujo de Trabajo Completo

```
Work Item Created/Updated
         ↓
    Setup Entorno
    (Python, Node.js, NPM)
         ↓
  Cache de Paquetes NPM
         ↓
Instalar Copilot CLI
         ↓
 Parsear Datos Webhook
         ↓
Clone Repositorio
         ↓
Leer Detalles del Work Item
         ↓
Inicializar Work Item
         ↓
Configurar MCP Servers
         ↓
Verificar Acceso MCP
         ↓
Create Branch (copilot/xxx)
         ↓
  Run GitHub Copilot
    (Genera código IA)
         ↓
   Commit Changes
         ↓
   Push to Remote
         ↓
  Link Branch to WI
         ↓
Update Activity (Development)
         ↓
  Create Pull Request
         ↓
 Link PR to Work Item
         ↓
Add Completion Comment
         ↓
  Publish Logs
         ↓
✅ Workflow Complete
```