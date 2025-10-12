#!/bin/bash

# Script para añadir un Required Reviewer a una PR de Azure DevOps
# Uso: ./add-required-reviewer.sh <organization> <project> <repository-id> <pr-id> <reviewer-email>

set -e

# Función para mostrar uso
show_usage() {
    echo "Usage: $0 <organization> <project> <repository-id> <pr-id> <reviewer-email>"
    echo ""
    echo "Arguments:"
    echo "  organization      : Azure DevOps organization name"
    echo "  project          : Project name (will be URL-encoded automatically)"
    echo "  repository-id    : Repository GUID"
    echo "  pr-id           : Pull Request ID number"
    echo "  reviewer-email  : Email address of the reviewer"
    echo ""
    echo "Environment Variables Required:"
    echo "  AZURE_DEVOPS_PAT : Personal Access Token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 myorg 'My Project' abc-123-def 42 user@example.com"
    exit 1
}

# Validar argumentos
if [ $# -ne 5 ]; then
    echo "❌ Error: Incorrect number of arguments"
    echo ""
    show_usage
fi

ORGANIZATION="$1"
PROJECT="$2"
REPOSITORY_ID="$3"
PULL_REQUEST_ID="$4"
REVIEWER_EMAIL="$5"

# Validar PAT
if [ -z "$AZURE_DEVOPS_PAT" ]; then
    echo "❌ Error: AZURE_DEVOPS_PAT environment variable is not set"
    echo "   Set it with: export AZURE_DEVOPS_PAT='your-pat-token'"
    exit 1
fi

# URL-encode el nombre del proyecto
PROJECT_ENCODED=$(echo "$PROJECT" | sed 's/ /%20/g')

echo "🔧 Adding Required Reviewer to Azure DevOps PR"
echo "================================================"
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Repository ID: $REPOSITORY_ID"
echo "PR ID: $PULL_REQUEST_ID"
echo "Reviewer Email: $REVIEWER_EMAIL"
echo ""

# Codificar PAT en Base64 (sin saltos de línea)
if base64 --help 2>&1 | grep -q "wrap"; then
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 -w 0)
else
    PAT_BASE64=$(echo -n ":${AZURE_DEVOPS_PAT}" | base64 | tr -d '\n')
fi

# Paso 1: Obtener el Identity ID del usuario por email
echo "📋 Step 1: Finding reviewer Identity ID..."
echo "-------------------------------------------"

# Primero intentar obtener el equipo del proyecto
TEAM_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "https://dev.azure.com/${ORGANIZATION}/_apis/projects/${PROJECT_ENCODED}/teams?api-version=7.0" \
  -H "Authorization: Basic ${PAT_BASE64}")

TEAM_BODY=$(echo "$TEAM_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
TEAM_STATUS=$(echo "$TEAM_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$TEAM_STATUS" -ne 200 ]; then
    echo "❌ Error: Could not get project teams (HTTP $TEAM_STATUS)"
    echo "$TEAM_BODY"
    exit 1
fi

TEAM_ID=$(echo "$TEAM_BODY" | jq -r '.value[0].id')

if [ -z "$TEAM_ID" ] || [ "$TEAM_ID" = "null" ]; then
    echo "❌ Error: Could not find team ID for project"
    exit 1
fi

echo "✅ Team ID: $TEAM_ID"

# Obtener miembros del equipo y buscar por email
MEMBERS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "https://dev.azure.com/${ORGANIZATION}/_apis/projects/${PROJECT_ENCODED}/teams/${TEAM_ID}/members?api-version=7.0" \
  -H "Authorization: Basic ${PAT_BASE64}")

MEMBERS_BODY=$(echo "$MEMBERS_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
MEMBERS_STATUS=$(echo "$MEMBERS_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$MEMBERS_STATUS" -ne 200 ]; then
    echo "❌ Error: Could not get team members (HTTP $MEMBERS_STATUS)"
    echo "$MEMBERS_BODY"
    exit 1
fi

REVIEWER_ID=$(echo "$MEMBERS_BODY" | jq -r --arg email "$REVIEWER_EMAIL" '.value[] | select(.identity.uniqueName == $email) | .identity.id')

if [ -z "$REVIEWER_ID" ] || [ "$REVIEWER_ID" = "null" ]; then
    echo "❌ Error: Could not find user with email: $REVIEWER_EMAIL"
    echo "   Make sure the user is a member of the project team"
    exit 1
fi

REVIEWER_NAME=$(echo "$MEMBERS_BODY" | jq -r --arg email "$REVIEWER_EMAIL" '.value[] | select(.identity.uniqueName == $email) | .identity.displayName')

echo "✅ Found reviewer: $REVIEWER_NAME"
echo "✅ Identity ID: $REVIEWER_ID"
echo ""

# Paso 2: Añadir el reviewer como Required a la PR
echo "📝 Step 2: Adding as Required Reviewer..."
echo "-------------------------------------------"

API_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/git/repositories/${REPOSITORY_ID}/pullRequests/${PULL_REQUEST_ID}/reviewers/${REVIEWER_ID}?api-version=6.1-preview.1"

REQUEST_BODY=$(cat <<EOF
{
  "id": "${REVIEWER_ID}",
  "isRequired": true
}
EOF
)

ADD_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PUT \
  "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic ${PAT_BASE64}" \
  -d "$REQUEST_BODY")

ADD_BODY=$(echo "$ADD_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
ADD_STATUS=$(echo "$ADD_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$ADD_STATUS" -ne 200 ]; then
    echo "❌ Error: Could not add reviewer (HTTP $ADD_STATUS)"
    echo "$ADD_BODY" | jq '.' || echo "$ADD_BODY"
    exit 1
fi

echo "✅ Reviewer added successfully!"
echo ""

# Paso 3: Verificar que es Required
echo "🔍 Step 3: Verifying Required Reviewer status..."
echo "-------------------------------------------"

VERIFY_URL="https://dev.azure.com/${ORGANIZATION}/${PROJECT_ENCODED}/_apis/git/repositories/${REPOSITORY_ID}/pullRequests/${PULL_REQUEST_ID}/reviewers/${REVIEWER_ID}?api-version=6.1-preview.1"

VERIFY_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET \
  "$VERIFY_URL" \
  -H "Authorization: Basic ${PAT_BASE64}")

VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
VERIFY_STATUS=$(echo "$VERIFY_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$VERIFY_STATUS" -ne 200 ]; then
    echo "⚠️  Warning: Could not verify reviewer status (HTTP $VERIFY_STATUS)"
    echo "$VERIFY_BODY"
    exit 0
fi

IS_REQUIRED=$(echo "$VERIFY_BODY" | jq -r '.isRequired')
DISPLAY_NAME=$(echo "$VERIFY_BODY" | jq -r '.displayName')

echo "✅ Reviewer: $DISPLAY_NAME"
echo "✅ Email: $REVIEWER_EMAIL"
echo "✅ isRequired: $IS_REQUIRED"
echo ""

if [ "$IS_REQUIRED" = "true" ]; then
    echo "✅✅✅ SUCCESS: Reviewer is REQUIRED"
    echo ""
    echo "================================================"
    echo "🎉 Required Reviewer added successfully!"
    echo "================================================"
    exit 0
else
    echo "❌ ERROR: Reviewer is NOT required (isRequired=$IS_REQUIRED)"
    exit 1
fi
