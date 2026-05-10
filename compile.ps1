# Script PowerShell pour compiler le document LaTeX
$ErrorActionPreference = "Stop"

# Utilise le répertoire du script comme répertoire de travail (portable)
$workingDir = Join-Path $PSScriptRoot "rapport"
$texFile = "Projet_de_synthese_final.tex"

# Changer de répertoire
Set-Location -LiteralPath $workingDir

# Compiler le document LaTeX (deux passes pour les références croisées)
Write-Host "Compilation LaTeX - Premiere passe..." -ForegroundColor Green
pdflatex -interaction=nonstopmode $texFile

Write-Host "Compilation LaTeX - Deuxieme passe..." -ForegroundColor Green
pdflatex -interaction=nonstopmode $texFile

Write-Host "Compilation terminee! PDF généré dans rapport/" -ForegroundColor Green
