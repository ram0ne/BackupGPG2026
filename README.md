# 🔐 Backup Seguro com Compactação, Criptografia e Upload para o MEGA

Script em **Shell Script** para automatizar backups no Linux (testado no **Kali Linux**). Ele compacta os arquivos da pasta atual, criptografa o resultado com **GPG (AES256)**, envia o arquivo criptografado para a nuvem no **MEGA.nz** e gera um relatório detalhado em `.txt` com tudo que foi feito.

## ✨ Funcionalidades

- 📦 Compacta todos os arquivos da pasta atual (e subpastas) em um `.zip`
- 🔒 Criptografa o `.zip` com GPG usando criptografia **simétrica** (senha) e algoritmo **AES256**
- ☁️ Envia automaticamente o arquivo criptografado para uma pasta no **MEGA.nz**
- 📄 Gera um relatório `.txt` explicando cada etapa realizada e como restaurar o backup
- 🧹 Remove o `.zip` sem criptografia após o processo, mantendo apenas a versão protegida

## 📋 Pré-requisitos

Antes de rodar o script, instale as dependências:

```bash
sudo apt install zip gnupg -y
```

O **MEGAcmd** não vem nos repositórios padrão do Kali Linux, então instale manualmente:

```bash
wget https://mega.nz/linux/repo/Debian_12/amd64/megacmd-Debian_12_amd64.deb
sudo apt install ./megacmd-Debian_12_amd64.deb -y
```

## 🚀 Como usar

1. Dê permissão de execução ao script:

```bash
chmod +x backup.sh
```

2. Execute dentro da pasta que deseja fazer backup:

```bash
./backup.sh
```

3. Durante a execução, será pedida:
   - Uma senha para a criptografia GPG (guarde-a bem, ela é necessária para restaurar o backup)
   - Email e senha da sua conta MEGA (caso as variáveis de ambiente não estejam definidas)

### Modo automático (sem digitar credenciais toda vez)

Você pode definir as credenciais do MEGA como variáveis de ambiente antes de rodar o script:

```bash
export MEGA_EMAIL="seuemail@exemplo.com"
export MEGA_SENHA="suasenha"
./backup.sh
```

## 📂 Arquivos gerados

Após a execução, os seguintes arquivos são criados na pasta atual:

| Arquivo | Descrição |
|---|---|
| `backup_DATA.zip.gpg` | Arquivo compactado e criptografado, também enviado ao MEGA |
| `backup_DATA_relatorio.txt` | Relatório com todas as etapas realizadas |

> O arquivo `.zip` sem criptografia é removido automaticamente após a criptografia.

## ♻️ Como restaurar um backup

Baixar do MEGA (se necessário):

```bash
mega-login <email> <senha>
mega-get "/Backups/backup_DATA.zip.gpg"
mega-logout
```

Descriptografar:

```bash
gpg -o backup_restaurado.zip -d backup_DATA.zip.gpg
```

Descompactar:

```bash
unzip backup_restaurado.zip -d pasta_restaurada
```

## ⚙️ Configurações personalizáveis

No início do script, você pode alterar:

```bash
PASTA_MEGA="/Backups"   # Pasta de destino no MEGA
```

## ⚠️ Aviso de segurança

- Guarde bem a senha usada na criptografia GPG — sem ela, **não é possível recuperar o backup**.
- Evite deixar a senha do MEGA salva em variáveis de ambiente em máquinas compartilhadas.
- Este script foi feito para uso pessoal/educacional. Use por sua conta e risco.

## 📝 Licença

Este projeto é de uso livre para fins pessoais e educacionais.
