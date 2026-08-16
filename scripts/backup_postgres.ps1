# backup_postgres.ps1 -- respaldo manual/programado de Postgres (Infinite Power)
#
# Que hace: corre pg_dump dentro del contenedor de Postgres y guarda el
# resultado en backups/ (gitignored, nunca se commitea - son datos reales,
# no schema). Guarda solo los ultimos $Retener respaldos, borra el resto.
#
# Uso manual:
#   .\scripts\backup_postgres.ps1
#
# Uso programado (recomendado, semanal como minimo, ver pendiente de Bloque 0):
#   Windows Task Scheduler -> crear tarea -> accion:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\2\Documents\infinite-power\scripts\backup_postgres.ps1"
#   disparador: semanal, el dia/hora que prefieras.
#
# No reemplaza un respaldo real fuera de la maquina (esto sigue viviendo en
# el mismo disco que la base de datos) - sirve para recuperarse de un error
# de migracion o un DROP accidental, no de una falla de disco.

param(
    [string]$ContainerName = "infinite-power-postgres-1",
    [string]$DbUser = "infpower",
    [string]$DbName = "infinite_power",
    [string]$BackupDir = "$PSScriptRoot\..\backups",
    [int]$Retener = 8
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$outFile = Join-Path $BackupDir "infinite_power_$timestamp.sql"

Write-Host "Corriendo pg_dump contra $ContainerName ($DbName)..."
docker exec $ContainerName pg_dump -U $DbUser -d $DbName --no-owner | Out-File -FilePath $outFile -Encoding utf8

if ((Get-Item $outFile).Length -lt 100) {
    Write-Error "El respaldo salio sospechosamente chico ($((Get-Item $outFile).Length) bytes) - revisar antes de confiar en el."
    exit 1
}

Write-Host "Respaldo guardado: $outFile ($((Get-Item $outFile).Length) bytes)"

# Limpieza: se queda solo con los $Retener mas recientes
$viejos = Get-ChildItem $BackupDir -Filter "infinite_power_*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Retener
if ($viejos) {
    Write-Host "Borrando $($viejos.Count) respaldo(s) viejo(s), se quedan los $Retener mas recientes..."
    $viejos | Remove-Item -Force
}
