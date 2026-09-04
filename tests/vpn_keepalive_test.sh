#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VPN_SCRIPT="${ROOT_DIR}/vpn"

fail() {
    echo "[失败] $1" >&2
    exit 1
}

grep -q 'KEEPALIVE_INTERVAL=' "$VPN_SCRIPT" \
    || fail "脚本应定义保活检查间隔"

grep -q 'start_keepalive' "$VPN_SCRIPT" \
    || fail "节点启动成功后应启动保活进程"

grep -q 'keepalive_loop' "$VPN_SCRIPT" \
    || fail "应有独立的保活循环"

grep -q 'should_keepalive_restart_node' "$VPN_SCRIPT" \
    || fail "应把单节点健康判断封装成函数"

grep -q 'KEEPALIVE_PROBE_URLS=' "$VPN_SCRIPT" \
    || fail "脚本应定义保活联网探测地址"

grep -q 'keepalive_network_ok' "$VPN_SCRIPT" \
    || fail "应检查节点命名空间内是否真的能联网"

grep -q 'ip netns exec "\$ns" curl' "$VPN_SCRIPT" \
    || fail "联网探测必须在当前节点自己的网络命名空间内执行"

grep -q 'if ! keepalive_network_ok "\$ns"; then' "$VPN_SCRIPT" \
    || fail "tun 存在但网络不通时也必须触发重启"

grep -q 'stop_node_silent "\$node" "\$port" "keepalive"' "$VPN_SCRIPT" \
    || fail "保活重启时只能清理当前节点，且不能停止自己的保活进程"

grep -q 'start_single_node "\$node" "\$ovpn_raw" "\$port" "\$auth_file" "no"' "$VPN_SCRIPT" \
    || fail "保活拉起当前节点时不能再启动新的保活进程"

grep -q 'kill .*"\${PID_DIR}/\${N}.keepalive"' "$VPN_SCRIPT" \
    || fail "手动停止节点时必须停止对应节点的保活进程"

echo "[通过] vpn 保活结构检查通过"
