#!/bin/bash

# ----------------------------------------
# Jupyter Notebook 管理脚本（兼容新版）
# 功能：安装、设置密码、启动/停止服务、显示密码哈希、查看日志
# ----------------------------------------

default_port=8888
jupyter_config_dir="$HOME/.jupyter"
jupyter_config_file="$jupyter_config_dir/jupyter_notebook_config.py"
log_file="$HOME/jupyter.log"

green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red()    { echo -e "\033[31m$1\033[0m"; }

install_jupyter() {
  cd ~ || cd /tmp
  green "📦 更新包列表并安装依赖..."
  apt update
  apt install -y python3-pip curl

  green "📥 安装 Jupyter 及所需组件..."
  pip3 install --upgrade pip
  pip3 install jupyter notebook jupyterlab jupyter_server

  mkdir -p "$jupyter_config_dir"
  jupyter notebook --generate-config --allow-root

  cat > "$jupyter_config_file" << EOF
c = get_config()
c.NotebookApp.allow_root = True
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '$HOME'
c.NotebookApp.allow_remote_access = True
EOF

  green "✅ Jupyter Notebook 安装完成"
  yellow "提示：请先设置登录密码再启动服务"
  return_to_menu
}

set_password() {
  if ! command -v jupyter &> /dev/null; then
    red "❌ Jupyter 未安装，请先安装"
    return_to_menu
    return
  fi

  read -s -p "请输入新密码: " password
  echo
  read -s -p "请确认新密码: " password2
  echo

  if [[ "$password" != "$password2" ]]; then
    red "❌ 两次密码不匹配"
    return_to_menu
    return
  fi

  hash=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('$password'))" 2>/dev/null)

  if [[ $? -ne 0 || -z "$hash" ]]; then
    red "❌ jupyter_server 模块不存在，请尝试运行：pip3 install jupyter_server"
    return_to_menu
    return
  fi

  sed -i "/c.NotebookApp.password/d" "$jupyter_config_file"
  echo "c.NotebookApp.password = '$hash'" >> "$jupyter_config_file"

  green "✅ 密码设置完成"
  return_to_menu
}

show_password() {
  if [[ -f "$jupyter_config_file" ]]; then
    echo "密码哈希值："
    grep "c.NotebookApp.password" "$jupyter_config_file" | cut -d"'" -f2
  else
    red "❌ 未找到密码配置，请先设置密码"
  fi
  return_to_menu
}

start_jupyter() {
  if ! command -v jupyter &> /dev/null; then
    red "❌ Jupyter 未安装，请先安装"
    return_to_menu
    return
  fi

  if pgrep -f "jupyter-notebook" > /dev/null; then
    yellow "⚠️ Jupyter 已在运行中"
    ps aux | grep "jupyter-notebook" | grep -v grep
    return_to_menu
    return
  fi

  read -p "🌐 请输入端口（默认: $default_port）: " port
  port=${port:-$default_port}

  if netstat -tuln | grep -q ":$port "; then
    red "❌ 端口 $port 已被占用"
    return_to_menu
    return
  fi

  cd "$HOME"
  jupyter notebook --allow-root --no-browser --ip=0.0.0.0 --port=$port > "$log_file" 2>&1 &

  sleep 3
  if pgrep -f "jupyter-notebook" > /dev/null; then
    server_ip=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    token=$(grep -oP "token=\K[a-z0-9]+" "$log_file" | head -n 1)
    green "🚀 Jupyter 已启动：端口 $port"
    if [[ -n "$token" ]]; then
      yellow "访问地址: http://$server_ip:$port/?token=$token"
    else
      yellow "访问地址: http://$server_ip:$port"
    fi
    yellow "运行日志: $log_file"
  else
    red "❌ Jupyter 启动失败，错误信息："
    cat "$log_file"
  fi
  return_to_menu
}

stop_jupyter() {
  if pgrep -f "jupyter-notebook" > /dev/null; then
    pkill -f "jupyter-notebook"
    sleep 2
    if ! pgrep -f "jupyter-notebook" > /dev/null; then
      green "🛑 Jupyter 服务已停止"
    else
      red "❌ Jupyter 停止失败，尝试强制停止..."
      pkill -9 -f "jupyter-notebook"
    fi
  else
    yellow "Jupyter 未运行"
  fi
  return_to_menu
}

uninstall_jupyter() {
  read -p "⚠️ 确认卸载 Jupyter？输入 yes 确认: " confirm
  if [[ $confirm == "yes" ]]; then
    stop_jupyter
    pip3 uninstall -y jupyter notebook jupyterlab jupyter_server
    rm -rf "$jupyter_config_dir" "$log_file"
    green "🗑️ 已卸载 Jupyter 及所有配置"
  else
    yellow "取消操作"
  fi
  return_to_menu
}

show_log() {
  if [[ -f "$log_file" ]]; then
    yellow "最近20行运行日志："
    tail -n 20 "$log_file"
  else
    red "❌ 找不到日志文件"
  fi
  return_to_menu
}

return_to_menu() {
  echo
  read -p "按 Enter 返回菜单..." _unused
  main_menu
}

main_menu() {
  clear
  echo "====== Jupyter 管理脚本 ======"
  echo "1) 安装 Jupyter Notebook"
  echo "2) 设置登录密码"
  echo "3) 显示密码哈希"
  echo "4) 启动 Jupyter 服务"
  echo "5) 停止 Jupyter 服务"
  echo "6) 卸载 Jupyter"
  echo "7) 查看运行日志"
  echo "0) 退出"
  echo "============================"
  read -p "请选择 [0-7]: " choice
  case "$choice" in
    1) install_jupyter ;;
    2) set_password ;;
    3) show_password ;;
    4) start_jupyter ;;
    5) stop_jupyter ;;
    6) uninstall_jupyter ;;
    7) show_log ;;
    0) exit 0 ;;
    *) red "无效选项" && return_to_menu ;;
  esac
}

main_menu
