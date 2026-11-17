# UNO-TODO.ps1 - Instala el conector MCP "simon-mcp" (PowerShell como Administrador)
$ErrorActionPreference='Stop'
$B='C:\mcp-server-simon'; $D='C:\ProgramData\mcp-simon'
New-Item -ItemType Directory -Force -Path $B,"$B\logs",$D|Out-Null
if(-not(Get-Command node -ErrorAction SilentlyContinue)){
  winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
  $env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+$env:Path
}
Set-Location $B
if(-not(Test-Path "$B\package.json")){ Invoke-WebRequest 'https://raw.githubusercontent.com/black-hak/mcp-simon/main/package.json' -OutFile "$B\package.json" }
Invoke-WebRequest 'https://raw.githubusercontent.com/black-hak/mcp-simon/main/server.js.gz.b64' -OutFile "$B\s.b64"
$b64=(Get-Content "$B\s.b64" -Raw) -replace '[^A-Za-z0-9+/=]',''
[IO.File]::WriteAllBytes("$B\s.gz",[Convert]::FromBase64String($b64))
$in=[IO.File]::OpenRead("$B\s.gz"); $out=[IO.File]::Create("$B\server.js"); $gz=New-Object IO.Compression.GZipStream($in,[IO.Compression.CompressionMode]::Decompress); $gz.CopyTo($out); $gz.Close(); $out.Close(); $in.Close()
Remove-Item "$B\s.b64","$B\s.gz" -Force
Write-Host ('server.js: ' + (Get-Item "$B\server.js").Length + ' bytes')
npm install --no-audit --no-fund
$b=New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); $T=($b|%{$_.ToString('x2')}) -join ''
$H=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($T)))).Replace('-','').ToLower()
[IO.File]::WriteAllText("$D\secrets.json",'{"tokens":{"principal":"'+$H+'"}}',(New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host '==================================================' -ForegroundColor Yellow
Write-Host "  TOKEN: $T" -ForegroundColor Green
Write-Host '  GUARDALO. No se vuelve a mostrar.' -ForegroundColor Yellow
Write-Host '  URL: https://simon-mcp.aprwebs.com/mcp' -ForegroundColor Green
Write-Host '==================================================' -ForegroundColor Yellow
$T | Set-Content "$env:USERPROFILE\Desktop\simon-token.txt" -NoNewline
$N='C:\ProgramData\mi-pc-mcp\nssm\nssm-2.24\win64\nssm.exe'
if(Test-Path $N){
  & $N install MCP-Server-Simon (Get-Command node).Source "$B\server.js"
  & $N set MCP-Server-Simon AppDirectory $B
  & $N set MCP-Server-Simon AppStdout "$B\logs\service.out.log"
  & $N set MCP-Server-Simon AppStderr "$B\logs\service.err.log"
  & $N set MCP-Server-Simon AppRotateFiles 1
  & $N set MCP-Server-Simon AppRotateBytes 20971520
  & $N set MCP-Server-Simon Start SERVICE_AUTO_START
  & $N set MCP-Server-Simon ObjectName LocalSystem
  sc.exe failure MCP-Server-Simon reset= 86400 actions= restart/20000/restart/20000/restart/20000|Out-Null
  Start-Service MCP-Server-Simon; Start-Sleep 7
  Get-Service MCP-Server-Simon|fl Name,Status,StartType
} else {
  $p=Start-Process node -ArgumentList 'server.js' -WorkingDirectory $B -PassThru -WindowStyle Hidden; Start-Sleep 8
}
(Invoke-WebRequest 'http://127.0.0.1:3200/health' -UseBasicParsing).Content
