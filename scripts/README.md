# Scripts

Este directorio contiene scripts auxiliares utilizados por GitHub Copilot CLI para automatizar tareas de Azure DevOps.

## add-required-reviewer.sh

Script para añadir un reviewer obligatorio (Required Reviewer) a una Pull Request de Azure DevOps.

### Uso

```bash
./scripts/add-required-reviewer.sh <organization> <project> <repository-id> <pr-id> <reviewer-email>
```

### Parámetros

- **organization**: Nombre de la organización de Azure DevOps
- **project**: Nombre del proyecto (puede contener espacios, se URL-encode automáticamente)
- **repository-id**: GUID del repositorio
- **pr-id**: Número de ID de la Pull Request
- **reviewer-email**: Email del usuario que será el reviewer

### Variables de entorno requeridas

- **AZURE_DEVOPS_PAT**: Personal Access Token con permisos de `vso.code_write`

### Ejemplo

```bash
export AZURE_DEVOPS_PAT="your-pat-token"
./scripts/add-required-reviewer.sh returngisorg "GitHub Copilot CLI" 0c295722-b409-4a3f-976d-6cd9614425fe 75 user@example.com
```

### Qué hace el script

1. **Busca el Identity ID del usuario**: Consulta los miembros del equipo del proyecto para encontrar el usuario por email
2. **Añade el reviewer como Required**: Usa la API REST de Azure DevOps para añadir el reviewer con `isRequired: true`
3. **Verifica el resultado**: Confirma que el reviewer fue añadido correctamente y que es obligatorio

### Salida exitosa

```
🔧 Adding Required Reviewer to Azure DevOps PR
================================================
Organization: returngisorg
Project: GitHub Copilot CLI
Repository ID: 0c295722-b409-4a3f-976d-6cd9614425fe
PR ID: 75
Reviewer Email: user@example.com

📋 Step 1: Finding reviewer Identity ID...
-------------------------------------------
✅ Team ID: f8266e69-c3c5-4855-90ec-d9ceb9ffb8ac
✅ Found reviewer: User Name
✅ Identity ID: ace1e6a3-a67d-6acb-b81b-f3304b45453c

📝 Step 2: Adding as Required Reviewer...
-------------------------------------------
✅ Reviewer added successfully!

🔍 Step 3: Verifying Required Reviewer status...
-------------------------------------------
✅ Reviewer: User Name
✅ Email: user@example.com
✅ isRequired: true

✅✅✅ SUCCESS: Reviewer is REQUIRED

================================================
🎉 Required Reviewer added successfully!
================================================
```

### Códigos de salida

- **0**: Éxito - El reviewer fue añadido correctamente como Required
- **1**: Error - Falló algún paso del proceso

### Errores comunes

#### Error: AZURE_DEVOPS_PAT no está configurado
```
❌ Error: AZURE_DEVOPS_PAT environment variable is not set
```
**Solución**: Exporta la variable de entorno con tu PAT

#### Error: Usuario no encontrado
```
❌ Error: Could not find user with email: user@example.com
```
**Solución**: Verifica que el email es correcto y que el usuario es miembro del proyecto

#### Error: Argumentos incorrectos
```
❌ Error: Incorrect number of arguments
```
**Solución**: Asegúrate de proporcionar los 5 argumentos requeridos

## Uso en GitHub Copilot CLI

Este script es utilizado automáticamente por GitHub Copilot CLI como parte del workflow de implementación de work items. El agente:

1. Crea la Pull Request en modo Draft
2. Extrae la información necesaria del work item
3. Ejecuta este script para añadir al creador del work item como Required Reviewer
4. Verifica que el reviewer fue añadido correctamente

No es necesario ejecutar este script manualmente a menos que estés haciendo pruebas o debugging.
