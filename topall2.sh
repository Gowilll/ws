#!/bin/bash

# ==============================================================================
# 增强版系统信息查看工具
# 版本: 2.0
# 作者: 系统管理员
# 描述: 全面的Linux系统信息查看和监控工具
# ==============================================================================

# 版本信息
VERSION="2.0"
SCRIPT_NAME="Enhanced System Info Tool"

# 颜色定义
declare -A COLORS=(
    ["GREEN"]='\033[0;32m'
    ["BLUE"]='\033[0;34m'
    ["YELLOW"]='\033[1;33m'
    ["RED"]='\033[0;31m'
    ["PURPLE"]='\033[0;35m'
    ["CYAN"]='\033[0;36m'
    ["WHITE"]='\033[1;37m'
    ["BOLD"]='\033[1m'
    ["NC"]='\033[0m'
)

# 配置文件
CONFIG_DIR="$HOME/.system-info-tool"
CONFIG_FILE="$CONFIG_DIR/config"
LOG_DIR="$CONFIG_DIR/logs"
REPORT_DIR="$CONFIG_DIR/reports"

# 全局变量
VERBOSE=false
AUTO_REFRESH=false
REFRESH_INTERVAL=5
EXPORT_FORMAT="txt"

# ==============================================================================
# 初始化和配置函数
# ==============================================================================

# 创建必要的目录
init_directories() {
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$REPORT_DIR" 2>/dev/null
}

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
# 系统信息工具配置文件
VERBOSE=$VERBOSE
AUTO_REFRESH=$AUTO_REFRESH
REFRESH_INTERVAL=$REFRESH_INTERVAL
EXPORT_FORMAT=$EXPORT_FORMAT
EOF
}

# 日志记录
log_action() {
    local action="$1"
    local logfile="$LOG_DIR/system-info-$(date +%Y%m).log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $action" >> "$logfile"
}

# ==============================================================================
# 工具函数
# ==============================================================================

# 清屏函数
clear_screen() {
    clear
    # 添加终端标题
    echo -ne "\033]0;$SCRIPT_NAME v$VERSION\007"
}

# 打印彩色文本
print_color() {
    local color="$1"
    local text="$2"
    echo -e "${COLORS[$color]}$text${COLORS[NC]}"
}

# 打印分隔线
print_separator() {
    local char="${1:-=}"
    local length="${2:-60}"
    printf "${COLORS[BLUE]}"
    printf "%*s\n" "$length" | tr ' ' "$char"
    printf "${COLORS[NC]}"
}

# 打印标题
print_title() {
    clear_screen
    print_separator "=" 70
    print_color "GREEN" "           $SCRIPT_NAME v$VERSION             "
    print_separator "=" 70
    echo ""
}

# 打印子标题
print_subtitle() {
    local title="$1"
    echo ""
    print_color "YELLOW" "$title"
    print_separator "-" 50
}

# 等待用户按键
wait_for_key() {
    echo ""
    print_color "CYAN" "按任意键继续..."
    read -n 1 -s
}

# 确认对话框
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    echo -n -e "${COLORS[YELLOW]}$message [y/N]: ${COLORS[NC]}"
    read choice
    [[ "$choice" =~ ^[Yy]$ ]] && return 0 || return 1
}

# 进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    
    printf "\r${COLORS[CYAN]}进度: ["
    printf "%*s" "$completed" | tr ' ' '='
    printf "%*s" $((width - completed)) | tr ' ' '-'
    printf "] %d%% (%d/%d)${COLORS[NC]}" "$percentage" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# ==============================================================================
# 系统检测函数
# ==============================================================================

# 检测操作系统类型
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 检测包管理器
detect_package_manager() {
    local os_type=$(detect_os)
    case "$os_type" in
        ubuntu|debian) echo "apt" ;;
        centos|rhel|fedora) echo "yum" ;;
        arch) echo "pacman" ;;
        *) echo "unknown" ;;
    esac
}

# 检查命令是否可用
check_command() {
    local cmd="$1"
    local required="${2:-false}"
    
    if ! command -v "$cmd" &> /dev/null; then
        if [[ "$required" == "true" ]]; then
            print_color "RED" "错误: 必需的命令 '$cmd' 不可用"
            return 1
        else
            [[ "$VERBOSE" == "true" ]] && print_color "YELLOW" "警告: 命令 '$cmd' 不可用"
            return 1
        fi
    fi
    return 0
}

# 检查依赖
check_dependencies() {
    local required_commands=("cat" "uname" "free" "df")
    local optional_commands=("lsb_release" "lscpu" "lsblk" "fdisk" "top" "ip" "ss" "lshw" "dmidecode" "sensors")
    local missing_required=()
    local missing_optional=()
    
    print_subtitle "检查系统依赖"
    
    # 检查必需命令
    for cmd in "${required_commands[@]}"; do
        if ! check_command "$cmd" "true"; then
            missing_required+=("$cmd")
        fi
    done
    
    # 检查可选命令
    for cmd in "${optional_commands[@]}"; do
        if ! check_command "$cmd"; then
            missing_optional+=("$cmd")
        fi
    done
    
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        print_color "RED" "缺少必需命令: ${missing_required[*]}"
        exit 1
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 && "$VERBOSE" == "true" ]]; then
        print_color "YELLOW" "缺少可选命令: ${missing_optional[*]}"
        print_color "CYAN" "提示: 某些功能可能受限"
    fi
    
    print_color "GREEN" "依赖检查完成"
    sleep 1
}

# ==============================================================================
# 系统信息获取函数
# ==============================================================================

# 获取系统基本信息
get_system_basic_info() {
    local info=""
    
    # 主机名
    info+="主机名: $(hostname)\n"
    
    # 用户信息
    info+="当前用户: $(whoami)\n"
    info+="用户ID: $(id -u)\n"
    info+="用户组: $(id -gn)\n"
    
    # 系统时间
    info+="系统时间: $(date)\n"
    info+="时区: $(timedatectl show --property=Timezone --value 2>/dev/null || echo 'N/A')\n"
    
    # 运行级别
    if command -v systemctl &> /dev/null; then
        info+="系统目标: $(systemctl get-default 2>/dev/null || echo 'N/A')\n"
    fi
    
    echo -e "$info"
}

# 获取硬件信息
get_hardware_info() {
    local info=""
    
    # 主板信息 (需要root权限)
    if command -v dmidecode &> /dev/null && [[ $EUID -eq 0 ]]; then
        local motherboard=$(dmidecode -s baseboard-product-name 2>/dev/null)
        local manufacturer=$(dmidecode -s baseboard-manufacturer 2>/dev/null)
        if [[ -n "$motherboard" && -n "$manufacturer" ]]; then
            info+="主板: $manufacturer $motherboard\n"
        fi
        
        local bios_version=$(dmidecode -s bios-version 2>/dev/null)
        local bios_date=$(dmidecode -s bios-release-date 2>/dev/null)
        if [[ -n "$bios_version" ]]; then
            info+="BIOS: $bios_version ($bios_date)\n"
        fi
    fi
    
    # 温度信息
    if command -v sensors &> /dev/null; then
        local temp_info=$(sensors 2>/dev/null | grep -E "Core|temp" | head -3)
        if [[ -n "$temp_info" ]]; then
            info+="温度信息:\n$temp_info\n"
        fi
    fi
    
    echo -e "$info"
}

# 获取进程信息
get_process_info() {
    local info=""
    
    # 进程统计
    local total_processes=$(ps -e | wc -l)
    local running_processes=$(ps -eo stat | grep -c "^R")
    local sleeping_processes=$(ps -eo stat | grep -c "^S")
    
    info+="总进程数: $((total_processes - 1))\n"
    info+="运行中: $running_processes\n"
    info+="休眠中: $sleeping_processes\n"
    
    # 内存使用最多的进程
    info+="内存使用最多的进程:\n"
    info+="$(ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -6)\n"
    
    # CPU使用最多的进程
    info+="CPU使用最多的进程:\n"
    info+="$(ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -6)\n"
    
    echo -e "$info"
}

# 获取服务状态
get_service_status() {
    if ! command -v systemctl &> /dev/null; then
        echo "systemctl 不可用"
        return
    fi
    
    local info=""
    local failed_services=$(systemctl --failed --no-legend | wc -l)
    local active_services=$(systemctl list-units --type=service --state=active --no-legend | wc -l)
    
    info+="服务状态概览:\n"
    info+="活动服务: $active_services\n"
    info+="失败服务: $failed_services\n"
    
    if [[ $failed_services -gt 0 ]]; then
        info+="失败的服务:\n"
        info+="$(systemctl --failed --no-legend | head -5)\n"
    fi
    
    echo -e "$info"
}

# 获取安全信息
get_security_info() {
    local info=""
    
    # 登录用户
    info+="当前登录用户:\n"
    info+="$(who)\n"
    
    # 最近登录
    if command -v last &> /dev/null; then
        info+="最近登录记录:\n"
        info+="$(last -n 5 | head -5)\n"
    fi
    
    # SSH连接
    if [[ -f /var/log/auth.log ]]; then
        local ssh_attempts=$(grep "sshd.*Failed password" /var/log/auth.log 2>/dev/null | wc -l)
        info+="今日SSH失败尝试: $ssh_attempts\n"
    fi
    
    # 防火墙状态
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status 2>/dev/null | head -n1)
        info+="UFW防火墙: $ufw_status\n"
    elif command -v firewalld &> /dev/null; then
        local firewalld_status=$(systemctl is-active firewalld 2>/dev/null)
        info+="FirewallD: $firewalld_status\n"
    fi
    
    echo -e "$info"
}

# ==============================================================================
# 主要功能函数
# ==============================================================================

# 1. 系统版本信息
show_system_version() {
    print_title
    print_subtitle "系统版本信息"
    
    # OS Release
    if [[ -f /etc/os-release ]]; then
        print_color "GREEN" "操作系统信息:"
        cat /etc/os-release
        echo ""
    fi
    
    # LSB Release
    if command -v lsb_release &> /dev/null; then
        print_color "GREEN" "LSB发行版信息:"
        lsb_release -a 2>/dev/null
        echo ""
    fi
    
    # RedHat Release
    if [[ -f /etc/redhat-release ]]; then
        print_color "GREEN" "RedHat版本:"
        cat /etc/redhat-release
        echo ""
    fi
    
    # 内核信息
    print_color "GREEN" "内核信息:"
    uname -a
    echo ""
    
    # 系统基本信息
    print_color "GREEN" "系统基本信息:"
    get_system_basic_info
    
    log_action "查看系统版本信息"
    wait_for_key
}

# 2. 增强的内核信息
show_kernel_info() {
    print_title
    print_subtitle "内核详细信息"
    
    print_color "GREEN" "内核版本: $(uname -r)"
    print_color "GREEN" "内核名称: $(uname -s)"
    print_color "GREEN" "系统架构: $(uname -m)"
    print_color "GREEN" "主机名: $(uname -n)"
    
    # 内核模块
    if [[ -f /proc/modules ]]; then
        local module_count=$(wc -l < /proc/modules)
        print_color "GREEN" "已加载模块数: $module_count"
        
        if confirm_action "是否查看加载的内核模块?"; then
            echo ""
            print_color "CYAN" "已加载的内核模块 (前20个):"
            head -20 /proc/modules | awk '{print $1, $2, $3}' | column -t
        fi
    fi
    
    # 内核参数
    if confirm_action "是否查看关键内核参数?"; then
        echo ""
        print_color "CYAN" "关键内核参数:"
        sysctl kernel.version kernel.ostype kernel.osrelease vm.swappiness 2>/dev/null
    fi
    
    log_action "查看内核信息"
    wait_for_key
}

# 3. 增强的内存信息
show_memory_info() {
    print_title
    print_subtitle "内存信息"
    
    # 基本内存信息
    print_color "GREEN" "内存使用情况:"
    free -h
    echo ""
    
    # 内存使用百分比
    local mem_info=$(free | grep '^Mem:')
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local available=$(echo $mem_info | awk '{print $7}')
    local usage_percent=$((used * 100 / total))
    
    print_color "CYAN" "内存使用率: ${usage_percent}%"
    
    # 交换分区信息
    if [[ -f /proc/swaps ]]; then
        local swap_info=$(grep -v "Filename" /proc/swaps)
        if [[ -n "$swap_info" ]]; then
            print_color "GREEN" "交换分区信息:"
            cat /proc/swaps
            echo ""
        else
            print_color "YELLOW" "未配置交换分区"
        fi
    fi
    
    # 内存占用最多的进程
    print_color "GREEN" "内存占用最多的进程:"
    ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -10
    echo ""
    
    if confirm_action "是否查看详细内存信息?"; then
        echo ""
        print_color "CYAN" "详细内存信息:"
        cat /proc/meminfo
    fi
    
    log_action "查看内存信息"
    wait_for_key
}

# 4. 增强的CPU信息
show_cpu_info() {
    print_title
    print_subtitle "CPU信息"
    
    # CPU概览
    if command -v lscpu &> /dev/null; then
        print_color "GREEN" "CPU概览:"
        lscpu
        echo ""
    fi
    
    # CPU负载
    print_color "GREEN" "CPU负载:"
    uptime
    cat /proc/loadavg
    echo ""
    
    # CPU使用率 (实时)
    if confirm_action "是否查看实时CPU使用率?"; then
        print_color "CYAN" "CPU使用率 (5秒采样):"
        top -bn2 -d1 | grep "Cpu(s)" | tail -1
        echo ""
    fi
    
    # CPU频率信息
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        print_color "GREEN" "CPU频率信息:"
        local current_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
        local max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
        local min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null)
        
        [[ -n "$current_freq" ]] && print_color "CYAN" "当前频率: $((current_freq / 1000)) MHz"
        [[ -n "$max_freq" ]] && print_color "CYAN" "最大频率: $((max_freq / 1000)) MHz"
        [[ -n "$min_freq" ]] && print_color "CYAN" "最小频率: $((min_freq / 1000)) MHz"
        echo ""
    fi
    
    if confirm_action "是否查看完整CPU详细信息?"; then
        echo ""
        print_color "CYAN" "详细CPU信息:"
        cat /proc/cpuinfo
    fi
    
    log_action "查看CPU信息"
    wait_for_key
}

# 5. 增强的磁盘信息
show_disk_info() {
    print_title
    print_subtitle "磁盘信息"
    
    # 磁盘使用情况
    print_color "GREEN" "磁盘使用情况:"
    df -h
    echo ""
    
    # 磁盘使用率警告
    local high_usage=$(df -h | awk 'NR>1 {gsub("%","",$5); if($5>80) print $1": "$5"%"}')
    if [[ -n "$high_usage" ]]; then
        print_color "RED" "警告: 以下磁盘使用率超过80%:"
        echo "$high_usage"
        echo ""
    fi
    
    # 块设备信息
    if command -v lsblk &> /dev/null; then
        print_color "GREEN" "块设备信息:"
        lsblk -f
        echo ""
    fi
    
    # I/O统计
    if [[ -f /proc/diskstats ]]; then
        print_color "GREEN" "磁盘I/O统计:"
        awk '{print $3, $4, $8}' /proc/diskstats | grep -E "sd[a-z]$|nvme" | head -5
        echo ""
    fi
    
    # 挂载点信息
    print_color "GREEN" "文件系统挂载信息:"
    mount | grep -E "^/dev" | column -t
    echo ""
    
    if confirm_action "是否查看详细磁盘分区信息? (需要sudo权限)"; then
        if command -v fdisk &> /dev/null; then
            echo ""
            print_color "CYAN" "详细分区信息:"
            sudo fdisk -l 2>/dev/null || print_color "RED" "需要root权限"
        fi
    fi
    
    log_action "查看磁盘信息"
    wait_for_key
}

# 6. 增强的系统监控
show_system_monitoring() {
    print_title
    print_subtitle "系统监控"
    
    # 系统运行时间和负载
    print_color "GREEN" "系统运行时间和负载:"
    uptime
    echo ""
    
    # 进程信息
    get_process_info
    echo ""
    
    # 服务状态
    get_service_status
    echo ""
    
    # 监控选项
    print_color "YELLOW" "选择监控工具:"
    echo "1) top - 基本系统监控"
    echo "2) htop - 增强系统监控"
    echo "3) iotop - I/O监控"
    echo "4) 实时系统状态"
    echo "5) 返回主菜单"
    echo -n "请选择 [1-5]: "
    read choice
    
    case $choice in
        1) top ;;
        2) 
            if command -v htop &> /dev/null; then
                htop
            else
                install_package "htop" && htop
            fi
            ;;
        3)
            if command -v iotop &> /dev/null; then
                sudo iotop
            else
                install_package "iotop" && sudo iotop
            fi
            ;;
        4) show_realtime_status ;;
        *) ;;
    esac
    
    log_action "使用系统监控"
}

# 实时系统状态
show_realtime_status() {
    local count=0
    print_color "CYAN" "实时系统状态 (按Ctrl+C退出)"
    echo ""
    
    while true; do
        clear_screen
        print_color "GREEN" "=== 实时系统状态 (刷新: $((++count))) ==="
        echo "时间: $(date)"
        print_separator "-" 50
        
        # CPU和内存
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d% -f1)
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local load_avg=$(uptime | awk -F'load average:' '{print $2}')
        
        print_color "YELLOW" "CPU使用率: ${cpu_usage}%"
        print_color "YELLOW" "内存使用率: ${mem_usage}%"
        print_color "YELLOW" "负载平均值: ${load_avg}"
        
        # 磁盘使用率
        echo ""
        print_color "CYAN" "磁盘使用率:"
        df -h | grep -E "^/dev" | awk '{printf "%-20s %s\n", $1, $5}'
        
        # 网络连接
        if command -v ss &> /dev/null; then
            local tcp_connections=$(ss -t | wc -l)
            print_color "PURPLE" "TCP连接数: $((tcp_connections - 1))"
        fi
        
        sleep $REFRESH_INTERVAL
    done
}

# 7. 增强的网络信息
show_network_info() {
    print_title
    print_subtitle "网络信息"
    
    # 基本网络信息
    print_color "GREEN" "主机名: $(hostname)"
    print_color "GREEN" "FQDN: $(hostname -f 2>/dev/null || echo 'N/A')"
    echo ""
    
    # 网络接口信息
    print_color "GREEN" "网络接口信息:"
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "^[0-9]+:|inet "
    elif command -v ifconfig &> /dev/null; then
        ifconfig | grep -E "^[a-z]|inet "
    fi
    echo ""
    
    # 路由信息
    print_color "GREEN" "路由表:"
    if command -v ip &> /dev/null; then
        ip route show
    else
        route -n 2>/dev/null
    fi
    echo ""
    
    # DNS信息
    if [[ -f /etc/resolv.conf ]]; then
        print_color "GREEN" "DNS服务器:"
        grep nameserver /etc/resolv.conf
        echo ""
    fi
    
    # 网络连接统计
    if command -v ss &> /dev/null; then
        print_color "GREEN" "网络连接统计:"
        ss -s
        echo ""
    fi
    
    # 端口监听
    if confirm_action "是否查看监听端口?"; then
        echo ""
        print_color "CYAN" "监听端口:"
        if command -v ss &> /dev/null; then
            ss -tuln | grep LISTEN
        elif command -v netstat &> /dev/null; then
            netstat -tuln | grep LISTEN
        fi
    fi
    
    # 网络测试
    if confirm_action "是否进行网络连通性测试?"; then
        echo ""
        print_color "CYAN" "网络连通性测试:"
        local test_hosts=("8.8.8.8" "baidu.com" "google.com")
        for host in "${test_hosts[@]}"; do
            if ping -c 1 -W 2 "$host" &> /dev/null; then
                print_color "GREEN" "✓ $host - 可达"
            else
                print_color "RED" "✗ $host - 不可达"
            fi
        done
    fi
    
    log_action "查看网络信息"
    wait_for_key
}

# 8. 系统安全检查
show_security_check() {
    print_title
    print_subtitle "系统安全检查"
    
    # 安全信息
    get_security_info
    echo ""
    
    # 系统更新检查
    print_color "GREEN" "系统更新检查:"
    local pkg_manager=$(detect_package_manager)
    case "$pkg_manager" in
        apt)
            if confirm_action "是否检查可用更新?"; then
                sudo apt list --upgradable 2>/dev/null | head -10
            fi
            ;;
        yum)
            if confirm_action "是否检查可用更新?"; then
                yum list updates 2>/dev/null | head -10
            fi
            ;;
    esac
    
    # 文件权限检查
    if confirm_action "是否检查关键文件权限?"; then
        echo ""
        print_color "CYAN" "关键文件权限:"
        local critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")
        for file in "${critical_files[@]}"; do
            if [[ -f "$file" ]]; then
                ls -l "$file"
            fi
        done
    fi
    
    log_action "进行系统安全检查"
    wait_for_key
}

# 9. 安装Neofetch
install_run_neofetch() {
    print_title
    print_subtitle "Neofetch 系统信息"
    
    if command -v neofetch &> /dev/null; then
        neofetch
    else
        if confirm_action "neofetch 未安装，是否安装?"; then
            install_package "neofetch" && neofetch
        fi
    fi
    
    log_action "使用Neofetch显示系统信息"
    wait_for_key
}

# 包安装函数
install_package() {
    local package="$1"
    local pkg_manager=$(detect_package_manager)
    
    print_color "CYAN" "正在安装 $package..."
    
    case "$pkg_manager" in
        apt)
            sudo apt update && sudo apt install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        pacman)
            sudo pacman -S "$package"
            ;;
        *)
            print_color "RED" "未知的包管理器，请手动安装 $package"
            return 1
            ;;
    esac
}

# 10. 生成系统报告
generate_system_report() {
    print_title
    print_subtitle "生成系统报告"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$REPORT_DIR/system_report_$timestamp.$EXPORT_FORMAT"

    {
        echo "===== $SCRIPT_NAME v$VERSION 系统报告 ====="
        echo "生成时间: $(date)"
        print_separator "=" 70
        echo ""
        echo "[系统版本信息]"
        get_system_basic_info
        echo ""
        echo "[硬件信息]"
        get_hardware_info
        echo ""
        echo "[内存信息]"
        free -h
        echo ""
        echo "[CPU信息]"
        if command -v lscpu &> /dev/null; then lscpu; else cat /proc/cpuinfo; fi
        echo ""
        echo "[磁盘信息]"
        df -h
        echo ""
        echo "[进程信息]"
        get_process_info
        echo ""
        echo "[网络信息]"
        if command -v ip &> /dev/null; then ip addr show; fi
        echo ""
        echo "[安全信息]"
        get_security_info
        echo ""
        print_separator "=" 70
        echo "END OF REPORT"
    } > "$report_file"

    print_color "GREEN" "报告已生成: $report_file"
    log_action "生成系统报告 $report_file"
    wait_for_key
}

# ==============================================================================
# 菜单和主流程
# ==============================================================================

main_menu() {
    while true; do
        print_title
        print_color "BOLD" "请选择要执行的操作:"
        echo "1) 系统版本信息"
        echo "2) 内核信息"
        echo "3) 内存信息"
        echo "4) CPU信息"
        echo "5) 磁盘信息"
        echo "6) 系统监控"
        echo "7) 网络信息"
        echo "8) 系统安全检查"
        echo "9) 安装/运行Neofetch"
        echo "10) 生成系统报告"
        echo "11) 配置工具"
        echo "12) 退出"
        echo -n "请输入选项 [1-12]: "
        read choice
        case "$choice" in
            1) show_system_version ;;
            2) show_kernel_info ;;
            3) show_memory_info ;;
            4) show_cpu_info ;;
            5) show_disk_info ;;
            6) show_system_monitoring ;;
            7) show_network_info ;;
            8) show_security_check ;;
            9) install_run_neofetch ;;
            10) generate_system_report ;;
            11) configure_tool ;;
            12) print_color "CYAN" "感谢使用，再见！"; exit 0 ;;
            *) print_color "RED" "无效的选项，请重新选择！"; sleep 1 ;;
        esac
    done
}

# 配置工具
configure_tool() {
    print_title
    print_subtitle "工具配置"
    echo "当前配置："
    echo "VERBOSE        : $VERBOSE"
    echo "AUTO_REFRESH   : $AUTO_REFRESH"
    echo "REFRESH_INTERVAL: $REFRESH_INTERVAL"
    echo "EXPORT_FORMAT  : $EXPORT_FORMAT"
    echo ""
    echo "是否修改配置？[y/N]: "
    read yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        echo -n "详细输出 (VERBOSE) [true/false]: "
        read v; [[ "$v" != "" ]] && VERBOSE=$v
        echo -n "自动刷新 (AUTO_REFRESH) [true/false]: "
        read ar; [[ "$ar" != "" ]] && AUTO_REFRESH=$ar
        echo -n "刷新间隔 (秒) (REFRESH_INTERVAL): "
        read ri; [[ "$ri" != "" ]] && REFRESH_INTERVAL=$ri
        echo -n "报告导出格式 (EXPORT_FORMAT) [txt/html]: "
        read ef; [[ "$ef" != "" ]] && EXPORT_FORMAT=$ef
        save_config
        print_color "GREEN" "配置已保存！"
        sleep 1
    fi
}

# 启动脚本主流程
init_directories
load_config
check_dependencies
main_menu
