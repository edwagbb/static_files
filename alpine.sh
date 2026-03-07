#!/bin/sh
# frpc http_proxy 极简启动脚本 (Alpine 兼容)

SERVER_IP="${1:-}"
SERVER_PORT="${2:-}"
AUTH_TOKEN="${3:-}"
REMOTE_PORT="${4:-10896}"
PROXY_USER="${5:-admin}"
PROXY_PASS="${6:-frp123456}"
FRP_VERSION="0.67.0"
TMP_DIR="/tmp/frp-$$"

if [ -z "$SERVER_IP" ] || [ -z "$SERVER_PORT" ] || [ -z "$AUTH_TOKEN" ]; then
    echo "用法: $0 <服务器IP> <服务器端口> <token> [远程端口] [用户名] [密码]"
    echo "  用户名默认: admin"
    echo "  密码默认: frp123456"
    exit 1
fi

mkdir -p "$TMP_DIR"

echo "[*] 下载 frpc..."
wget -q "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz" -O "${TMP_DIR}/frp.tar.gz"
tar -xzf "${TMP_DIR}/frp.tar.gz" -C "$TMP_DIR"
cp "${TMP_DIR}/frp_${FRP_VERSION}_linux_amd64/frpc" "${TMP_DIR}/frpc"
chmod +x "${TMP_DIR}/frpc"

cat > "${TMP_DIR}/frpc.toml" << EOF
serverAddr = "${SERVER_IP}"
serverPort = ${SERVER_PORT}
auth.token = "${AUTH_TOKEN}"

[[proxies]]
name = "http_proxy-${REMOTE_PORT}"
type = "tcp"
remotePort = ${REMOTE_PORT}

[proxies.plugin]
type = "http_proxy"
httpUser = "${PROXY_USER}"
httpPassword = "${PROXY_PASS}"
EOF

echo "[*] 启动 frpc..."
"${TMP_DIR}/frpc" -c "${TMP_DIR}/frpc.toml" &

sleep 2
echo ""
echo "========================================="
echo "  HTTP 代理已启动"
echo "========================================="
echo "  服务器: ${SERVER_IP}:${REMOTE_PORT}"
echo "  用户名: ${PROXY_USER}"
echo "  密码: ${PROXY_PASS}"
echo "========================================="
echo ""
echo "  测试: curl --proxy http://${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${REMOTE_PORT} https://api.ip.sb/ip"
echo "========================================="

sleep 3600
