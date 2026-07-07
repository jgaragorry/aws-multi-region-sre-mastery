#!/bin/bash
BUCKET_NAME="garagorry-sre-tfstate-global"

echo "🔥 [PURGA] Destruyendo Backend Remoto de iac-mastery_7..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "⏳ Vaciando todas las versiones y marcadores de eliminacion en S3..."
    
    # Borrar todas las versiones de objetos de forma masiva
    aws s3api delete-objects --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null || true
        
    # Borrar todos los marcadores de eliminacion (Delete Markers) rezagados
    aws s3api delete-objects --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null || true

    echo "🗑️ Eliminando el contenedor logico del bucket..."
    aws s3 rb "s3://$BUCKET_NAME" --force
    
    echo "🟢 [ÉXITO] El Backend Remoto ha sido completamente erradicado."
else
    echo "✔ Nada que eliminar. El bucket no existe."
fi
