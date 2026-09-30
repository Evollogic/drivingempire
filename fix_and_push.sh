#!/bin/bash
echo "[+] Preparando os ficheiros para o GitHub..."
git add Hub.lua Auto/autohop.lua
git commit -m "Fix: Arrasto definitivo do Hub e design futurista com glow"
git push origin main
echo "[+] Código enviado com sucesso!"
