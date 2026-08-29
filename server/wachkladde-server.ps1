<#
  Wachkladde-Server für Windows — ohne Installation.

  Nutzt den in Windows eingebauten HttpListener; es wird nichts nachinstalliert.
  Liefert Wachkladde.html aus und hält den Änderungsabgleich der Arbeitsplätze.
  Die Anmeldung übernimmt Windows (Negotiate/NTLM), die Schreibrechte kommen
  aus rechte.json.

  Start:   powershell -ExecutionPolicy Bypass -File wachkladde-server.ps1
  oder per Doppelklick auf "Wachkladde-Server starten.cmd".

  Einmalig durch die IT, damit der Port ohne Adminrechte geöffnet werden darf:
      netsh http add urlacl url=http://+:8080/ user=DOMAENE\Dienstkonto
      netsh advfirewall firewall add rule name="Wachkladde" dir=in action=allow ^
            protocol=TCP localport=8080
#>
param(
  [int]$Port = 8080,
  [string]$Wurzel = (Split-Path -Parent $PSScriptRoot),
  [string]$Daten  = (Join-Path $PSScriptRoot 'data'),
  [string]$Rechte = (Join-Path $PSScriptRoot 'rechte.json'),
  [switch]$NurLokal            # bindet nur an localhost (kein urlacl nötig, zum Ausprobieren)
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

New-Item -ItemType Directory -Force -Path $Daten | Out-Null
$OpsDatei  = Join-Path $Daten 'ops.jsonl'
$SnapDatei = Join-Path $Daten 'snapshot.json'
if (-not (Test-Path $OpsDatei)) { New-Item -ItemType File -Path $OpsDatei | Out-Null }

# ── Zustand ────────────────────────────────────────────────────────────────
$script:Log = [System.Collections.ArrayList]@()
Get-Content $OpsDatei -Encoding UTF8 | Where-Object { $_ } | ForEach-Object {
  [void]$script:Log.Add($_)          # Zeilen bleiben als Text – schnell und verlustfrei
}
$script:Ids = [System.Collections.Generic.HashSet[string]]::new()
foreach ($z in $script:Log) {
  try { [void]$script:Ids.Add((ConvertFrom-Json $z).id) } catch {}
}

function Lade-Rechte {
  if (Test-Path $Rechte) { try { return Get-Content $Rechte -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} }
  return $null
}
function Kurzname([string]$n) { if (-not $n) { return '' } ($n -split '\\')[-1].Trim() }

function Darf-Schreiben([string]$benutzer) {
  $r = Lade-Rechte
  if (-not $r)            { return $true }        # keine Datei -> offener Betrieb
  if ($r.offen -eq $true) { return $true }
  $k = (Kurzname $benutzer).ToLower()
  if (-not $k) { return $false }

  # 1. Weg: AD-Gruppe – der Planerbereich pflegt die Mitglieder
  if ($r.gruppe) {
    try {
      $wi = New-Object Security.Principal.WindowsIdentity($benutzer)
      $wp = New-Object Security.Principal.WindowsPrincipal($wi)
      if ($wp.IsInRole([string]$r.gruppe)) { return $true }
    } catch {
      Write-Host "Gruppe '$($r.gruppe)' konnte fuer '$benutzer' nicht geprueft werden: $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
  # 2. Weg: einzelne Kennungen
  if ($r.schreiben) {
    foreach ($e in $r.schreiben) { if ((Kurzname $e).ToLower() -eq $k) { return $true } }
  }
  # Weder Gruppe noch Liste hinterlegt -> niemand wird ausgesperrt
  if (-not $r.gruppe -and -not $r.schreiben) { return $true }
  return $false
}

function Kladdenname([string]$benutzer) {
  $r = Lade-Rechte
  $k = (Kurzname $benutzer).ToLower()
  if ($r -and $r.zuordnung -and $k) {
    foreach ($e in $r.zuordnung.PSObject.Properties) {
      if ($e.Name.ToLower() -eq $k) { return [string]$e.Value }
    }
  }
  return (Kurzname $benutzer)
}

function Sende($ctx, [int]$code, [string]$typ, [byte[]]$inhalt) {
  $ctx.Response.StatusCode  = $code
  $ctx.Response.ContentType = $typ
  $ctx.Response.Headers['Cache-Control'] = 'no-store'
  $ctx.Response.ContentLength64 = $inhalt.Length
  $ctx.Response.OutputStream.Write($inhalt, 0, $inhalt.Length)
  $ctx.Response.OutputStream.Close()
}
function SendeJson($ctx, [int]$code, $objekt) {
  Sende $ctx $code 'application/json; charset=utf-8' `
    ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $objekt -Depth 12 -Compress)))
}

# ── Zuhören ────────────────────────────────────────────────────────────────
$hoerer = New-Object System.Net.HttpListener
$praefix = if ($NurLokal) { "http://localhost:$Port/" } else { "http://+:$Port/" }
$hoerer.Prefixes.Add($praefix)
$hoerer.AuthenticationSchemes =
  [System.Net.AuthenticationSchemes]::IntegratedWindowsAuthentication -bor
  [System.Net.AuthenticationSchemes]::Anonymous     # Lesen auch ohne Anmeldung möglich

try { $hoerer.Start() }
catch {
  Write-Host ''
  Write-Host 'Der Port konnte nicht geoeffnet werden.' -ForegroundColor Red
  Write-Host 'Entweder laeuft schon etwas auf diesem Port, oder es fehlt die Freigabe.'
  Write-Host 'Einmalig als Administrator ausfuehren:'
  Write-Host "  netsh http add urlacl url=http://+:$Port/ user=$env:USERDOMAIN\$env:USERNAME"
  Write-Host 'Zum Ausprobieren ohne Freigabe:  -NurLokal'
  Write-Host ''
  Read-Host 'Mit Enter beenden'
  exit 1
}

$rechner = [System.Net.Dns]::GetHostName()
Write-Host ''
Write-Host '  WACHKLADDE-SERVER laeuft' -ForegroundColor Green
Write-Host "  Adresse fuer die Arbeitsplaetze:  http://$rechner`:$Port/"
Write-Host "  Daten:   $Daten"
Write-Host "  Rechte:  $(if (Test-Path $Rechte) { $Rechte } else { 'keine Datei - jeder darf schreiben' })"
Write-Host '  Fenster offen lassen. Beenden mit Strg+C.'
Write-Host ''

while ($hoerer.IsListening) {
  try { $ctx = $hoerer.GetContext() } catch { break }
  try {
    $pfad     = $ctx.Request.Url.AbsolutePath
    $benutzer = if ($ctx.User -and $ctx.User.Identity.IsAuthenticated) { $ctx.User.Identity.Name } else { '' }
    $darf     = Darf-Schreiben $benutzer

    switch -Regex ($pfad) {

      '^/api/wer$' {
        SendeJson $ctx 200 @{
          kennung       = (Kurzname $benutzer)
          name          = (Kladdenname $benutzer)
          darfSchreiben = $darf
          rolle         = $(if ($darf) { 'dgl' } else { 'leser' })
          rechteAktiv   = [bool](Lade-Rechte)
        }
        break
      }

      '^/api/ops$' {
        if ($ctx.Request.HttpMethod -eq 'GET') {
          $seit = 0
          if ($ctx.Request.QueryString['since']) { [int]::TryParse($ctx.Request.QueryString['since'], [ref]$seit) | Out-Null }
          $teil = if ($seit -lt $script:Log.Count) { $script:Log.GetRange($seit, $script:Log.Count - $seit) } else { @() }
          $ops  = @(); foreach ($z in $teil) { try { $ops += (ConvertFrom-Json $z) } catch {} }
          SendeJson $ctx 200 @{ cursor = $script:Log.Count; ops = $ops }
          break
        }
        if (-not $darf) {
          SendeJson $ctx 403 @{ error = 'keine Schreibberechtigung'; name = (Kurzname $benutzer) }
          break
        }
        $leser = New-Object IO.StreamReader($ctx.Request.InputStream, [Text.Encoding]::UTF8)
        $rumpf = $leser.ReadToEnd(); $leser.Close()
        $neu = 0
        try {
          $daten = ConvertFrom-Json $rumpf
          $zeilen = New-Object System.Collections.ArrayList
          foreach ($op in @($daten.ops)) {
            if (-not $op -or -not $op.path) { continue }
            if ($script:Ids.Contains([string]$op.id)) { continue }   # doppelt gesendet
            [void]$script:Ids.Add([string]$op.id)
            $z = ConvertTo-Json $op -Depth 12 -Compress
            [void]$script:Log.Add($z); [void]$zeilen.Add($z); $neu++
          }
          if ($neu -gt 0) { Add-Content -Path $OpsDatei -Value $zeilen -Encoding UTF8 }
          SendeJson $ctx 200 @{ ok = $true; accepted = $neu; cursor = $script:Log.Count }
        } catch { SendeJson $ctx 400 @{ error = $_.Exception.Message } }
        break
      }

      '^/api/snapshot$' {
        if (Test-Path $SnapDatei) {
          Sende $ctx 200 'application/json; charset=utf-8' ([IO.File]::ReadAllBytes($SnapDatei))
        } else { SendeJson $ctx 200 @{} }
        break
      }

      default {
        $datei = if ($pfad -eq '/') { 'Wachkladde.html' } else { $pfad.TrimStart('/') }
        $voll  = Join-Path $Wurzel $datei
        # nichts ausserhalb des Ordners ausliefern
        $wurzelVoll = [IO.Path]::GetFullPath($Wurzel)
        if (-not (Test-Path $voll -PathType Leaf) -or
            -not ([IO.Path]::GetFullPath($voll)).StartsWith($wurzelVoll)) {
          SendeJson $ctx 404 @{ error = 'nicht gefunden' }; break
        }
        $typ = switch ([IO.Path]::GetExtension($voll).ToLower()) {
          '.html' { 'text/html; charset=utf-8' }
          '.json' { 'application/json; charset=utf-8' }
          '.js'   { 'text/javascript; charset=utf-8' }
          '.css'  { 'text/css; charset=utf-8' }
          '.txt'  { 'text/plain; charset=utf-8' }
          default { 'application/octet-stream' }
        }
        Sende $ctx 200 $typ ([IO.File]::ReadAllBytes($voll))
      }
    }
  } catch {
    try { SendeJson $ctx 500 @{ error = $_.Exception.Message } } catch {}
  }
}
$hoerer.Stop()
