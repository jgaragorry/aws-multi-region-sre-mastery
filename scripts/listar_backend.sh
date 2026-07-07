#!/bin/bash
BUCKET_NAME="garagorry-sre-tfstate-global"

echo "🔎 [AUDITORÍA] Listando estados remotos de iac-mastery_7 en S3..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    aws s3 ls "s3://$BUCKET_NAME" --recursive
else
    echo "❌ El backend '$BUCKET_NAME' no existe actualmente en AWS."
fi
