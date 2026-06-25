param([string]$RunId = "RUN_$(Get-Date -Format 'yyyyMMdd_HHmm')")

# --- 1. CONFIGURACIÓN ---
$logDir = "C:\MTTD"
$csvPath = "$logDir\mttd_dataset.csv"

if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir }

# Si el CSV no existe, creamos la cabecera
if (!(Test-Path $csvPath)) {
    "RunId;StartTime;EndTime;MTTD_Seconds;Action" | Out-File -FilePath $csvPath -Encoding utf8
}

# --- 2. INICIO (T0) ---
$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
Write-Host "[+] Ejecución $RunId iniciada a las $startTime" -ForegroundColor Cyan

# Escribimos en el Log de Eventos de Windows (esto lo leerá Wazuh)
# Usamos el ID 999 para identificar fácilmente nuestro inicio en los logs
Write-EventLog -LogName Application -Source "MsiInstaller" -EventId 999 -EntryType Information `
               -Message "MTTD_START: RunId=$RunId, StartTime=$startTime"

# --- 3. ATAQUE SIMULADO ---
# Acción A: Comando vssadmin (detección casi segura por Sysmon/Wazuh)
vssadmin.exe delete shadows /all /quiet 

# Acción B: Simulación de cifrado (creación de archivos)
for ($i=1; $i -le 15; $i++) {
    "Contenido simulado Conti" | Out-File -FilePath "$logDir\encrypt_test_$i.txt" -Force
}

# --- 4. REGISTRO EN CSV ---
# El EndTime y el MTTD quedarán vacíos (o con PENDING) para llenarlos con la alerta de Wazuh
# Esto genera una fila lista para ser completada tras el análisis
"$RunId;$startTime;PENDING;0;vssadmin_execution" | Out-File -FilePath $csvPath -Append -Encoding utf8

Write-Host "[+] Trazas generadas. Esperando detección en Wazuh..." -ForegroundColor Yellow
