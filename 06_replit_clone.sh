#!/usr/bin/env bash
# ARC-AIO 06_replit_clone.sh – lightweight Replit environment
set -e
USERNAME="gp"
DOMAIN="repl.all.ddnskey.com"
WORKDIR="/srv/replit"
CODE_PORT=8080
CODE_PASS="$(openssl rand -hex 12)"

echo "==> Installing code-server + Caddy..."
apt update -y && apt install -y curl wget unzip apt-transport-https gnupg lsb-release build-essential

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

curl -fsSL https://code-server.dev/install.sh | sh
systemctl enable --now code-server@$USERNAME || true

mkdir -p /home/$USERNAME/.config/code-server
cat >/home/$USERNAME/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:${CODE_PORT}
auth: password
password: ${CODE_PASS}
cert: false
EOF
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

mkdir -p ${WORKDIR}
chown -R $USERNAME:$USERNAME ${WORKDIR}

apt install -y debian-keyring debian-archive-keyring
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | apt-key add -
echo "deb [trusted=yes] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" \
  > /etc/apt/sources.list.d/caddy-stable.list
apt update -y && apt install -y caddy

cat >/etc/caddy/Caddyfile <<EOF
${DOMAIN} {
    reverse_proxy 127.0.0.1:${CODE_PORT}
}
EOF

systemctl enable caddy
systemctl restart caddy

echo ""
echo "✅ Replit clone ready at https://${DOMAIN}"
echo "User: ${USERNAME}   Password: ${CODE_PASS}"
echo "Workspace: ${WORKDIR}"
