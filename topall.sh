#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 恢复默认颜色

# 清屏函数
clear_screen() {
    clear
}

# 打印分隔线
print_separator() {
    echo -e "${BLUE}------------------------------------------------${NC}"
}

# 打印标题
print_title() {
    clear_screen
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}           系统信息查看工具             ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
}

# 等待用户按键继续
wait_for_key() {
    echo ""
    read -p "按任意键返回主菜单..." key
}

# 检查命令是否可用
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}警告: $1 命令不可用，一些功能可能无法正常工作${NC}"
        sleep 1
    fi
}

# 检查必要的命令
check_dependencies() {
    commands=("cat" "lsb_release" "uname" "free" "lscpu" "df" "lsblk" "fdisk" "uptime" "top" "ip" "hostname")
    
    for cmd in "${commands[@]}"; do
        check_command $cmd
    done
}

# 1. 系统版本信息
show_system_version() {
    print_title
    echo -e "${YELLOW}系统版本信息${NC}"
    print_separator
    
    echo -e "${GREEN}通用系统信息 (/etc/os-release):${NC}"
    cat /etc/os-release 2>/dev/null || echo "文件不存在或无法访问"
    print_separator
    
    echo -e "${GREEN}LSB 发行版信息:${NC}"
    if command -v lsb_release &> /dev/null; then
        lsb_release -a
    else
        echo "lsb_release 命令不可用"
    fi
    print_separator
    
    echo -e "${GREEN}RedHat 系统信息:${NC}"
    if [ -f "/etc/redhat-release" ]; then
        cat /etc/redhat-release
    else
        echo "不是 RedHat 系统或文件不存在"
    fi
    print_separator
    
    echo -e "${GREEN}内核及架构信息:${NC}"
    uname -a
    
    wait_for_key
}

# 2. 内核信息
show_kernel_info() {
    print_title
    echo -e "${YELLOW}内核信息${NC}"
    print_separator
    
    echo -e "${GREEN}内核版本:${NC} $(uname -r)"
    echo -e "${GREEN}内核名称:${NC} $(uname -s)"
    echo -e "${GREEN}系统架构:${NC} $(uname -m)"
    echo -e "${GREEN}主机名:${NC} $(uname -n)"
    echo -e "${GREEN}处理器类型:${NC} $(uname -p 2>/dev/null || echo '信息不可用')"
    echo -e "${GREEN}硬件平台:${NC} $(uname -i 2>/dev/null || echo '信息不可用')"
    
    wait_for_key
}

# 3. 内存信息
show_memory_info() {
    print_title
    echo -e "${YELLOW}内存信息${NC}"
    print_separator
    
    echo -e "${GREEN}内存使用情况 (free):${NC}"
    free -h
    print_separator
    
    echo -e "${GREEN}是否查看详细内存信息 (/proc/meminfo)? [y/N]:${NC} "
    read choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}详细内存信息:${NC}"
        cat /proc/meminfo
    fi
    
    wait_for_key
}

# 4. CPU信息
show_cpu_info() {
    print_title
    echo -e "${YELLOW}CPU信息${NC}"
    print_separator
    
    if command -v lscpu &> /dev/null; then
        echo -e "${GREEN}CPU概览 (lscpu):${NC}"
        lscpu
    else
        echo "lscpu 命令不可用"
    fi
    print_separator
    
    echo -e "${GREEN}是否查看完整CPU信息 (/proc/cpuinfo)? [y/N]:${NC} "
    read choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}详细CPU信息:${NC}"
        cat /proc/cpuinfo
    fi
    
    wait_for_key
}

# 5. 磁盘信息
show_disk_info() {
    print_title
    echo -e "${YELLOW}磁盘信息${NC}"
    print_separator
    
    echo -e "${GREEN}磁盘使用情况 (df):${NC}"
    df -h
    print_separator
    
    echo -e "${GREEN}块设备信息 (lsblk):${NC}"
    if command -v lsblk &> /dev/null; then
        lsblk
    else
        echo "lsblk 命令不可用"
    fi
    print_separator
    
    echo -e "${GREEN}是否查看详细磁盘分区信息 (fdisk)? [y/N]:${NC} "
    read choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if command -v fdisk &> /dev/null; then
            echo -e "${GREEN}磁盘分区信息:${NC}"
            sudo fdisk -l || echo "需要root权限运行fdisk -l"
        else
            echo "fdisk 命令不可用"
        fi
    fi
    
    wait_for_key
}

# 6. 运行时间和负载
show_uptime_load() {
    print_title
    echo -e "${YELLOW}系统运行时间和负载${NC}"
    print_separator
    
    echo -e "${GREEN}系统运行时间和负载 (uptime):${NC}"
    uptime
    print_separator
    
    echo -e "${GREEN}选择监控工具:${NC}"
    echo "1) top - 基本系统监控"
    echo "2) htop - 增强系统监控 (如果已安装)"
    echo "3) 返回主菜单"
    echo -n "请选择 [1-3]: "
    read choice
    
    case $choice in
        1)
            top
            ;;
        2)
            if command -v htop &> /dev/null; then
                htop
            else
                echo -e "${YELLOW}htop 未安装，是否安装? [y/N]:${NC} "
                read install_choice
                if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                    if command -v apt &> /dev/null; then
                        sudo apt install -y htop
                        htop
                    elif command -v dnf &> /dev/null; then
                        sudo dnf install -y htop
                        htop
                    elif command -v yum &> /dev/null; then
                        sudo yum install -y htop
                        htop
                    else
                        echo "无法确定包管理器，请手动安装 htop"
                    fi
                else
                    top
                fi
            fi
            ;;
        *)
            ;;
    esac
}

# 7. 网络信息
show_network_info() {
    print_title
    echo -e "${YELLOW}网络信息${NC}"
    print_separator
    
    echo -e "${GREEN}主机名:${NC}"
    hostname
    print_separator
    
    echo -e "${GREEN}网络接口信息:${NC}"
    if command -v ip &> /dev/null; then
        ip addr
    elif command -v ifconfig &> /dev/null; then
        ifconfig
    else
        echo "ip 和 ifconfig 命令均不可用"
    fi
    print_separator
    
    echo -e "${GREEN}是否查看网络连接状态? [y/N]:${NC} "
    read choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}网络连接状态:${NC}"
        if command -v ss &> /dev/null; then
            ss -tuln
        elif command -v netstat &> /dev/null; then
            netstat -tuln
        else
            echo "ss 和 netstat 命令均不可用"
        fi
    fi
    
    wait_for_key
}

# 8. 安装和运行neofetch
install_run_neofetch() {
    print_title
    echo -e "${YELLOW}Neofetch 系统信息${NC}"
    print_separator
    
    if command -v neofetch &> /dev/null; then
        neofetch
    else
        echo -e "${YELLOW}neofetch 未安装，是否安装? [y/N]:${NC} "
        read choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            if command -v apt &> /dev/null; then
                sudo apt install -y neofetch
                neofetch
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y neofetch
                neofetch
            elif command -v yum &> /dev/null; then
                sudo yum install -y neofetch
                neofetch
            else
                echo "无法确定包管理器，请手动安装 neofetch"
            fi
        fi
    fi
    
    wait_for_key
}

# 9. 所有系统信息汇总
show_all_info() {
    print_title
    echo -e "${YELLOW}生成系统信息报告${NC}"
    print_separator
    
    report_file="system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "================ 系统信息报告 ================"
        echo "生成时间: $(date)"
        echo ""
        
        echo "================ 系统版本 ================"
        echo "--- OS Release ---"
        cat /etc/os-release 2>/dev/null
        echo ""
        
        if command -v lsb_release &> /dev/null; then
            echo "--- LSB Release ---"
            lsb_release -a 2>/dev/null
            echo ""
        fi
        
        if [ -f "/etc/redhat-release" ]; then
            echo "--- RedHat Release ---"
            cat /etc/redhat-release 2>/dev/null
            echo ""
        fi
        
        echo "================ 内核信息 ================"
        echo "完整内核信息: $(uname -a)"
        echo "内核版本: $(uname -r)"
        echo "内核名称: $(uname -s)"
        echo "系统架构: $(uname -m)"
        echo ""
        
        echo "================ 内存信息 ================"
        free -h
        echo ""
        
        echo "================ CPU信息 ================"
        if command -v lscpu &> /dev/null; then
            lscpu
        fi
        echo ""
        
        echo "================ 磁盘信息 ================"
        echo "--- 磁盘使用情况 ---"
        df -h
        echo ""
        
        if command -v lsblk &> /dev/null; then
            echo "--- 块设备信息 ---"
            lsblk
            echo ""
        fi
        
        echo "================ 系统负载 ================"
        uptime
        echo ""
        
        echo "================ 网络信息 ================"
        echo "主机名: $(hostname)"
        echo ""
        echo "--- 网络接口 ---"
        if command -v ip &> /dev/null; then
            ip addr
        elif command -v ifconfig &> /dev/null; then
            ifconfig
        fi
        echo ""
        
        if command -v neofetch &> /dev/null; then
            echo "================ Neofetch信息 ================"
            neofetch --stdout
        fi
        
    } > "$report_file"
    
    echo -e "${GREEN}系统信息已保存到 ${YELLOW}$report_file${NC}"
    echo -e "${GREEN}是否查看生成的报告? [y/N]:${NC} "
    read choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if command -v less &> /dev/null; then
            less "$report_file"
        else
            cat "$report_file"
        fi
    fi
    
    wait_for_key
}

# 主菜单
show_main_menu() {
    while true; do
        print_title
        echo -e "${YELLOW}请选择要查看的系统信息:${NC}"
        echo ""
        echo "1) 系统版本信息"
        echo "2) 内核信息"
        echo "3) 内存信息"
        echo "4) CPU信息"
        echo "5) 磁盘信息"
        echo "6) 运行时间和负载"
        echo "7) 网络信息"
        echo "8) 使用Neofetch显示系统信息"
        echo "9) 生成完整系统信息报告"
        echo "0) 退出"
        echo ""
        echo -n "请输入选项 [0-9]: "
        read choice
        
        case $choice in
            1) show_system_version ;;
            2) show_kernel_info ;;
            3) show_memory_info ;;
            4) show_cpu_info ;;
            5) show_disk_info ;;
            6) show_uptime_load ;;
            7) show_network_info ;;
            8) install_run_neofetch ;;
            9) show_all_info ;;
            0) 
                clear_screen
                echo -e "${GREEN}感谢使用系统信息查看工具!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}无效选项，请重试${NC}"
                sleep 1
                ;;
        esac
    done
}

# 主程序入口
check_dependencies
show_main_menu
