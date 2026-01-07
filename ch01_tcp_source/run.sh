#!/usr/bin/env bash
set -euo pipefail

# =========================
# 记录初始目录（关键）
# =========================
ORIG_DIR="$(pwd)"

# =========================
# 基础配置
# =========================
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$BASE_DIR"
LOG_DIR="$WORK_DIR/data/logs"
PID_DIR="$WORK_DIR/data/pids"

mkdir -p "$LOG_DIR" "$PID_DIR"

# =========================
# 启动 docker
# =========================
# docker compose up -d

# =========================
# 进入工作目录
# =========================
cd "$WORK_DIR"

# =========================
# 启动后台进程并记录 PID
# =========================
start_process() {
    local cmd="$1"
    local log_file="$2"
    local pid_file="$3"

    echo "[INFO] Starting: $cmd"
    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
        echo "Linux detected, start with nohup"
        nohup $cmd > "$log_file" 2>&1 &
    else
        $cmd > "$log_file" 2>&1 &
    fi
    echo $! > "$pid_file"
    echo "[INFO] PID $! recorded in $pid_file"
}

# 启动各个进程
start_process "wparse daemon --stat 2 -p" "$LOG_DIR/wparse-info.log" "$PID_DIR/wparse.pid"
sleep 1
cd $ORIG_DIR/sender/fbt-send/
start_process "wpgen sample -c wpgen-tcp.toml --stat 2 -p" "$LOG_DIR/wpgen-tcp-1.log" "$PID_DIR/wpgen-tcp-1.pid"

cd $ORIG_DIR/sender/nginx-send/
start_process "wpgen sample -c wpgen-tcp.toml --stat 2 -p" "$LOG_DIR/wpgen-tcp-2.log" "$PID_DIR/wpgen-tcp-2.pid"

# start_process "wpgen sample -c wpgen-tcp-1.toml --stat 2 -p" "$LOG_DIR/wpgen-tcp-1.log" "$PID_DIR/wpgen-tcp-1.pid"
# start_process "wpgen sample -c wpgen-tcp-2.toml --stat 2 -p" "$LOG_DIR/wpgen-tcp-2.log" "$PID_DIR/wpgen-tcp-2.pid"

echo "[INFO] All processes started. PIDs stored in $PID_DIR."
# =========================
# 阻塞主进程（可选）
# =========================
# 如果希望脚本直接结束，不阻塞，可以注释掉 wait
# wait
