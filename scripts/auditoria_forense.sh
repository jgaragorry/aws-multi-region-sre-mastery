#!/bin/bash
# ==============================================================================
# SCRIPT DE AUDITORÍA FORENSE DE CERTEZA ABSOLUTA (LAB 7)
# ==============================================================================
# Propósito: Auditoría total y profunda de escombros de infraestructura.
# Regiones afectadas: us-east-1 (Virginia) y us-west-2 (Oregón)
# Idempotencia: Sí. Operaciones 100% de lectura (Read-Only).
# ==============================================================================

REGIONES=("us-east-1" "us-west-2")
TAG_KEY="Lab"
TAG_VALUE="iac-mastery_7"
SSM_PREFIX="/sre"
BUCKET_NAME="garagorry-sre-tfstate-global"

echo "=============================================================================="
echo "🛡️ INICIANDO AUDITORÍA FORENSE DE CERTEZA ABSOLUTA (CERO FACTURACIÓN)"
echo "=============================================================================="

# ------------------------------------------------------------------------------
# AUDITORÍA GLOBAL: CAPA DE ALMACENAMIENTO CENTRALIZADO (S3)
# ------------------------------------------------------------------------------
echo "🔹 [S3 GLOBAL] Verificando existencia del Backend Remoto..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "  ⚠ ALERTA - El bucket '$BUCKET_NAME' todavía existe de forma activa."
    echo "  Recuerda ejecutar ./scripts/eliminar_backend.sh para evitar residuos."
else
    echo "  ✔ El bucket de almacenamiento global no existe (Eliminado correctamente)."
fi
echo "------------------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# AUDITORÍA REGIONAL: CAPAS DE CÓMPUTO, DISCOS, REDES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
for REGION in "${REGIONES[@]}"; do
    echo ""
    echo "🌐 [REGIÓN: $REGION] Escaneando todas las capas de infraestructura..."
    echo "------------------------------------------------------------------------------"

    # 1. CAPA DE CÓMPUTO: Instancias EC2
    echo "🔹 [EC2] Buscando instancias activas, pendientes o colgadas..."
    INSTANCES=$(aws ec2 describe-instances \
        --region "$REGION" \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
            "Name=instance-state-name,Values=pending,running,shutting-down,stopping" \
        --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value | [0]}" \
        --output table 2>/dev/null)

    if [[ -z "$INSTANCES" || "$INSTANCES" == "-----------------------" || "$INSTANCES" == "None" ]]; then
        echo "  ✔ Cero instancias EC2 detectadas."
    else
        echo "  ⚠ ALERTA - Instancias zombies:"
        echo "$INSTANCES"
    fi

    # 2. CAPA DE ALMACENAMIENTO: Volúmenes EBS (Discos activos)
    echo "🔹 [EBS] Buscando discos duros huérfanos..."
    VOLUMES=$(aws ec2 describe-volumes \
        --region "$REGION" \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
        --query "Volumes[*].{ID:VolumeId,Size:Size,State:State}" \
        --output table 2>/dev/null)

    if [[ -z "$VOLUMES" || "$VOLUMES" == "-----------------------" || "$VOLUMES" == "None" ]]; then
        echo "  ✔ Cero volúmenes EBS detectados."
    else
        echo "  ⚠ ALERTA - Discos sueltos cobrando por gigabyte:"
        echo "$VOLUMES"
    fi

    # 3. CAPA DE ALMACENAMIENTO RESIDUAL: Snapshots (Copias de seguridad de discos)
    echo "🔹 [SNAPSHOT] Buscando respaldos de discos residuales..."
    SNAPSHOTS=$(aws ec2 describe-snapshots \
        --region "$REGION" \
        --owner-ids self \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
        --query "Snapshots[*].{ID:SnapshotId,Volume:VolumeId,Size:VolumeSize}" \
        --output table 2>/dev/null)

    if [[ -z "$SNAPSHOTS" || "$SNAPSHOTS" == "-----------------------" || "$SNAPSHOTS" == "None" ]]; then
        echo "  ✔ Cero snapshots residuales detectados."
    else
        echo "  ⚠ ALERTA - Snapshots huérfanos cobrando almacenamiento histórico:"
        echo "$SNAPSHOTS"
    fi

    # 4. CAPA DE REDES: Direcciones IP Elásticas (Elastic IPs)
    echo "🔹 [EIP] Buscando asignaciones de direcciones IP públicas fijas..."
    EIPS=$(aws ec2 describe-addresses \
        --region "$REGION" \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
        --query "Addresses[*].{IP:PublicIp,AllocationId:AllocationId}" \
        --output table 2>/dev/null)

    if [[ -z "$EIPS" || "$EIPS" == "-----------------------" || "$EIPS" == "None" ]]; then
        echo "  ✔ Cero IPs Elásticas remanentes."
    else
        echo "  ⚠ ALERTA - IPs públicas inactivas (AWS cobra penalización por hora si no se usan):"
        echo "$EIPS"
    fi

    # 5. CAPA DE CONFIGURACIÓN: SSM Parameter Store
    echo "🔹 [SSM] Buscando parámetros residuales de configuración..."
    PARAMETERS=$(aws ssm describe-parameters \
        --region "$REGION" \
        --query "Parameters[?contains(Name, '$SSM_PREFIX')].{Name:Name,Type:Type}" \
        --output table 2>/dev/null)

    if [[ -z "$PARAMETERS" || "$PARAMETERS" == "-----------------------" || "$PARAMETERS" == "None" ]]; then
        echo "  ✔ Cero parámetros lógicos detectados."
    else
        echo "  ⚠ ALERTA - Parámetros huérfanos:"
        echo "$PARAMETERS"
    fi

    # 6. CAPA DE RED LOGICA: VPCs del Laboratorio
    echo "🔹 [VPC] Buscando redes lógicas del laboratorio..."
    VPCS=$(aws ec2 describe-vpcs \
        --region "$REGION" \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
        --query "Vpcs[*].{ID:VpcId,Cidr:CidrBlock,State:State}" \
        --output table 2>/dev/null)

    if [[ -z "$VPCS" || "$VPCS" == "-----------------------" || "$VPCS" == "None" ]]; then
        echo "  ✔ Cero redes VPC detectadas."
    else
        echo "  ⚠ ALERTA - Redes lógicas activas:"
        echo "$VPCS"
    fi

    # 7. CAPA DE RED LOGICA: Subredes (Subnets)
    echo "🔹 [SUBNET] Buscando subredes asociadas de forma remanente..."
    SUBNETS=$(aws ec2 describe-subnets \
        --region "$REGION" \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
        --query "Subnets[*].{ID:SubnetId,Vpc:VpcId,Cidr:CidrBlock}" \
        --output table 2>/dev/null)

    if [[ -z "$SUBNETS" || "$SUBNETS" == "-----------------------" || "$SUBNETS" == "None" ]]; then
        echo "  ✔ Cero subredes detectadas."
    else
        echo "  ⚠ ALERTA - Subredes huérfanas:"
        echo "$SUBNETS"
    fi

    # 8. CAPA DE SEGURIDAD: Security Groups del Laboratorio
    echo "🔹 [SG] Buscando grupos de seguridad personalizados..."
    SGS=$(aws ec2 describe-security-groups \
        --region "$REGION" \
        --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
        --query "SecurityGroups[*].{ID:GroupId,Name:GroupName}" \
        --output table 2>/dev/null)

    if [[ -z "$SGS" || "$SGS" == "-----------------------" || "$SGS" == "None" ]]; then
        echo "  ✔ Cero grupos de seguridad remanentes."
    else
        echo "  ⚠ ALERTA - Grupos de seguridad personalizados sin borrar:"
        echo "$SGS"
    fi

done

echo ""
echo "=============================================================================="
echo "🏁 AUDITORÍA FORENSE ULTRA-PROVADA FINALIZADA"
echo "=============================================================================="
