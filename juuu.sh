#!/bin/bash

# ----------------------------------------
# Jupyter Notebook 管理脚本
# 功能：安装、生成配置、设置密码、启动/停止服务、显示密码
# ----------------------------------------

# 默认参数
default_port=8888
jupyter_config_dir=".jupyter"
jupyter_config_file="jupyter_notebook_config.json"

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
  green "✅ Jupyter Notebook 安装完成"
  return_to_menu
}

# 生成配置文件
generate_config() {
  jupyter notebook --generate-config
  green "✅ 已生成配置文件于: ~/.jupyter/jupyter_notebook_config.py"
  return_to_menu
}

# 设置登录密码
set_password() {
  jupyter notebook password
  green "✅ 密码设置完成"
  return_to_menu
}

# 显示密码哈希
show_password() {
  local config_path="$HOME/$jupyter_config_dir/$jupyter_config_file"
  if [[ -f "$config_path" ]]; then
    echo "密码哈希值："
    grep "password" "$config_path" | cut -d'"' -f4
  else
    red "❌ 未找到密码配置文件"
  fi
  return_to_menu
}

# 启动 Jupyter Notebook
start_jupyter() {
  read -p "🌐 请输入端口（默认: $default_port）: " port
  port=${port:-$default_port}
  
  # 检查端口是否被占用
  if netstat -tuln | grep -q ":$port "; then
    red "❌ 端口 $port 已被占用"
    return_to_menu
    return
  fi
  
  local log_file="$HOME/jupyter.log"
  nohup jupyter notebook --ip=0.0.0.0 --port=$port > "$log_file" 2>&1 &
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
  if pgrep -f jupyter > /dev/null; then
    pkill -f jupyter
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
    pkill -f jupyter
    pip3 uninstall -y jupyter notebook
    rm -rf "$HOME/.jupyter"
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
  echo "2) 生成配置文件"
  echo "3) 设置登录密码"
  echo "4) 显示密码哈希"
  echo "5) 启动 Jupyter 服务"
  echo "6) 停止 Jupyter 服务"
  echo "7) 卸载 Jupyter"
  echo "0) 退出"
  echo "============================"
  read -p "请选择 [0-7]: " choice
  case "$choice" in
    1) install_jupyter ;;
    2) generate_config ;;
    3) set_password ;;
    4) show_password ;;
    5) start_jupyter ;;
    6) stop_jupyter ;;
    7) uninstall_jupyter ;;
    0) exit 0 ;;
    *) red "无效选项" && return_to_menu ;;
  esac
}

# 启动脚本
main_menu
