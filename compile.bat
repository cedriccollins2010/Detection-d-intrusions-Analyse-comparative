@echo off
cd /d "%~dp0rapport"
pdflatex -interaction=nonstopmode "Projet_de_synthese_final.tex"
pdflatex -interaction=nonstopmode "Projet_de_synthese_final.tex"
echo.
echo Compilation terminee. PDF genere dans rapport/
pause
