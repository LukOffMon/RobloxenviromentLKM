# Verificacion completa antes de hacer commit: formato, lint, tipos estrictos y build.
# Uso:  ./scripts/check.ps1        (anade -Fix para reformatear con StyLua)
param([switch]$Fix)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"

$defs = ".luau-defs/globalTypes.d.luau"
if (-not (Test-Path $defs)) {
	New-Item -ItemType Directory -Force (Split-Path $defs) | Out-Null
	Invoke-WebRequest "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau" -OutFile $defs
}

$failed = @()
function Step($name, [scriptblock]$cmd) {
	Write-Host "`n== $name" -ForegroundColor Cyan
	& $cmd
	if ($LASTEXITCODE -ne 0) { $script:failed += $name }
}

if ($Fix) { Step "StyLua (fix)" { stylua src tests } } else { Step "StyLua" { stylua --check src tests } }
Step "Selene" { selene src }
Step "Sourcemap" { rojo sourcemap default.project.json -o sourcemap.json }
Step "Luau (strict)" { luau-lsp analyze --sourcemap=sourcemap.json --definitions=$defs --platform=roblox --settings=.vscode/settings.json src }
Step "Tests (Lune)" { lune run tests/run.luau }
Step "Rojo build" { rojo build default.project.json -o "$env:TEMP\RobloxenviromentLKM.rbxl" }

if ($failed.Count) { Write-Host "`nFALLO: $($failed -join ', ')" -ForegroundColor Red; exit 1 }
Write-Host "`nTodo OK" -ForegroundColor Green
