$logDir = "C:\MTTD"
$csvPath = "$logDir\mttd_dataset.csv"

if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

# 1) Borrar artefactos de archivos (simulación de cifrado)
Get-ChildItem -Path $logDir -Filter "encrypt_test_*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# 2) Rotar dataset anterior (si existe)
if (Test-Path $csvPath) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Rename-Item -Path $csvPath -NewName "mttd_dataset_$stamp.csv"
}

# 3) Crear CSV nuevo con cabecera
"RunId;StartTime;EndTime;MTTD_Seconds;Action" | Out-File -FilePath $csvPath -Encoding utf8
Write-Host "[+] Reset completado. CSV nuevo listo en $csvPath"
