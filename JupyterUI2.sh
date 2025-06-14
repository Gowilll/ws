#!/bin/bash
# ----------------------------------------
# Jupyter Notebook 管理脚本 (增强版)
# 功能：安装、创建用户、生成配置、设置密码、启动/停止 服务、删除所有
# ----------------------------------------

# 默认参数
default_user="jpy"
default_port=60001
config_dir="/etc/jupyter-manager"
pid_file="$config_dir/jupyter.pid"

# 颜色输出
green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red()    { echo -e "\033[31m$1\033[0m"; }
blue()   { echo -e "\033[34m$1\033[0m"; }

# 创建配置目录
init_config_dir() {
  [[ ! -d "$config_dir" ]] && mkdir -p "$config_dir"
}

# 检查依赖
check_dependencies() {
  local missing_deps=()
  for cmd in python3 pip3 curl; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    red "❌ 缺少依赖: ${missing_deps[*]}"
    return 1
  fi
  return 0
}

# 安装 Jupyter Notebook，并防止 getcwd() 错误
install_jupyter() {
  cd ~ || cd /root || cd /tmp
  
  green "📦 更新包列表并安装依赖..."
  if ! apt update; then
    red "❌ 包列表更新失败"
    return_to_menu
    return
  fi
  
  if ! apt install -y python3-pip curl; then
    red "❌ 依赖安装失败"
    return_to_menu
    return
  fi
  
  green "📥 升级 pip 并安装 Jupyter..."
  if ! pip3 install --upgrade pip; then
    red "❌ pip 升级失败"
    return_to_menu
    return
  fi
  
  if ! pip3 install jupyter notebook; then
    red "❌ Jupyter 安装失败"
    return_to_menu
    return
  fi
  
  green "✅ Jupyter Notebook 安装完成"
  return_to_menu
}

# 验证用户名
validate_username() {
  local username="$1"
  if [[ ! "$username" =~ ^[a-z][-a-z0-9]*$ ]]; then
    red "❌ 用户名格式无效。只允许小写字母、数字和连字符，且必须以字母开头"
    return 1
  fi
  return 0
}

# 确保用户主目录存在
ensure_home() {
  local username="$1"
  local home_dir="/home/$username"
  if [[ ! -d "$home_dir" ]]; then
    mkdir -p "$home_dir"
    chown "$username:$username" "$home_dir"
    chmod 755 "$home_dir"
  fi
}

# 创建运行用户
create_user() {
  read -p "👤 请输入运行用户（默认: $default_user）: " username
  username=${username:-$default_user}
  
  if ! validate_username "$username"; then
    return_to_menu
    return
  fi
  
  if id "$username" &>/dev/null; then
    yellow "⚠️ 用户 $username 已存在，跳过创建"
  else
    if adduser --gecos "" --disabled-password "$username"; then
      green "✅ 用户 $username 创建成功"
    else
      red "❌ 用户创建失败"
    fi
  fi
  return_to_menu
}

# 生成配置文件
generate_config() {
  read -p "👤 请输入运行用户（默认: $default_user）: " username
  username=${username:-$default_user}
  
  if ! id "$username" &>/dev/null; then
    red "❌ 用户 $username 不存在，请先创建用户"
    return_to_menu
    return
  fi
  
  ensure_home "$username"
  
  if runuser -l "$username" -c "jupyter notebook --generate-config"; then
    green "✅ 已为 $username 生成配置文件于: /home/$username/.jupyter/jupyter_notebook_config.py"
  else
    red "❌ 配置文件生成失败"
  fi
  return_to_menu
}

# 设置登录密码
set_password() {
  read -p "👤 请输入运行用户（默认: $default_user）: " username
  username=${username:-$default_user}
  
  if ! id "$username" &>/dev/null; then
    red "❌ 用户 $username 不存在，请先创建用户"
    return_to_menu
    return
  fi
  
  ensure_home "$username"
  
  if runuser -l "$username" -c "jupyter notebook password"; then
    green "✅ 密码设置完成"
  else
    red "❌ 密码设置失败"
  fi
  return_to_menu
}

# 检查端口是否被占用
check_port() {
  local port="$1"
  if netstat -tuln 2>/dev/null | grep -q ":$port "; then
    return 1
  fi
  return 0
}

# 获取 Jupyter 进程 PID
get_jupyter_pid() {
  local username="$1"
  local port="$2"
  pgrep -f "jupyter.*--port=$port" 2>/dev/null | head -1
}

# 启动 Jupyter Notebook
start_jupyter() {
  read -p "👤 请输入运行用户（默认: $default_user）: " username
  username=${username:-$default_user}
  
  if ! id "$username" &>/dev/null; then
    red "❌ 用户 $username 不存在，请先创建用户"
    return_to_menu
    return
  fi
  
  ensure_home "$username"
  
  read -p "🌐 请输入端口（默认: $default_port）: " port
  port=${port:-$default_port}
  
  # 验证端口范围
  if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1024 ]] || [[ "$port" -gt 65535 ]]; then
    red "❌ 端口必须是 1024-65535 之间的数字"
    return_to_menu
    return
  fi
  
  # 检查端口是否被占用
  if ! check_port "$port"; then
    red "❌ 端口 $port 已被占用"
    return_to_menu
    return
  fi
  
  # 检查是否已有该用户的 Jupyter 进程运行
  if existing_pid=$(get_jupyter_pid "$username" "$port"); then
    yellow "⚠️ 端口 $port 上已有 Jupyter 进程运行 (PID: $existing_pid)"
    return_to_menu
    return
  fi
  
  local home_dir="/home/$username"
  local log_file="$home_dir/jupyter.log"
  
  # 启动 Jupyter
  runuser -l "$username" -c "cd ~ && nohup jupyter notebook --allow-root --ip=0.0.0.0 --port=$port --no-browser > $log_file 2>&1 &"
  
  # 等待启动并获取 PID
  sleep 3
  local jupyter_pid=$(get_jupyter_pid "$username" "$port")
  
  if [[ -n "$jupyter_pid" ]]; then
    # 保存进程信息
    echo "$username:$port:$jupyter_pid" >> "$config_dir/running_instances"
    
    # 获取服务器 IP
    server_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "localhost")
    
    green "🚀 Jupyter 已启动成功！"
    blue "📋 运行信息："
    echo "   用户: $username"
    echo "   端口: $port"
    echo "   PID:  $jupyter_pid"
    echo "   日志: $log_file"
    yellow "🌐 访问地址: http://$server_ip:$port"
    echo "   (如果是远程服务器，请确保防火墙允许端口 $port)"
  else
    red "❌ Jupyter 启动失败，请检查日志: $log_file"
  fi
  
  return_to_menu
}

# 显示运行状态
show_status() {
  blue "📊 Jupyter 运行状态："
  
  if [[ ! -f "$config_dir/running_instances" ]]; then
    yellow "   无运行中的实例"
    return_to_menu
    return
  fi
  
  local found_running=false
  while IFS=':' read -r user port pid; do
    if kill -0 "$pid" 2>/dev/null; then
      echo "   ✅ 用户: $user, 端口: $port, PID: $pid"
      found_running=true
    fi
  done < "$config_dir/running_instances"
  
  if [[ "$found_running" == false ]]; then
    yellow "   无运行中的实例"
    # 清理失效记录
    > "$config_dir/running_instances"
  fi
  
  return_to_menu
}

# 停止 Jupyter Notebook
stop_jupyter() {
  if [[ ! -f "$config_dir/running_instances" ]]; then
    yellow "🔍 未找到运行中的 Jupyter 实例"
    return_to_menu
    return
  fi
  
  echo "🔍 当前运行的 Jupyter 实例："
  local instances=()
  local index=1
  
  while IFS=':' read -r user port pid; do
    if kill -0 "$pid" 2>/dev/null; then
      echo "   $index) 用户: $user, 端口: $port, PID: $pid"
      instances+=("$user:$port:$pid")
      ((index++))
    fi
  done < "$config_dir/running_instances"
  
  if [[ ${#instances[@]} -eq 0 ]]; then
    yellow "   无运行中的实例"
    > "$config_dir/running_instances"
    return_to_menu
    return
  fi
  
  echo "   0) 停止所有实例"
  read -p "请选择要停止的实例 [0-$((${#instances[@]}))]: " choice
  
  if [[ "$choice" == "0" ]]; then
    # 停止所有实例
    for instance in "${instances[@]}"; do
      IFS=':' read -r user port pid <<< "$instance"
      if kill "$pid" 2>/dev/null; then
        green "✅ 已停止 $user 的实例 (端口: $port, PID: $pid)"
      else
        yellow "⚠️ 无法停止 PID $pid"
      fi
    done
    > "$config_dir/running_instances"
    green "🛑 所有 Jupyter 实例已停止"
  elif [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [[ "$choice" -le ${#instances[@]} ]]; then
    # 停止指定实例
    local selected_instance="${instances[$((choice-1))]}"
    IFS=':' read -r user port pid <<< "$selected_instance"
    
    if kill "$pid" 2>/dev/null; then
      green "✅ 已停止 $user 的实例 (端口: $port, PID: $pid)"
      # 从记录中移除该实例
      grep -v "^$user:$port:$pid$" "$config_dir/running_instances" > "$config_dir/running_instances.tmp" 2>/dev/null || true
      mv "$config_dir/running_instances.tmp" "$config_dir/running_instances" 2>/dev/null || true
    else
      red "❌ 无法停止 PID $pid"
    fi
  else
    yellow "⚠️ 无效选择"
  fi
  
  return_to_menu
}

# 删除所有：Jupyter、用户及配置（危险操作）
delete_all() {
  red "⚠️⚠️⚠️ 危险操作警告 ⚠️⚠️⚠️"
  echo "此操作将："
  echo "• 停止所有 Jupyter 进程"
  echo "• 删除用户 $default_user 及其主目录"
  echo "• 卸载 Jupyter 软件包"
  echo "• 删除所有配置文件"
  echo
  read -p "确认删除所有配置和用户？此操作不可恢复！输入 'DELETE_ALL' 确认: " confirm
  
  if [[ $confirm == "DELETE_ALL" ]]; then
    # 停止所有 Jupyter 进程
    pkill -f jupyter 2>/dev/null || true
    
    # 删除用户
    if id "$default_user" &>/dev/null; then
      deluser --remove-home "$default_user" 2>/dev/null && \
        green "✅ 已删除用户 $default_user" || \
        yellow "⚠️ 删除用户时出现问题"
    fi
    
    # 卸载 Jupyter
    pip3 uninstall -y jupyter notebook 2>/dev/null && \
      green "✅ 已卸载 Jupyter" || \
      yellow "⚠️ 卸载 Jupyter 时出现问题"
    
    # 清理配置目录
    rm -rf "$config_dir" 2>/dev/null && \
      green "✅ 已清理配置目录" || \
      yellow "⚠️ 清理配置目录时出现问题"
    
    green "🗑️ 删除操作完成"
  else
    yellow "❌ 取消删除操作"
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
  echo "========== Jupyter 管理脚本 (增强版) =========="
  echo "1) 安装 Jupyter Notebook"
  echo "2) 创建运行用户"
  echo "3) 生成配置文件"
  echo "4) 设置登录密码"
  echo "5) 启动 Jupyter 服务"
  echo "6) 显示运行状态"
  echo "7) 停止 Jupyter 服务"
  echo "8) 删除所有配置与用户"
  echo "0) 退出"
  echo "============================================="
  read -p "请选择 [0-8]: " choice
  
  case "$choice" in
    1) install_jupyter ;;
    2) create_user ;;
    3) generate_config ;;
    4) set_password ;;
    5) start_jupyter ;;
    6) show_status ;;
    7) stop_jupyter ;;
    8) delete_all ;;
    0) green "👋 再见！"; exit 0 ;;
    *) red "❌ 无效选项，请重新选择" && sleep 1 && main_menu ;;
  esac
}

# 确保以 root 运行
if [[ $EUID -ne 0 ]]; then
  red "❌ 请使用 root 权限运行此脚本"
  exit 1
fi

# 初始化
init_config_dir

# 启动脚本
main_menu
