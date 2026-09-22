#!/bin/bash

# Apaga os scripts de configuração anteriores
rm -f arrumar_chave.sh configurar_chave_existente.sh enviar_git.sh

# Força o repositório a usar a chave correta
git config core.sshCommand "ssh -i ~/.ssh/id_evollogic -o IdentitiesOnly=yes"

# Confirma o link e faz o envio
git remote remove origin 2>/dev/null
git remote add origin git@github.com:Evollogic/drivingempire.git
git push -u origin main

echo "Push concluído com a chave id_evollogic!"
