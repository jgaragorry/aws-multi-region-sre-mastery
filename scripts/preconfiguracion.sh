#!/bin/bash
set -e

BUCKET_NAME="garagorry-sre-tfstate-global"
REGION="us-east-1"

echo "🛡️ [PRECONFIGURACIÓN] Validando Binarios e Infraestructura..."

# 1. Validar Terraform Nativo (No OpenTofu)
#if tofu version &>/dev/null; then
#    echo "❌ ERROR: OpenTofu detectado. Este laboratorio requiere Terraform nativo oficial."
#    exit 1
#fi

TF_VERSION=$(terraform -version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "✔ Terraform oficial detectado: v$TF_VERSION"

# 2. Validar versión >= 1.10
if [ "$(echo -e "1.10.0\n$TF_VERSION" | sort -V | head -n1)" != "1.10.0" ]; then
    echo "❌ ERROR: Se requiere Terraform v1.10 o superior para el soporte nativo de backend S3."
    exit 1
fi

# 3. Crear Bucket S3 de forma Idempotente con Object Lock habilitado
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✔ El bucket S3 '$BUCKET_NAME' ya existe. Validando propiedades..."
else
    echo "🚀 Creando bucket S3 '$BUCKET_NAME'..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --object-lock-enabled-for-bucket
fi

# 4. Asegurar Cifrado AES256
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# 5. Asegurar Versionado Estricto
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "🟢 [ÉXITO] Backend S3 Nativo inicializado y securizado para iac-mastery_7."
