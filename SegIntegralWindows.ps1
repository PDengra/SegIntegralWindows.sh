<#
.SYNOPSIS
Script Avanzado de Auditoría y Hardening de Sistemas Windows
.Autor: Pablo Dengra 
.Fecha: $(Get-Date -Format "yyyy-MM-dd")
#>

# ============================
# Variables
# ============================
$Informe = "$env:USERPROFILE\auditoria_seguridad_completa_$(Get-Date -Format yyyyMMdd).html"
$Email = "admin@tuservidor.com"
$SmtpServer = "smtp.tuservidor.com"
$SmtpPort = 587
$SmtpUser = "usuario_smtp"
$SmtpPass = "contraseña_smtp"

$TelegramBotToken = "AQUI_TU_TOKEN"
$TelegramChatID = "AQUI_TU_CHAT_ID"

# ============================
# Cabecera del informe
# ============================
"<html><body><h1>Auditoría de Seguridad Completa - $(Get-Date)</h1><h2>Host: $env:COMPUTERNAME</h2>" | Out-File $Informe

# 1. Información del sistema
"<h3>Sistema operativo:</h3>" | Out-File $Informe -Append
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 2. Usuarios locales
"<h3>Usuarios locales:</h3>" | Out-File $Informe -Append
Get-LocalUser | Select-Object Name, Enabled, LastLogon | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 3. Miembros de Administradores
"<h3>Miembros del grupo Administradores:</h3>" | Out-File $Informe -Append
Get-LocalGroupMember Administrators | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 4. Procesos TOP 5 por CPU
"<h3>Procesos TOP 5 por CPU:</h3>" | Out-File $Informe -Append
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, Id | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 5. Servicios activos
"<h3>Servicios activos (Running):</h3>" | Out-File $Informe -Append
Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name, DisplayName, Status | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 6. Puertos abiertos
"<h3>Puertos y servicios abiertos:</h3>" | Out-File $Informe -Append
Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, State, OwningProcess | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 7. Tareas programadas
"<h3>Tareas programadas:</h3>" | Out-File $Informe -Append
Get-ScheduledTask | Select-Object TaskName, State, LastRunTime | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 8. Archivos críticos (System32 ejecutables)
"<h3>Archivos ejecutables críticos:</h3>" | Out-File $Informe -Append
Get-ChildItem C:\Windows\System32\*.exe | Select-Object Name, Length, LastWriteTime | Sort-Object Length -Descending | Select-Object -First 10 | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 9. Uso de disco
"<h3>Uso de disco:</h3>" | Out-File $Informe -Append
Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free, @{Name="UsedGB";Expression={[math]::Round($_.Used/1GB,2)}}, @{Name="FreeGB";Expression={[math]::Round($_.Free/1GB,2)}} | ConvertTo-Html -Fragment | Out-File $Informe -Append

# 10. Actualizaciones pendientes (requiere módulo PSWindowsUpdate)
"<h3>Actualizaciones pendientes:</h3>" | Out-File $Informe -Append
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Get-WindowsUpdate -IsPending | Select-Object KB, Size, Title | ConvertTo-Html -Fragment | Out-File $Informe -Append
} else {
    "<p>PSWindowsUpdate no instalado</p>" | Out-File $Informe -Append
}

# Cerrar HTML
"</body></html>" | Out-File $Informe -Append

Write-Host "✅ Auditoría completada. Informe en: $Informe"

# ============================
# Envío por correo electrónico
# ============================
$MailMessage = @{
    From       = $SmtpUser
    To         = $Email
    Subject    = "Informe de Auditoría de Seguridad - $env:COMPUTERNAME"
    Body       = "Adjunto el informe de auditoría de seguridad."
    SmtpServer = $SmtpServer
    Port       = $SmtpPort
    Credential = New-Object System.Management.Automation.PSCredential($SmtpUser,(ConvertTo-SecureString $SmtpPass -AsPlainText -Force))
    UseSsl     = $true
    Attachments= $Informe
}

Send-MailMessage @MailMessage
Write-Host "📧 Informe enviado por correo a $Email"

# ============================
# Envío por Telegram
# ============================
if ($TelegramBotToken -and $TelegramChatID) {
    Invoke-RestMethod -Uri "https://api.telegram.org/bot$TelegramBotToken/sendDocument" -Method Post -Form @{
        chat_id = $TelegramChatID
        document = Get-Item $Informe
        caption = "Informe de Auditoría de Seguridad - $env:COMPUTERNAME"
    }
    Write-Host "📲 Informe enviado por Telegram"
}
