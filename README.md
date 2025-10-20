# 🤖 Azure DevOps Coding Agent gracias a GitHub Copilot CLI

<div align="center">

[![YouTube Channel Subscribers](https://img.shields.io/youtube/channel/subscribers/UC140iBrEZbOtvxWsJ-Tb0lQ?style=for-the-badge&logo=youtube&logoColor=white&color=red)](https://www.youtube.com/c/GiselaTorres?sub_confirmation=1)
[![GitHub followers](https://img.shields.io/github/followers/0GiS0?style=for-the-badge&logo=github&logoColor=white)](https://github.com/0GiS0)
[![LinkedIn Follow](https://img.shields.io/badge/LinkedIn-Sígueme-blue?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/giselatorresbuitrago/)
[![X Follow](https://img.shields.io/badge/X-Sígueme-black?style=for-the-badge&logo=x&logoColor=white)](https://twitter.com/0GiS0)

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

## 📝 Cómo Funciona el Pipeline

1. **Webhook trigger** 📡 - Se dispara al crear/actualizar un work item
2. **Parse data** 📋 - Extrae información del evento
3. **Clone repo** 🛎️ - Clona el repositorio destino
4. **Create branch** 🌿 - Crea rama de características
5. **Run Copilot** 🤖 - Genera el código automáticamente
6. **Commit & Push** 💾 - Guardar y subir cambios
7. **Create PR** 📬 - Abre Pull Request automática
8. **Link resources** 🔗 - Vincula todo en Azure DevOps

## 🔄 Flujo de Trabajo

```
Work Item Created/Updated
         ↓
    Parse Webhook
         ↓
   Clone Repository
         ↓
  Create Branch (copilot/xxx)
         ↓
  Run GitHub Copilot
         ↓
   Commit Changes
         ↓
   Push to Remote
         ↓
  Create Pull Request
         ↓
Link PR to Work Item
```