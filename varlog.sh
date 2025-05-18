#!/bin/bash

# Linux 日志管理与分析脚本
# 作者: wsj
# 日期: 2025-05-18
# 用途: 简化日志查看、分析和错误检测

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}警告: 部分功能可能需要 root 权限${NC}"
    fi
}

# 清屏函数
clear_screen() {
    clear
}

# 显示欢迎信息
show_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}      Linux 日志管理助手       ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
}

# 显示主菜单
show_main_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}请选择操作:${NC}"
    echo -e "${CYAN}1.${NC} 查看常见日志文件"
    echo -e "${CYAN}2.${NC} 错误日志快速检测"
    echo -e "${CYAN}3.${NC} 系统登录分析"
    echo -e "${CYAN}4.${NC} 实用日志组合命令"
    echo -e "${CYAN}5.${NC} 日志维护工具"
    echo -e "${CYAN}6.${NC} 自定义日志查询"
    echo -e "${CYAN}0.${NC} 退出程序"
    echo ""
    echo -n "请输入选项 [0-6]: "
}

# 显示日志文件子菜单
show_log_files_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}常见日志文件:${NC}"
    echo -e "${CYAN}1.${NC} 系统日志 (/var/log/syslog 或 /var/log/messages)"
    echo -e "${CYAN}2.${NC} 认证日志 (/var/log/auth.log)"
    echo -e "${CYAN}3.${NC} 内核日志 (/var/log/kern.log)"
    echo -e "${CYAN}4.${NC} 启动日志 (/var/log/boot.log)"
    echo -e "${CYAN}5.${NC} 应用日志(如 nginx, apache)"
    echo -e "${CYAN}6.${NC} 查看 journalctl 日志"
    echo -e "${CYAN}7.${NC} 查看 dmesg 输出"
    echo -e "${CYAN}0.${NC} 返回主菜单"
    echo ""
    echo -n "请输入选项 [0-7]: "
}

# 显示错误检测子菜单
show_error_detection_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}错误日志快速检测:${NC}"
    echo -e "${CYAN}1.${NC} 搜索系统日志中的错误"
    echo -e "${CYAN}2.${NC} 搜索认证日志中的失败"
    echo -e "${CYAN}3.${NC} 查看最近系统错误 (journalctl)"
    echo -e "${CYAN}4.${NC} 检查服务失败原因"
    echo -e "${CYAN}5.${NC} 分析所有日志中的关键错误"
    echo -e "${CYAN}6.${NC} 检查磁盘空间警告"
    echo -e "${CYAN}7.${NC} 查找网络连接问题"
    echo -e "${CYAN}0.${NC} 返回主菜单"
    echo ""
    echo -n "请输入选项 [0-7]: "
}

# 显示登录分析子菜单
show_login_analysis_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}系统登录分析:${NC}"
    echo -e "${CYAN}1.${NC} 查看登录历史 (last)"
    echo -e "${CYAN}2.${NC} 查看用户最近登录 (lastlog)"
    echo -e "${CYAN}3.${NC} 显示当前登录用户 (who/w)"
    echo -e "${CYAN}4.${NC} 检查登录失败记录"
    echo -e "${CYAN}5.${NC} 分析可疑 IP 登录尝试"
    echo -e "${CYAN}6.${NC} 查看系统重启历史"
    echo -e "${CYAN}0.${NC} 返回主菜单"
    echo ""
    echo -n "请输入选项 [0-6]: "
}

# 显示组合命令子菜单
show_command_combinations_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}实用日志组合命令:${NC}"
    echo -e "${CYAN}1.${NC} 过滤最近一小时的系统错误"
    echo -e "${CYAN}2.${NC} 统计登录失败的 IP 地址"
    echo -e "${CYAN}3.${NC} 查看特定服务的错误"
    echo -e "${CYAN}4.${NC} 查看特定用户的活动"
    echo -e "${CYAN}5.${NC} 分析日志中最常见的错误"
    echo -e "${CYAN}6.${NC} 导出错误报告"
    echo -e "${CYAN}0.${NC} 返回主菜单"
    echo ""
    echo -n "请输入选项 [0-6]: "
}

# 显示日志维护子菜单
show_log_maintenance_menu() {
    clear_screen
    show_header
    echo -e "${CYAN}日志维护工具:${NC}"
    echo -e "${CYAN}1.${NC} 查看日志轮转配置"
    echo -e "${CYAN}2.${NC} 测试日志轮转设置"
    echo -e "${CYAN}3.${NC} 手动执行日志轮转"
    echo -e "${CYAN}4.${NC} 压缩旧日志文件"
    echo -e "${CYAN}5.${NC} 检查日志权限"
    echo -e "${CYAN}6.${NC} 清空指定日志文件"
    echo -e "${CYAN}0.${NC} 返回主菜单"
    echo ""
    echo -n "请输入选项 [0-6]: "
}

# 处理查看日志文件选项
handle_log_files() {
    local choice=$1
    local lines=50
    
    echo -n "要显示多少行? [默认 50]: "
    read input_lines
    if [[ -n "$input_lines" ]]; then
        lines=$input_lines
    fi
    
    case $choice in
        1)
            if [[ -f "/var/log/syslog" ]]; then
                tail -n $lines /var/log/syslog | less
            elif [[ -f "/var/log/messages" ]]; then
                tail -n $lines /var/log/messages | less
            else
                echo -e "${RED}系统日志文件未找到!${NC}"
            fi
            ;;
        2)
            if [[ -f "/var/log/auth.log" ]]; then
                tail -n $lines /var/log/auth.log | less
            else
                echo -e "${RED}认证日志文件未找到!${NC}"
            fi
            ;;
        3)
            if [[ -f "/var/log/kern.log" ]]; then
                tail -n $lines /var/log/kern.log | less
            else
                echo -e "${RED}内核日志文件未找到!${NC}"
            fi
            ;;
        4)
            if [[ -f "/var/log/boot.log" ]]; then
                tail -n $lines /var/log/boot.log | less
            else
                echo -e "${RED}启动日志文件未找到!${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}可用的应用日志:${NC}"
            ls -l /var/log/ | grep -E 'nginx|apache|mysql|postgresql' | awk '{print NR". "$9}'
            echo -n "请选择要查看的应用日志 (输入编号): "
            read app_log_choice
            
            # 获取选择的日志文件名
            app_log=$(ls -l /var/log/ | grep -E 'nginx|apache|mysql|postgresql' | awk '{print $9}' | sed -n "${app_log_choice}p")
            if [[ -n "$app_log" ]]; then
                echo "查看 /var/log/$app_log"
                if [[ -d "/var/log/$app_log" ]]; then
                    ls -la "/var/log/$app_log"
                    echo -n "输入具体日志文件名: "
                    read specific_log
                    if [[ -f "/var/log/$app_log/$specific_log" ]]; then
                        tail -n $lines "/var/log/$app_log/$specific_log" | less
                    else
                        echo -e "${RED}指定的日志文件未找到!${NC}"
                    fi
                else
                    tail -n $lines "/var/log/$app_log" | less
                fi
            else
                echo -e "${RED}未选择有效的应用日志!${NC}"
            fi
            ;;
        6)
            echo -n "输入 journalctl 参数 (默认: -xe): "
            read journal_params
            if [[ -z "$journal_params" ]]; then
                journal_params="-xe"
            fi
            journalctl $journal_params | less
            ;;
        7)
            dmesg | less
            ;;
        *)
            echo -e "${RED}无效选项!${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}操作完成.${NC}"
    read -p "按任意键继续..." -n1 -s
}

# 处理错误检测选项
handle_error_detection() {
    local choice=$1
    
    case $choice in
        1)
            if [[ -f "/var/log/syslog" ]]; then
                grep -Ei "error|fail|fatal|panic" /var/log/syslog | tail -n 100 | less
            elif [[ -f "/var/log/messages" ]]; then
                grep -Ei "error|fail|fatal|panic" /var/log/messages | tail -n 100 | less
            else
                echo -e "${RED}系统日志文件未找到!${NC}"
            fi
            ;;
        2)
            if [[ -f "/var/log/auth.log" ]]; then
                grep -i "failed\|failure\|error" /var/log/auth.log | tail -n 100 | less
            else
                echo -e "${RED}认证日志文件未找到!${NC}"
            fi
            ;;
        3)
            journalctl -p err..alert -xb | less
            ;;
        4)
            echo -n "输入服务名称 (如 nginx, ssh): "
            read service_name
            systemctl status $service_name
            journalctl -u $service_name --no-pager | grep -i "error\|fail\|denied" | tail -n 50
            ;;
        5)
            echo -e "${YELLOW}正在分析所有重要日志中的错误...${NC}"
            {
                echo -e "\n=== 系统日志错误 ==="
                if [[ -f "/var/log/syslog" ]]; then
                    grep -Ei "error|fail|fatal|panic" /var/log/syslog | tail -n 20
                elif [[ -f "/var/log/messages" ]]; then
                    grep -Ei "error|fail|fatal|panic" /var/log/messages | tail -n 20
                fi
                
                echo -e "\n=== 认证错误 ==="
                if [[ -f "/var/log/auth.log" ]]; then
                    grep -i "failed\|failure\|error" /var/log/auth.log | tail -n 20
                fi
                
                echo -e "\n=== 内核错误 ==="
                dmesg | grep -i "error\|fail\|warn" | tail -n 20
                
                echo -e "\n=== Systemd 服务错误 ==="
                journalctl -p err..alert -b --no-pager | tail -n 20
            } | less
            ;;
        6)
            df -h
            echo ""
            grep -i "no space left on device" /var/log/syslog /var/log/messages 2>/dev/null | tail -n 20
            ;;
        7)
            echo -e "${YELLOW}检查网络连接问题...${NC}"
            {
                echo -e "\n=== 连接拒绝错误 ==="
                grep -Ei "connection refused|timeout|unreachable" /var/log/syslog /var/log/messages 2>/dev/null | tail -n 20
                
                echo -e "\n=== 网络接口错误 ==="
                dmesg | grep -i eth | grep -i error
                
                echo -e "\n=== 防火墙拒绝 ==="
                grep -i "DROP" /var/log/syslog /var/log/messages 2>/dev/null | tail -n 20
            } | less
            ;;
        *)
            echo -e "${RED}无效选项!${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}操作完成.${NC}"
    read -p "按任意键继续..." -n1 -s
}

# 处理登录分析选项
handle_login_analysis() {
    local choice=$1
    
    case $choice in
        1)
            last | less
            ;;
        2)
            lastlog | less
            ;;
        3)
            echo -e "\n=== 当前登录用户 (who) ==="
            who
            echo -e "\n=== 当前登录用户详情 (w) ==="
            w
            ;;
        4)
            if [[ -f "/var/log/auth.log" ]]; then
                grep "Failed password" /var/log/auth.log | tail -n 100 | less
            else
                echo -e "${RED}认证日志文件未找到!${NC}"
            fi
            ;;
        5)
            echo -e "${YELLOW}分析可疑 IP 登录尝试...${NC}"
            if [[ -f "/var/log/auth.log" ]]; then
                echo -e "\n=== 登录失败的 IP 统计 ==="
                grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -n 20
            else
                echo -e "${RED}认证日志文件未找到!${NC}"
            fi
            ;;
        6)
            last reboot | less
            ;;
        *)
            echo -e "${RED}无效选项!${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}操作完成.${NC}"
    read -p "按任意键继续..." -n1 -s
}

# 处理组合命令选项
handle_command_combinations() {
    local choice=$1
    
    case $choice in
        1)
            echo -e "${YELLOW}过滤最近一小时的系统错误...${NC}"
            journalctl --since "1 hour ago" -p err | less
            ;;
        2)
            echo -e "${YELLOW}统计登录失败的 IP 地址...${NC}"
            if [[ -f "/var/log/auth.log" ]]; then
                grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | less
            else
                echo -e "${RED}认证日志文件未找到!${NC}"
            fi
            ;;
        3)
            echo -n "输入服务名称 (如 nginx, ssh): "
            read service_name
            echo -e "${YELLOW}查看 $service_name 服务的错误...${NC}"
            journalctl -u $service_name --no-pager | grep -i "error\|fail\|denied\|warn" | less
            ;;
        4)
            echo -n "输入用户名: "
            read username
            echo -e "${YELLOW}查看用户 $username 的活动...${NC}"
            {
                echo -e "\n=== 用户登录历史 ==="
                last $username
                
                echo -e "\n=== 用户命令历史 ==="
                if [[ -f "/home/$username/.bash_history" ]]; then
                    tail -n 50 "/home/$username/.bash_history"
                else
                    echo "无法访问用户命令历史"
                fi
                
                echo -e "\n=== 用户进程 ==="
                ps -u $username -f
            } | less
            ;;
        5)
            echo -e "${YELLOW}分析日志中最常见的错误...${NC}"
            {
                if [[ -f "/var/log/syslog" ]]; then
                    grep -Ei "error|fail|fatal|panic" /var/log/syslog
                elif [[ -f "/var/log/messages" ]]; then
                    grep -Ei "error|fail|fatal|panic" /var/log/messages
                fi
            } | awk -F': ' '{print $NF}' | sort | uniq -c | sort -nr | head -n 20 | less
            ;;
        6)
            echo -n "输出错误报告文件名 (默认: error_report.txt): "
            read report_name
            if [[ -z "$report_name" ]]; then
                report_name="error_report.txt"
            fi
            
            echo -e "${YELLOW}生成错误报告到 $report_name...${NC}"
            {
                echo "===== 系统错误报告 ====="
                echo "生成时间: $(date)"
                echo "主机名: $(hostname)"
                echo "内核版本: $(uname -r)"
                echo ""
                
                echo "===== 系统资源状态 ====="
                echo "磁盘使用情况:"
                df -h
                echo ""
                echo "内存使用情况:"
                free -m
                echo ""
                
                echo "===== 系统日志错误 ====="
                if [[ -f "/var/log/syslog" ]]; then
                    grep -Ei "error|fail|fatal|panic" /var/log/syslog | tail -n 50
                elif [[ -f "/var/log/messages" ]]; then
                    grep -Ei "error|fail|fatal|panic" /var/log/messages | tail -n 50
                fi
                echo ""
                
                echo "===== 认证错误 ====="
                if [[ -f "/var/log/auth.log" ]]; then
                    grep -i "failed\|failure\|error" /var/log/auth.log | tail -n 50
                fi
                echo ""
                
                echo "===== 内核错误 ====="
                dmesg | grep -i "error\|fail\|warn" | tail -n 50
                echo ""
                
                echo "===== Systemd 服务错误 ====="
                journalctl -p err..alert -b --no-pager | tail -n 50
                echo ""
                
                echo "===== 登录失败的 IP 统计 ====="
                if [[ -f "/var/log/auth.log" ]]; then
                    grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -n 20
                fi
                echo ""
                
            } > "$report_name"
            
            echo -e "${GREEN}错误报告已生成到当前目录: $report_name${NC}"
            ;;
        *)
            echo -e "${RED}无效选项!${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}操作完成.${NC}"
    read -p "按任意键继续..." -n1 -s
}

# 处理日志维护选项
handle_log_maintenance() {
    local choice=$1
    
    case $choice in
        1)
            echo -e "${YELLOW}查看日志轮转配置...${NC}"
            {
                echo -e "\n=== 主配置文件 ==="
                cat /etc/logrotate.conf
                
                echo -e "\n=== 应用配置文件 ==="
                ls -la /etc/logrotate.d/
                
                echo -n "要查看特定应用的轮转配置吗? (y/n): "
                read view_specific
                if [[ "$view_specific" == "y" ]]; then
                    echo -n "输入应用名称 (如 nginx, apache2): "
                    read app_name
                    if [[ -f "/etc/logrotate.d/$app_name" ]]; then
                        echo -e "\n=== $app_name 轮转配置 ==="
                        cat "/etc/logrotate.d/$app_name"
                    else
                        echo -e "${RED}未找到该应用的轮转配置!${NC}"
                    fi
                fi
            } | less
            ;;
        2)
            echo -e "${YELLOW}测试日志轮转设置 (不执行)...${NC}"
            echo -n "输入配置文件 (默认: /etc/logrotate.conf): "
            read config_file
            if [[ -z "$config_file" ]]; then
                config_file="/etc/logrotate.conf"
            fi
            
            logrotate -d $config_file | less
            ;;
        3)
            echo -e "${YELLOW}手动执行日志轮转...${NC}"
            echo -e "${RED}警告: 这将立即执行日志轮转!${NC}"
            echo -n "确定要继续吗? (y/n): "
            read confirm
            
            if [[ "$confirm" == "y" ]]; then
                echo -n "输入配置文件 (默认: /etc/logrotate.conf): "
                read config_file
                if [[ -z "$config_file" ]]; then
                    config_file="/etc/logrotate.conf"
                fi
                
                logrotate -v -f $config_file
            else
                echo "操作已取消"
            fi
            ;;
        4)
            echo -e "${YELLOW}压缩旧日志文件...${NC}"
            echo -n "输入日志目录 (默认: /var/log): "
            read log_dir
            if [[ -z "$log_dir" ]]; then
                log_dir="/var/log"
            fi
            
            echo -e "${YELLOW}查找未压缩的旧日志文件...${NC}"
            find $log_dir -type f -name "*.log.*" -not -name "*.gz" -exec ls -lh {} \;
            
            echo -n "要压缩这些文件吗? (y/n): "
            read compress_confirm
            if [[ "$compress_confirm" == "y" ]]; then
                find $log_dir -type f -name "*.log.*" -not -name "*.gz" -exec gzip -v {} \;
            else
                echo "操作已取消"
            fi
            ;;
        5)
            echo -e "${YELLOW}检查日志权限...${NC}"
            find /var/log -type f -name "*.log" -exec ls -la {} \; | less
            ;;
        6)
            echo -e "${YELLOW}清空指定日志文件...${NC}"
            echo -e "${RED}警告: 这将清空日志内容!${NC}"
            echo -n "输入要清空的日志文件完整路径: "
            read log_path
            
            if [[ -f "$log_path" ]]; then
                echo -n "确定要清空 $log_path 吗? (y/n): "
                read clear_confirm
                
                if [[ "$clear_confirm" == "y" ]]; then
                    # 使用重定向清空而不是删除
                    echo "" > "$log_path"
                    echo -e "${GREEN}日志已清空!${NC}"
                else
                    echo "操作已取消"
                fi
            else
                echo -e "${RED}指定的日志文件不存在!${NC}"
            fi
            ;;
        *)
            echo -e "${RED}无效选项!${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}操作完成.${NC}"
    read -p "按任意键继续..." -n1 -s
}

# 处理自定义日志查询
handle_custom_query() {
    clear_screen
    show_header
    echo -e "${CYAN}自定义日志查询:${NC}"
    echo ""
    
    # 选择日志文件
    echo -e "${YELLOW}选择要查询的日志文件:${NC}"
    echo -e "1. 系统日志 (/var/log/syslog 或 /var/log/messages)"
    echo -e "2. 认证日志 (/var/log/auth.log)"
    echo -e "3. 内核日志 (/var/log/kern.log)"
    echo -e "4. journalctl 日志"
    echo -e "5. 自定义路径"
    echo -n "请选择 [1-5]: "
    read log_choice
    
    # 确定日志源
    case $log_choice in
        1)
            if [[ -f "/var/log/syslog" ]]; then
                log_source="/var/log/syslog"
            elif [[ -f "/var/log/messages" ]]; then
                log_source="/var/log/messages"
            else
                echo -e "${RED}系统日志文件未找到!${NC}"
                read -p "按任意键继续..." -n1 -s
                return
            fi
            ;;
        2)
            if [[ -f "/var/log/auth.log" ]]; then
                log_source="/var/log/auth.log"
            else
                echo -e "${RED}认证日志文件未找到!${NC}"
                read -p "按任意键继续..." -n1 -s
                return
            fi
            ;;
        3)
            if [[ -f "/var/log/kern.log" ]]; then
                log_source="/var/log/kern.log"
            else
                echo -e "${RED}内核日志文件未找到!${NC}"
                read -p "按任意键继续..." -n1 -s
                return
            fi
            ;;
        4)
            log_source="journalctl"
            ;;
        5)
            echo -n "输入日志文件路径: "
            read log_source
            if [[ ! -f "$log_source" ]]; then
                echo -e "${RED}指定的日志文件不存在!${NC}"
                read -p "按任意键继续..." -n1 -s
                return
            fi
            ;;
        *)
            echo -e "${RED}无效选项!${NC}"
            read -p "按任意键继续..." -n1 -s
            return
            ;;
    esac
    
    # 询问搜索关键词
    echo -n "输入要搜索的关键词 (留空显示所有): "
    read search_term
    
    # 询问时间范围
    echo -n "限制时间范围? (y/n): "
    read time_limit
    time_filter=""
    
    if [[ "$time_limit" == "y" ]]; then
        echo "选择时间范围:"
        echo "1. 今天"
        echo "2. 昨天"
        echo "3. 最近一小时"
        echo "4. 最近24小时"
        echo "5. 自定义范围"
        echo -n "请选择 [1-5]: "
        read time_choice
        
        case $time_choice in
            1)
                if [[ "$log_source" == "journalctl" ]]; then
                    time_filter="--since today"
                else
                    time_filter="-e \"$(date +%b\ %d)\""
                fi
                ;;
            2)
                if [[ "$log_source" == "journalctl" ]]; then
                    time_filter="--since yesterday --until today"
                else
                    # 获取昨天的日期格式
                    yesterday=$(date -d "yesterday" '+%b %d')
                    time_filter="-e \"$yesterday\""
                fi
                ;;
            3)
                if [[ "$log_source" == "journalctl" ]]; then
                    time_filter="--since \"1 hour ago\""
                else
                    # 获取一小时前的时间
                    hour_ago=$(date -d "1 hour ago" '+%H:%M:%S')
                    time_filter="-e \"$hour_ago\""
		fi
                ;;
            4)
                if [[ "$log_source" == "journalctl" ]]; then
                    time_filter="--since \"24 hours ago\""
                else
                    # 获取24小时前的日期和时间
                    day_ago=$(date -d "24 hours ago" '+%b %d %H:%M:%S')
                    time_filter="-e \"$day_ago\""
                fi
                ;;
            5)
                echo -n "输入开始时间 (格式: YYYY-MM-DD HH:MM:SS): "
                read start_time
                echo -n "输入结束时间 (格式: YYYY-MM-DD HH:MM:SS): "
                read end_time
                if [[ "$log_source" == "journalctl" ]]; then
                    time_filter="--since \"$start_time\" --until \"$end_time\""
                else
                    # 自定义时间过滤比较复杂，简化处理
                    echo -e "${YELLOW}注意: 非journalctl日志的自定义时间过滤可能不够精确${NC}"
                    time_filter=""
                fi
                ;;
            *)
                echo -e "${RED}无效选项!${NC}"
                time_filter=""
                ;;
        esac
    fi
    
    # 询问输出行数
    echo -n "最大显示行数 (默认: 100): "
    read max_lines
    if [[ -z "$max_lines" ]]; then
        max_lines=100
    fi
    
    # 执行查询
    echo -e "${YELLOW}执行日志查询...${NC}"
    
    if [[ "$log_source" == "journalctl" ]]; then
        # journalctl 查询
        cmd="journalctl $time_filter"
        if [[ -n "$search_term" ]]; then
            cmd="$cmd | grep -i \"$search_term\""
        fi
        cmd="$cmd | tail -n $max_lines"
    else
        # 普通日志文件查询
        cmd="cat $log_source"
        if [[ -n "$time_filter" ]]; then
            cmd="$cmd | grep $time_filter"
        fi
        if [[ -n "$search_term" ]]; then
            cmd="$cmd | grep -i \"$search_term\""
        fi
        cmd="$cmd | tail -n $max_lines"
    fi
    
    # 显示将要执行的命令
    echo -e "${CYAN}执行命令: ${NC}$cmd"
    echo ""
    
    # 使用eval执行命令并通过less显示
    eval "$cmd" | less
    
    echo ""
    echo -e "${GREEN}查询完成.${NC}"
    read -p "按任意键继续..." -n1 -s
}

# 主程序
main() {
    check_root
    
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1)
                show_log_files_menu
                read log_choice
                handle_log_files $log_choice
                ;;
            2)
                show_error_detection_menu
                read error_choice
                handle_error_detection $error_choice
                ;;
            3)
                show_login_analysis_menu
                read login_choice
                handle_login_analysis $login_choice
                ;;
            4)
                show_command_combinations_menu
                read command_choice
                handle_command_combinations $command_choice
                ;;
            5)
                show_log_maintenance_menu
                read maintenance_choice
                handle_log_maintenance $maintenance_choice
                ;;
            6)
                handle_custom_query
                ;;
            0)
                clear_screen
                echo -e "${GREEN}感谢使用 Linux 日志管理助手!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项!${NC}"
                read -p "按任意键继续..." -n1 -s
                ;;
        esac
    done
}

# 运行主程序
main
