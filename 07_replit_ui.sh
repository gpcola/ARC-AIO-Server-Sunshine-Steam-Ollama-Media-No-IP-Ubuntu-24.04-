#!/usr/bin/env bash
# ARC-AIO 07_replit_ui.sh – dynamic Replit dashboard with LAN toggle
set -e
USERNAME="gp"
WEBROOT="/srv/replit/ui"
API_PORT=5209

echo "==> Installing dashboard..."
apt install -y nginx jq nginx-extras lua-cjson

mkdir -p ${WEBROOT}/{static,api}
mkdir -p /opt/replit-api
chown -R $USERNAME:$USERNAME ${WEBROOT}

# --- config JSON for rename / hide ---
cat >/etc/replit-defaults.json <<'EOF'
{
  "5173": {"name": "Preview",  "visible": true},
  "8080": {"name": "Editor",   "visible": true},
  "8081": {"name": "Database", "visible": true},
  "8082": {"name": "Projects", "visible": true},
  "7860": {"name": "Ollama",   "visible": true},
  "11434":{"name": "AI API",   "visible": true},
  "47989":{"name": "Sunshine", "visible": true}
}
EOF

# --- scan ports + apply rename/hide ---
cat >/opt/replit-api/scan_ports.sh <<'EOF'
#!/usr/bin/env bash
CFG=/etc/replit-defaults.json
PORTS=(5173 8080 8081 8082 7860 11434 47989)
OUT='['
for p in "${PORTS[@]}"; do
  if ss -lnt "( sport = :$p )" | grep -q ":$p"; then
     visible=$(jq -r --arg p "$p" '.[$p].visible' $CFG 2>/dev/null)
     [ "$visible" = "true" ] || continue
     name=$(jq -r --arg p "$p" '.[$p].name' $CFG 2>/dev/null)
     OUT="$OUT{\"name\":\"${name:-Port $p}\",\"port\":$p},"
  fi
done
OUT="${OUT%,}]"
echo "$OUT"
EOF
chmod +x /opt/replit-api/scan_ports.sh

# --- API wrapper ---
cat >/opt/replit-api/replit-api.sh <<'EOF'
#!/usr/bin/env bash
CONFIG=/etc/replit-flags.json
[ ! -f "$CONFIG" ] && echo '{"autostart":false,"toolbox":true,"autonomy":1,"lan_auth":true}' >"$CONFIG"

case "$1" in
  get) cat "$CONFIG" ;;
  toggle-autostart) jq '.autostart = (.autostart|not)' "$CONFIG" | tee "$CONFIG" >/dev/null ;;
  toggle-toolbox)   jq '.toolbox = (.toolbox|not)' "$CONFIG" | tee "$CONFIG" >/dev/null ;;
  set-autonomy)     jq --arg v "$2" '.autonomy = ($v|tonumber)' "$CONFIG" | tee "$CONFIG" >/dev/null ;;
  toggle-lan)       jq '.lan_auth = (.lan_auth|not)' "$CONFIG" | tee "$CONFIG" >/dev/null; systemctl reload nginx ;;
  ports) /opt/replit-api/scan_ports.sh ;;
esac
EOF
chmod +x /opt/replit-api/replit-api.sh

# --- trusted subnet auth include ---
cat >/etc/nginx/conf.d/trusted_auth.conf <<'EOF'
geo $trusted_lan {
    default 0;
    192.168.1.0/24 1;
    10.29.1.0/24   1;
}

map $trusted_lan $auth_bypass {
    1 "";
    0 "Basic realm=\"ARC-AIO\"";
}

lua_shared_dict replit_flags 1m;
init_by_lua_block {
  local cjson=require("cjson.safe")
  local f=io.open("/etc/replit-flags.json","r")
  local data=f and cjson.decode(f:read("*a")) or {}
  ngx.shared.replit_flags:set("lan_auth",data.lan_auth and "1" or "0")
}
access_by_lua_block {
  local val=ngx.shared.replit_flags:get("lan_auth")
  if val=="1" and ngx.var.trusted_lan=="1" then
    ngx.header["Auth-Bypass"]="LAN"
  end
}
EOF

# --- HTML dashboard ---
cat >${WEBROOT}/static/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="UTF-8"><title>ARC-AIO Replit</title>
<style>
body{margin:0;font-family:sans-serif;display:flex;height:100vh}
#sidebar{width:230px;background:#1e1e1e;color:#fff;padding:1rem;overflow-y:auto}
#content{flex:1;display:flex;flex-direction:column}
iframe{flex:1;border:none}
button{width:100%;margin:.3rem 0;padding:.5rem;background:#333;color:#fff;border:0;cursor:pointer;border-radius:4px}
h3{margin-top:0}
</style></head>
<body>
<div id="sidebar">
<h3>Toolbox</h3>
<button onclick="api('toggle-autostart')">Toggle Autostart</button>
<button onclick="api('toggle-toolbox')">Toggle Toolbox</button>
<button onclick="api('set-autonomy',prompt('0–3 autonomy level','1'))">Set Autonomy</button>
<button onclick="api('toggle-lan')">Toggle Trusted LAN Access</button>
<hr>
<h3>GPU Services</h3>
<button onclick="api('gpu','start')">Start Ollama + Sunshine</button>
<button onclick="api('gpu','stop')">Stop Ollama + Sunshine</button>
<button onclick="api('gpu','toggle')">Toggle Auto-Start at Boot</button
<hr><h3>Services</h3><div id="services"></div>
</div>
<div id="content"><iframe id="frame"></iframe></div>
<script>
async function api(a,b){await fetch(`/api/${a}${b?'/'+b:''}`)}
async function refresh(){
 const r=await fetch('/api/ports');const j=await r.json();
 const div=document.getElementById('services');div.innerHTML='';
 j.forEach(s=>{
  const b=document.createElement('button');
  b.textContent=s.name;
  b.onclick=()=>document.getElementById('frame').src=`http://localhost:${s.port}`;
  div.appendChild(b);
 });
 if(!j.length){const p=document.createElement('p');p.textContent='No local services';div.appendChild(p);}
}
setInterval(refresh,10000);refresh();
</script></body></html>
EOF

# --- nginx site ---
cat >/etc/nginx/sites-available/replit.conf <<EOF
server {
    listen 80;
    server_name repl.all.ddnskey.com;
    include /etc/nginx/conf.d/trusted_auth.conf;
    root ${WEBROOT}/static;
    index index.html;

    location / {
        satisfy any;
        allow 192.168.1.0/24;
        allow 10.29.1.0/24;
        deny all;
        try_files \$uri \$uri/ =404;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:${API_PORT}/;
    }

    location /code/ {
        auth_basic \$auth_bypass;
        proxy_pass http://127.0.0.1:8080/;
    }
}
EOF

ln -sf /etc/nginx/sites-available/replit.conf /etc/nginx/sites-enabled/replit.conf
systemctl restart nginx

echo "✅ Dashboard active →  http://repl.all.ddnskey.com"
