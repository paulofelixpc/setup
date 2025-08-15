#!/bin/bash
# OpenSousa AutoInstaller
# https://paulocesardesousa.com.br
# Versão: 1.1

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Configurações
CONFIG_DIR="/etc/opensousa"
INSTALL_DIR="/opt/opensousa"

# Verificar root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Este script deve ser executado como root!${NC}"
        echo -e "${YELLOW}Use: sudo -i${NC}"
        exit 1
    fi
}

# Mostrar cabeçalho
show_header() {
    clear
    echo -e "${ORANGE}"
    echo "   ___                 _           ___                      "
    echo "  / _ \ _ __  ___  ___| |_ ___    / _ \ _   _  ___ ___ ___  "
    echo " | | | | '_ \/ __|/ _ \ __/ _ \  | | | | | | |/ _ / __/ __| "
    echo " | |_| | |_) \__ |  __/ ||  __/  | |_| | |_| | (_) \__ \__ \\"
    echo "  \___/| .__/|___/\___|\__\___|   \__\_\\\__,_|\___/|___/___/ "
    echo "       |_|                                                  "
    echo -e "${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}          OpenSousa - Instalador Automático       ${NC}"
    echo -e "${GREEN} Telefone: (33) 99941-7323 | Email: ola@paulocesardesousa.com.br ${NC}"
    echo -e "${GREEN}          Site: https://paulocesardesousa.com.br          ${NC}"
    echo -e "${GREEN}================================================${NC}"
}

# Termos de uso
show_terms() {
    show_header
    echo -e "${YELLOW}TERMOS DE USO:${NC}"
    echo "1. Este instalador é fornecido como software livre"
    echo "2. Pode ser utilizado, modificado e distribuído livremente"
    echo "3. É obrigatória a menção à OpenSousa"
    echo "4. Deve ser mantido um link para https://opensousa.com.br"
    echo "5. Não nos responsabilizamos por danos decorrentes do uso"
    echo -e "${GREEN}================================================${NC}"
    
    read -p "Você aceita estes termos? [s/N]: " aceite
    if [[ ! "$aceite" =~ [sS] ]]; then
        echo -e "${RED}Instalação cancelada!${NC}"
        exit 1
    fi
}

# Menu principal
main_menu() {
    while true; do
        show_header
        echo -e "${CYAN}1. Instalar Dependências Básicas${NC}"
        echo -e "${CYAN}2. Instalar Docker e Docker Compose${NC}"
        echo -e "${CYAN}3. Instalar Traefik (Proxy Reverso)${NC}"
        echo -e "${CYAN}4. Instalar Portainer (Gerenciamento)${NC}"
        echo -e "${CYAN}5. Instalar n8n (Automação)${NC}"
        echo -e "${CYAN}6. Instalar Evolution API (WhatsApp)${NC}"
        echo -e "${CYAN}7. Instalar Chatwoot (Atendimento)${NC}"
        echo -e "${CYAN}8. Instalar Whaticket (WhatsApp Business)${NC}"
        echo -e "${CYAN}9. Instalar Tudo (Full Stack)${NC}"
        echo -e "${RED}0. Sair${NC}"
        echo -e "${GREEN}================================================${NC}"
        
        read -p "Selecione uma opção: " choice
        
        case $choice in
            1) install_dependencies ;;
            2) install_docker ;;
            3) install_traefik ;;
            4) install_portainer ;;
            5) install_n8n ;;
            6) install_evolution ;;
            7) install_chatwoot ;;
            8) install_whaticket ;;
            9) install_full_stack ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
        esac
    done
}

# Funções de instalação
install_dependencies() {
    show_header
    echo -e "${YELLOW}[*] Instalando dependências básicas...${NC}"
    apt update
    apt install -y curl git unzip software-properties-common apt-transport-https ca-certificates lsb-release gnupg
    echo -e "${GREEN}[✓] Dependências instaladas com sucesso!${NC}"
    sleep 2
}

install_docker() {
    show_header
    echo -e "${YELLOW}[*] Instalando Docker e Docker Compose...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}[✓] Docker e Docker Compose instalados!${NC}"
    sleep 2
}

install_traefik() {
    show_header
    echo -e "${YELLOW}[*] Instalando Traefik...${NC}"
    
    read -p "Domínio do Traefik Dashboard (ex: traefik.dominio.com): " domain
    read -p "Email para certificados SSL: " email
    
    # Criar diretórios
    mkdir -p $INSTALL_DIR/traefik
    
    # Instalar Traefik
    docker run -d \
        --name traefik \
        --restart=always \
        -p 80:80 -p 443:443 \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v $INSTALL_DIR/traefik:/etc/traefik \
        traefik:v2.10 \
        --api.dashboard=true \
        --providers.docker=true \
        --providers.docker.exposedbydefault=false \
        --entrypoints.web.address=:80 \
        --entrypoints.websecure.address=:443 \
        --certificatesresolvers.leresolver.acme.tlschallenge=true \
        --certificatesresolvers.leresolver.acme.email=$email \
        --certificatesresolvers.leresolver.acme.storage=/etc/traefik/acme.json
        
    # Configurar acesso
    echo "traefik_domain=$domain" > $CONFIG_DIR/traefik.conf
    echo "traefik_email=$email" >> $CONFIG_DIR/traefik.conf
    
    echo -e "${GREEN}[✓] Traefik instalado com sucesso!${NC}"
    echo -e "Acesse: ${CYAN}https://$domain${NC}"
    sleep 3
}

install_portainer() {
    show_header
    echo -e "${YELLOW}[*] Instalando Portainer...${NC}"
    
    read -p "Domínio para Portainer (ex: portainer.dominio.com): " domain
    
    docker volume create portainer_data
    docker run -d \
        --name portainer \
        --restart=always \
        -p 8000:8000 -p 9000:9000 \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    
    # Configurar proxy no Traefik
    docker network create sousa_net 2>/dev/null || true
    docker network connect sousa_net portainer 2>/dev/null || true
    
    docker stop portainer
    docker rm portainer
    
    docker run -d \
        --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v portainer_data:/data \
        --network sousa_net \
        -l "traefik.enable=true" \
        -l "traefik.http.routers.portainer.rule=Host(\`$domain\`)" \
        -l "traefik.http.routers.portainer.entrypoints=websecure" \
        -l "traefik.http.routers.portainer.tls.certresolver=leresolver" \
        -l "traefik.http.services.portainer.loadbalancer.server.port=9000" \
        portainer/portainer-ce:latest
        
    echo "portainer_domain=$domain" >> $CONFIG_DIR/portainer.conf
    
    echo -e "${GREEN}[✓] Portainer instalado com sucesso!${NC}"
    echo -e "Acesse: ${CYAN}https://$domain${NC}"
    sleep 3
}

install_n8n() {
    show_header
    echo -e "${YELLOW}[*] Instalando n8n...${NC}"
    
    read -p "Domínio para n8n (ex: n8n.dominio.com): " domain
    read -p "Usuário admin para n8n: " user
    read -sp "Senha admin para n8n: " password
    echo
    
    docker run -d \
        --name n8n \
        --restart=always \
        -p 5678:5678 \
        -e N8N_BASIC_AUTH_ACTIVE=true \
        -e N8N_BASIC_AUTH_USER="$user" \
        -e N8N_BASIC_AUTH_PASSWORD="$password" \
        n8nio/n8n
        
    # Configurar proxy no Traefik
    docker network connect sousa_net n8n 2>/dev/null || true
    
    docker stop n8n
    docker rm n8n
    
    docker run -d \
        --name n8n \
        --restart=always \
        -e N8N_BASIC_AUTH_ACTIVE=true \
        -e N8N_BASIC_AUTH_USER="$user" \
        -e N8N_BASIC_AUTH_PASSWORD="$password" \
        --network sousa_net \
        -l "traefik.enable=true" \
        -l "traefik.http.routers.n8n.rule=Host(\`$domain\`)" \
        -l "traefik.http.routers.n8n.entrypoints=websecure" \
        -l "traefik.http.routers.n8n.tls.certresolver=leresolver" \
        -l "traefik.http.services.n8n.loadbalancer.server.port=5678" \
        n8nio/n8n
        
    echo "n8n_domain=$domain" >> $CONFIG_DIR/n8n.conf
    echo "n8n_user=$user" >> $CONFIG_DIR/n8n.conf
    echo "n8n_password=$password" >> $CONFIG_DIR/n8n.conf
    
    echo -e "${GREEN}[✓] n8n instalado com sucesso!${NC}"
    echo -e "Acesse: ${CYAN}https://$domain${NC}"
    sleep 3
}

install_evolution() {
    show_header
    echo -e "${YELLOW}[*] Instalando Evolution API...${NC}"
    
    read -p "Domínio para Evolution API (ex: evolution.dominio.com): " domain
    
    docker run -d \
        --name evolution-api \
        --restart=always \
        -p 3000:3000 \
        -e TZ=America/Sao_Paulo \
        evolutionapi/evolution-api
        
    # Configurar proxy no Traefik
    docker network connect sousa_net evolution-api 2>/dev/null || true
    
    docker stop evolution-api
    docker rm evolution-api
    
    docker run -d \
        --name evolution-api \
        --restart=always \
        -e TZ=America/Sao_Paulo \
        --network sousa_net \
        -l "traefik.enable=true" \
        -l "traefik.http.routers.evolution-api.rule=Host(\`$domain\`)" \
        -l "traefik.http.routers.evolution-api.entrypoints=websecure" \
        -l "traefik.http.routers.evolution-api.tls.certresolver=leresolver" \
        -l "traefik.http.services.evolution-api.loadbalancer.server.port=3000" \
        evolutionapi/evolution-api
        
    echo "evolution_domain=$domain" >> $CONFIG_DIR/evolution.conf
    
    echo -e "${GREEN}[✓] Evolution API instalada com sucesso!${NC}"
    echo -e "Acesse: ${CYAN}https://$domain${NC}"
    sleep 3
}

install_chatwoot() {
    show_header
    echo -e "${YELLOW}[*] Instalando Chatwoot...${NC}"
    
    read -p "Domínio para Chatwoot (ex: chatwoot.dominio.com): " domain
    
    docker run -d \
        --name chatwoot \
        --restart=always \
        -p 3000:3000 \
        -e RAILS_ENV=production \
        chatwoot/chatwoot
        
    # Configurar proxy no Traefik
    docker network connect sousa_net chatwoot 2>/dev/null || true
    
    docker stop chatwoot
    docker rm chatwoot
    
    docker run -d \
        --name chatwoot \
        --restart=always \
        -e RAILS_ENV=production \
        --network sousa_net \
        -l "traefik.enable=true" \
        -l "traefik.http.routers.chatwoot.rule=Host(\`$domain\`)" \
        -l "traefik.http.routers.chatwoot.entrypoints=websecure" \
        -l "traefik.http.routers.chatwoot.tls.certresolver=leresolver" \
        -l "traefik.http.services.chatwoot.loadbalancer.server.port=3000" \
        chatwoot/chatwoot
        
    echo "chatwoot_domain=$domain" >> $CONFIG_DIR/chatwoot.conf
    
    echo -e "${GREEN}[✓] Chatwoot instalado com sucesso!${NC}"
    echo -e "Acesse: ${CYAN}https://$domain${NC}"
    sleep 3
}

install_whaticket() {
    show_header
    echo -e "${YELLOW}[*] Instalando Whaticket...${NC}"
    
    read -p "Domínio para Whaticket (ex: whatsapp.dominio.com): " domain
    read -p "Token para Whaticket: " token
    
    git clone https://github.com/canove/whaticket $INSTALL_DIR/whaticket
    cd $INSTALL_DIR/whaticket
    
    # Configurar .env
    cp .env.example .env
    sed -i "s|FRONT_URL=.*|FRONT_URL=https://$domain|" .env
    sed -i "s|API_URL=.*|API_URL=https://$domain/api|" .env
    sed -i "s|TOKEN=.*|TOKEN=$token|" .env
    
    docker-compose up -d --build
    
    # Configurar proxy no Traefik
    docker network create sousa_net 2>/dev/null || true
    docker network connect sousa_net whaticket 2>/dev/null || true
    
    # Adicionar labels ao container
    docker stop whaticket
    docker rm whaticket
    
    docker run -d \
        --name whaticket \
        --restart=always \
        --network sousa_net \
        -v $INSTALL_DIR/whaticket:/usr/src/app \
        -v $INSTALL_DIR/whaticket/tmp:/usr/src/app/tmp \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -l "traefik.enable=true" \
        -l "traefik.http.routers.whaticket.rule=Host(\`$domain\`)" \
        -l "traefik.http.routers.whaticket.entrypoints=websecure" \
        -l "traefik.http.routers.whaticket.tls.certresolver=leresolver" \
        -l "traefik.http.services.whaticket.loadbalancer.server.port=3000" \
        whaticket
    
    echo "whaticket_domain=$domain" >> $CONFIG_DIR/whaticket.conf
    echo "whaticket_token=$token" >> $CONFIG_DIR/whaticket.conf
    
    echo -e "${GREEN}[✓] Whaticket instalado com sucesso!${NC}"
    echo -e "Acesse: ${CYAN}https://$domain${NC}"
    echo -e "Token: ${YELLOW}$token${NC}"
    sleep 3
}

install_full_stack() {
    show_header
    echo -e "${YELLOW}[*] Instalando Full Stack...${NC}"
    
    install_dependencies
    install_docker
    install_traefik
    install_portainer
    install_n8n
    install_evolution
    install_chatwoot
    install_whaticket
    
    echo -e "${GREEN}[✓] Full Stack instalado com sucesso!${NC}"
    sleep 3
}

# Inicialização
check_root
show_terms
mkdir -p $CONFIG_DIR $INSTALL_DIR
main_menu