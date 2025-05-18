#!/bin/bash

# ----------------------------------------
# Jupyter Notebook 管理脚本
# 功能：安装、设置密码、启动/停止服务、显示密码
# ----------------------------------------

# 默认参数
default_port=8888
jupyter_config_dir="$HOME/.jupyter"
jupyter_config_file="$jupyter_config_dir/jupyter_notebook_config.py"
jupyter_password_file="$jupyter_config_dir/jupyter_server_config.json"

# 颜色输出
green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red()    { echo -e "\033[31m$1\033[0m"; }

# 安装 Jupyter Notebook
install_jupyter() {
  cd ~ || cd /tmp
  green "📦 更新包列表并安装依赖..."
  apt update
  apt install -y python3-pip curl
  green "📥 升级 pip 并安装 Jupyter..."
  pip3 install --upgrade pip
  pip3 install jupyter notebook

  # 自动生成配置文件
  mkdir -p "$jupyter_config_dir"
  if [[ ! -f "$jupyter_config_file" ]]; then
    jupyter notebook --generate-config
    
    # 添加基础配置
    cat >> "$jupyter_config_file" << EOF

# 设置允许远程访问
c.NotebookApp.allow_remote_access = True
c.NotebookApp.ip = '0.0.0.0'
# 禁用自动打开浏览器
c.NotebookApp.open_browser = False
# 设置工作目录
c.NotebookApp.notebook_dir = '$HOME'
EOF
  fi

  green "✅ Jupyter Notebook 安装完成"
  yellow "提示：请先设置登录密码再启动服务"
  return_to_menu
}

# 设置登录密码
set_password() {
  jupyter server password
  if [[ $? -eq 0 ]]; then
    green "✅ 密码设置完成"
  else
    red "❌ 密码设置失败"
  fi
  return_to_menu
}

# 显示密码哈希
show_password() {
  if [[ -f "$jupyter_password_file" ]]; then
    echo "密码哈希值："
    grep "password" "$jupyter_password_file" | cut -d'"' -f4
  else
    red "❌ 未找到密码文件，请先设置密码"
  fi
  return_to_menu
}

# 启动 Jupyter Notebook
start_jupyter() {
  if [[ ! -f "$jupyter_password_file" ]]; then
    red "❌ 请先设置登录密码"
    return_to_menu
    return
  fi

  read -p "🌐 请输入端口（默认: $default_port）: " port
  port=${port:-$default_port}
  
  # 检查端口是否被占用
  if netstat -tuln | grep -q ":$port "; then
    red "❌ 端口 $port 已被占用"
    return_to_menu
    return
  fi
  
  local log_file="$HOME/jupyter.log"
  nohup jupyter notebook --port=$port > "$log_file" 2>&1 &
  sleep 2
  
  if ! netstat -tuln | grep -q ":$port "; then
    red "❌ Jupyter 启动失败，请检查日志: $log_file"
  else
    server_ip=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    green "🚀 Jupyter 已启动：端口 $port"
    yellow "访问地址: http://$server_ip:$port"
  fi
  return_to_menu
}

# 停止 Jupyter Notebook
stop_jupyter() {
  if pgrep -f "jupyter-notebook" > /dev/null; then
    pkill -f "jupyter-notebook"
    green "🛑 Jupyter 服务已停止"
  else
    yellow "Jupyter 未运行"
  fi
  return_to_menu
}

# 卸载 Jupyter
uninstall_jupyter() {
  read -p "⚠️ 确认卸载 Jupyter？此操作将删除所有配置！输入 yes 确认: " confirm
  if [[ $confirm == "yes" ]]; then
    stop_jupyter
    pip3 uninstall -y jupyter notebook
    rm -rf "$jupyter_config_dir"
    green "🗑️ 已卸载 Jupyter 及所有配置"
  else
    yellow "取消操作"
  fi
  return_to_menu
}

# 返回主菜单
return_to_menu() {
  echo
  read -p "按 Enter 返回菜单..." _unused
  main_menu
}

# 主菜单
main_menu() {
  clear
  echo "====== Jupyter 管理脚本 ======"
  echo "1) 安装 Jupyter Notebook"
  echo "2) 设置登录密码"
  echo "3) 显示密码哈希"
  echo "4) 启动 Jupyter 服务"
  echo "5) 停止 Jupyter 服务"
  echo "6) 卸载 Jupyter"
  echo "0) 退出"
  echo "============================"
  read -p "请选择 [0-6]: " choice
  case "$choice" in
    1) install_jupyter ;;
    2) set_password ;;
    3) show_password ;;
    4) start_jupyter ;;
    5) stop_jupyter ;;
    6) uninstall_jupyter ;;
    0) exit 0 ;;
    *) red "无效选项" && return_to_menu ;;
  esac
}

# 启动脚本
main_menu
