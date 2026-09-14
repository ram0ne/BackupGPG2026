#!/bin/bash
#
# ==============================================================
# Script de Backup - Compacta, Criptografa e Documenta
# Autor: Gerado com Claude
# Sistema: Kali Linux (ou qualquer distro com zip e gpg)
# ==============================================================
#
# O que este script faz:
#   1. Compacta todos os arquivos da pasta atual em um .zip
#   2. Criptografa o .zip usando GPG (criptografia simétrica, com senha)
#   3. Envia o arquivo criptografado para a nuvem (MEGA.nz)
#   4. Gera um arquivo .txt com o relatório de tudo que foi feito
#
# Requisitos: zip, gpg e megacmd instalados
#   sudo apt install zip gnupg -y
#   Instalar o MEGAcmd (não vem nos repositórios padrão do Kali):
#   wget https://mega.nz/linux/repo/Debian_12/amd64/megacmd-Debian_12_amd64.deb
#   sudo apt install ./megacmd-Debian_12_amd64.deb -y
#
# Credenciais do MEGA:
#   Defina as variáveis de ambiente MEGA_EMAIL e MEGA_SENHA antes de rodar,
#   ou o script vai perguntar interativamente (sem mostrar a senha na tela).
#   Exemplo:
#     export MEGA_EMAIL="seuemail@exemplo.com"
#     ./backup.sh
#

# --------------------------------------------------------------
# 1. Configurações iniciais
# --------------------------------------------------------------

# Pega a data e hora atual para nomear os arquivos (evita sobrescrever backups antigos)
DATA=$(date +"%Y-%m-%d_%H-%M-%S")

# Pasta atual onde o script está sendo executado
PASTA_ATUAL=$(pwd)

# Nomes dos arquivos que serão gerados
NOME_ZIP="backup_${DATA}.zip"
NOME_GPG="backup_${DATA}.zip.gpg"
NOME_LOG="backup_${DATA}_relatorio.txt"

# Pasta de destino dentro do MEGA (será criada se não existir)
PASTA_MEGA="/Backups"

echo "=================================================="
echo " Iniciando processo de backup em: $PASTA_ATUAL"
echo "=================================================="

# --------------------------------------------------------------
# 2. Verifica se os programas necessários estão instalados
# --------------------------------------------------------------

# 'command -v' verifica se o comando existe no sistema
if ! command -v zip &> /dev/null; then
    echo "[ERRO] O programa 'zip' não está instalado. Instale com: sudo apt install zip"
    exit 1
fi

if ! command -v gpg &> /dev/null; then
    echo "[ERRO] O programa 'gpg' não está instalado. Instale com: sudo apt install gnupg"
    exit 1
fi

if ! command -v mega-put &> /dev/null; then
    echo "[ERRO] O MEGAcmd não está instalado. Veja instruções no topo deste script."
    exit 1
fi

# --------------------------------------------------------------
# 3. Compactação dos arquivos da pasta atual
# --------------------------------------------------------------

echo "[1/4] Compactando arquivos em $NOME_ZIP ..."

# -r = recursivo (inclui subpastas)
# Excluímos o próprio script e arquivos de backup anteriores, para não compactar backup dentro de backup
zip -r "$NOME_ZIP" . \
    -x "$(basename "$0")" \
    -x "backup_*.zip" \
    -x "backup_*.zip.gpg" \
    -x "backup_*_relatorio.txt" \
    > /dev/null

# Verifica se o zip foi criado com sucesso
if [ ! -f "$NOME_ZIP" ]; then
    echo "[ERRO] Falha ao criar o arquivo zip."
    exit 1
fi

TAMANHO_ZIP=$(du -h "$NOME_ZIP" | cut -f1)
echo "      -> Arquivo $NOME_ZIP criado com sucesso (Tamanho: $TAMANHO_ZIP)"

# --------------------------------------------------------------
# 4. Criptografia simétrica com GPG
# --------------------------------------------------------------

echo "[2/4] Criptografando o arquivo com GPG (será pedida uma senha)..."

# --symmetric = criptografia simétrica (usa senha, não par de chaves)
# --cipher-algo AES256 = algoritmo forte de criptografia
# -o = define o nome do arquivo de saída
gpg --symmetric --cipher-algo AES256 -o "$NOME_GPG" "$NOME_ZIP"

# Verifica se a criptografia deu certo
if [ ! -f "$NOME_GPG" ]; then
    echo "[ERRO] Falha ao criptografar o arquivo."
    exit 1
fi

TAMANHO_GPG=$(du -h "$NOME_GPG" | cut -f1)
echo "      -> Arquivo $NOME_GPG criado com sucesso (Tamanho: $TAMANHO_GPG)"

# Remove o .zip sem criptografia por segurança (deixa só a versão protegida)
rm -f "$NOME_ZIP"
echo "      -> Arquivo .zip original removido (mantido apenas o .gpg criptografado)"

# --------------------------------------------------------------
# 5. Upload do arquivo criptografado para o MEGA.nz
# --------------------------------------------------------------

echo "[3/4] Enviando $NOME_GPG para o MEGA.nz ..."

# Se as variáveis de ambiente não existirem, pede os dados na hora
# -s no 'read' esconde a senha digitada no terminal
if [ -z "$MEGA_EMAIL" ]; then
    read -p "Digite o email da conta MEGA: " MEGA_EMAIL
fi

if [ -z "$MEGA_SENHA" ]; then
    read -s -p "Digite a senha da conta MEGA: " MEGA_SENHA
    echo ""
fi

# Faz login no MEGA (o megacmd mantém uma sessão em segundo plano)
mega-login "$MEGA_EMAIL" "$MEGA_SENHA" &> /dev/null

# Cria a pasta de destino no MEGA, caso ainda não exista (ignora erro se já existir)
mega-mkdir -p "$PASTA_MEGA" &> /dev/null

# Envia o arquivo criptografado para a pasta escolhida
mega-put "$NOME_GPG" "$PASTA_MEGA"

# Verifica se o arquivo realmente chegou na nuvem, listando o conteúdo da pasta
if mega-ls "$PASTA_MEGA" | grep -q "$NOME_GPG"; then
    STATUS_UPLOAD="Sucesso"
    echo "      -> Upload concluído: $PASTA_MEGA/$NOME_GPG"
else
    STATUS_UPLOAD="Falhou"
    echo "      -> [AVISO] Não foi possível confirmar o upload. Verifique manualmente com 'mega-ls $PASTA_MEGA'"
fi

# Encerra a sessão do MEGA por segurança (remove a sessão ativa do megacmd)
mega-logout &> /dev/null

# --------------------------------------------------------------
# 6. Geração do relatório em .txt
# --------------------------------------------------------------

echo "[4/4] Gerando relatório em $NOME_LOG ..."

# O bloco abaixo (heredoc) escreve várias linhas de uma vez no arquivo .txt
cat > "$NOME_LOG" << EOF
==================================================
RELATÓRIO DE BACKUP
==================================================
Data e hora do backup : $DATA
Pasta de origem        : $PASTA_ATUAL

Etapas realizadas:
1. Compactação
   - Todos os arquivos da pasta atual (e subpastas) foram
     compactados no arquivo temporário: backup_${DATA}.zip
   - O próprio script e backups antigos foram excluídos da compactação.

2. Criptografia
   - O arquivo .zip foi criptografado usando GPG com
     criptografia SIMÉTRICA (senha), algoritmo AES256.
   - Arquivo final criptografado: $NOME_GPG
   - O .zip sem criptografia foi apagado por segurança.

3. Upload para a nuvem (MEGA.nz)
   - Status do envio: $STATUS_UPLOAD
   - Pasta de destino no MEGA: $PASTA_MEGA
   - Arquivo enviado: $NOME_GPG
   - A sessão do MEGAcmd foi encerrada (logout) após o envio.

Como restaurar o backup:
   1. Baixar do MEGA (se necessário):
      mega-login <email> <senha>
      mega-get "$PASTA_MEGA/$NOME_GPG"
      mega-logout

   2. Descriptografar:
      gpg -o backup_restaurado.zip -d $NOME_GPG
      (será pedida a mesma senha usada na criptografia)

   3. Descompactar:
      unzip backup_restaurado.zip -d pasta_restaurada

==================================================
Backup concluído com sucesso!
==================================================
EOF

echo "      -> Relatório salvo em $NOME_LOG"

echo ""
echo "=================================================="
echo " Backup finalizado!"
echo " Arquivo criptografado : $NOME_GPG"
echo " Upload para o MEGA    : $STATUS_UPLOAD"
echo " Relatório             : $NOME_LOG"
echo "=================================================="
