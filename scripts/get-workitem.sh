#!/bin/bash

# Script para recuperar información de un Work Item de Azure DevOps
# Uso: ./get-workitem.sh <organization> <project> <work-item-id>

set -e

# Función para mostrar uso
show_usage() {
    echo "Usage: $0 <organization> <project> <work-item-id>"
    echo ""
    echo "Arguments:"
    echo "  organization      : Azure DevOps organization name"
    echo "  project          : Project name (will be URL-encoded automatically)"
    echo "  work-item-id     : Work Item ID number"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' 412"
    exit 1
}

# Validar argumentos
if [ $# -ne 3 ]; then
    echo "❌ Error: Incorrect number of arguments (expected 3, got $#)"
    echo ""
    show_usage
fi

ORGANIZATION="$1"
PROJECT="$2"
WORK_ITEM_ID="$3"

# Validar PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode el nombre del proyecto
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "🔍 Retrieving Work Item from Azure DevOps"
echo "=========================================="
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Work Item ID: $WORK_ITEM_ID"
echo ""

# Codificar PAT en Base64
PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64)

# Obtener el work item
API_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.0"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "$API_URL" \
  -H "Authorization: Basic ${PAT_BASE64}" \
  -H "Content-Type: application/json")

BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$STATUS" -ne 200 ]; then
    echo "❌ Error: Could not retrieve work item (HTTP $STATUS)"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi

echo "✅ Work item retrieved successfully!"
echo ""
echo "================================================"
echo "📋 Work Item Details"
echo "================================================"

# Extraer información clave
TITLE=$(echo "$BODY" | jq -r '.fields["System.Title"]')
STATE=$(echo "$BODY" | jq -r '.fields["System.State"]')
WORK_ITEM_TYPE=$(echo "$BODY" | jq -r '.fields["System.WorkItemType"]')
ASSIGNED_TO=$(echo "$BODY" | jq -r '.fields["System.AssignedTo"].displayName // "Unassigned"')
CREATED_BY=$(echo "$BODY" | jq -r '.fields["System.CreatedBy"].displayName')
CREATED_BY_EMAIL=$(echo "$BODY" | jq -r '.fields["System.CreatedBy"].uniqueName')
CREATED_DATE=$(echo "$BODY" | jq -r '.fields["System.CreatedDate"]')
ACTIVITY=$(echo "$BODY" | jq -r '.fields["Microsoft.VSTS.Common.Activity"] // "Not set"')
DESCRIPTION=$(echo "$BODY" | jq -r '.fields["System.Description"] // "No description"')

echo "ID:              $WORK_ITEM_ID"
echo "Type:            $WORK_ITEM_TYPE"
echo "Title:           $TITLE"
echo "State:           $STATE"
echo "Activity:        $ACTIVITY"
echo "Assigned To:     $ASSIGNED_TO"
echo "Created By:      $CREATED_BY ($CREATED_BY_EMAIL)"
echo "Created Date:    $CREATED_DATE"
echo ""
echo "Description:"
echo "---"
# Eliminar HTML tags básicos para mejor lectura
echo "$DESCRIPTION" | sed 's/<[^>]*>//g' | sed 's/&nbsp;/ /g' | head -20
echo ""
echo "================================================"
echo ""

# Información útil para otros scripts
echo "📝 Extracted Information for Scripts:"
echo "---"
echo "Project:              $PROJECT"
echo "Created By Name:      $CREATED_BY"
echo "Created By Email:     $CREATED_BY_EMAIL"
echo "Work Item Type:       $WORK_ITEM_TYPE"
echo "Current State:        $STATE"
echo "Current Activity:     $ACTIVITY"
echo ""

# Mostrar JSON completo opcionalmente
if [ "$VERBOSE" = "true" ]; then
    echo "================================================"
    echo "📄 Full JSON Response:"
    echo "================================================"
    echo "$BODY" | jq '.'
fi

# Retornar éxito
exit 0
