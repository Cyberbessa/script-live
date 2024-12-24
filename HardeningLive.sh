#!/bin/bash
# Script de Hardening Versão 2.3 - cyberbessa
# LinkedIn: linkedin.com/in/cyberbessa
# YouTube: youtube.com/@cyberbessa
# Grupo no Telegram: https://t.me/+91kR4N_li005M2Nh

usuario=$1
$usuario

echo "Iniciando o hardening aprimorado para Ubuntu 24.04..."

# 1. Atualizar pacotes do sistema
echo "Atualizando pacotes do sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Adicionar um novo usuário e incluir no grupo sudo
echo "Criando um novo usuário $usuario..."
sudo adduser $usuario --gecos "Primeiro Último,NúmeroSala,TelefoneTrabalho,TelefoneCasa" --disabled-password
echo "Adicionando $usuario ao grupo sudo..."
sudo usermod -aG sudo $usuario

# 3. Desativar login root via SSH
echo "Desativando login root via SSH..."
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# 4. Desativar autenticação por senha para SSH (permitir apenas chaves SSH)
#echo "Desativando autenticação por senha para SSH..."
#sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 5. Hardening adicional do SSH
echo "Aplicando hardening adicional no SSH..."
# Desativar encaminhamento X11
sudo sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
# Desativar senhas vazias
sudo sed -i 's/#PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
# Desativar encaminhamento TCP
echo "AllowTcpForwarding no" | sudo tee -a /etc/ssh/sshd_config
# Limitar tentativas de login SSH para mitigar ataques de força bruta
echo "MaxAuthTries 3" | sudo tee -a /etc/ssh/sshd_config

# 6. Alterar a porta SSH (opcional, recomendado usar uma porta não padrão)
SSH_PORT=2222
echo "Alterando a porta SSH para $SSH_PORT..."
sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

# 7. Ativar o UFW (Uncomplicated Firewall)
echo "Ativando o UFW e configurando regras básicas de firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH na nova porta
sudo ufw allow $SSH_PORT/tcp

# Permitir HTTP, HTTPS e SSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2222/tcp

# Ativar o firewall
sudo ufw enable

# 8. Instalar e configurar Fail2Ban para proteção SSH
echo "Instalando e configurando Fail2Ban..."
sudo apt install fail2ban -y

# Configurar Fail2Ban para proteção SSH
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOL
[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
maxretry = 3
bantime = 3600
EOL

# Reiniciar Fail2Ban para aplicar a configuração
sudo systemctl restart fail2ban

# 9. Definir permissões em /etc/passwd e /etc/shadow
echo "Definindo permissões seguras em /etc/passwd e /etc/shadow..."
sudo chmod 644 /etc/passwd
sudo chmod 600 /etc/shadow

# 10. Configurar atualizações automáticas de segurança
echo "Ativando atualizações automáticas de segurança..."
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades

# 11. Configurar políticas de senha fortes
echo "Configurando políticas de senha fortes..."
sudo apt install libpam-pwquality -y
echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=3" | sudo tee -a /etc/pam.d/common-password

# 12. Recarregar SSH e UFW
echo "Recarregando serviços SSH e UFW..."
sudo systemctl reload sshd
sudo ufw reload

echo "Hardening aprimorado concluído com sucesso!"
