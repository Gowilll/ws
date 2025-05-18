#!/bin/bash

# 交互式Nmap助手
# 这个脚本帮助用户轻松构建和运行nmap命令

clear
echo "========================================"
echo "         交互式Nmap扫描助手"
echo "========================================"
echo

# 初始化nmap命令
NMAP_CMD="nmap"

# 目标设置
get_target() {
    echo "====== 目标设置 ======"
    echo "请指定扫描目标 (例如: scanme.nmap.org, 192.168.0.1/24):"
    read target
    
    if [ -z "$target" ]; then
        echo "错误: 必须指定目标。"
        get_target
    else
        NMAP_CMD="$NMAP_CMD $target"
    fi
}

# 扫描技术选择
select_scan_technique() {
    echo
    echo "====== 扫描技术 ======"
    echo "1) TCP SYN 扫描 (-sS) [默认，需要root权限]"
    echo "2) TCP 连接扫描 (-sT)"
    echo "3) UDP 扫描 (-sU) [需要root权限]"
    echo "4) TCP Null 扫描 (-sN) [需要root权限]"
    echo "5) TCP FIN 扫描 (-sF) [需要root权限]"
    echo "6) TCP Xmas 扫描 (-sX) [需要root权限]"
    echo "7) 不进行端口扫描，只做主机发现 (-sn)"
    echo "8) 不选择特定扫描类型"
    echo -n "请选择扫描技术 [1-8]: "
    read scan_choice

    case $scan_choice in
        1) NMAP_CMD="$NMAP_CMD -sS" ;;
        2) NMAP_CMD="$NMAP_CMD -sT" ;;
        3) NMAP_CMD="$NMAP_CMD -sU" ;;
        4) NMAP_CMD="$NMAP_CMD -sN" ;;
        5) NMAP_CMD="$NMAP_CMD -sF" ;;
        6) NMAP_CMD="$NMAP_CMD -sX" ;;
        7) NMAP_CMD="$NMAP_CMD -sn" ;;
        8) echo "不使用特定扫描技术" ;;
        *) echo "无效选择，不使用特定扫描技术" ;;
    esac
}

# 端口设置
select_ports() {
    echo
    echo "====== 端口设置 ======"
    echo "1) 扫描所有端口 (1-65535)"
    echo "2) 扫描常用端口 (默认)"
    echo "3) 扫描最常用的N个端口"
    echo "4) 指定端口范围"
    echo "5) 快速扫描 (-F)"
    echo -n "请选择端口选项 [1-5]: "
    read port_choice

    case $port_choice in
        1) NMAP_CMD="$NMAP_CMD -p 1-65535" ;;
        2) echo "使用nmap默认端口设置" ;;
        3) 
            echo -n "要扫描最常用的多少个端口? "
            read top_ports
            if [[ $top_ports =~ ^[0-9]+$ ]]; then
                NMAP_CMD="$NMAP_CMD --top-ports $top_ports"
            else
                echo "无效输入，使用默认端口设置"
            fi
            ;;
        4)
            echo -n "请输入端口范围 (例如: 20-25,80,443): "
            read port_range
            NMAP_CMD="$NMAP_CMD -p $port_range"
            ;;
        5) NMAP_CMD="$NMAP_CMD -F" ;;
        *) echo "无效选择，使用默认端口设置" ;;
    esac
}

# 主机发现设置
host_discovery() {
    echo
    echo "====== 主机发现设置 ======"
    echo "1) 默认主机发现"
    echo "2) 跳过主机发现，视所有主机为在线 (-Pn)"
    echo "3) 仅进行主机发现，不做端口扫描 (-sn)"
    echo -n "请选择主机发现选项 [1-3]: "
    read discovery_choice

    case $discovery_choice in
        1) echo "使用默认主机发现方法" ;;
        2) NMAP_CMD="$NMAP_CMD -Pn" ;;
        3) 
            if [[ $NMAP_CMD != *"-sn"* ]]; then
                NMAP_CMD="$NMAP_CMD -sn"
            fi
            ;;
        *) echo "无效选择，使用默认主机发现方法" ;;
    esac
}

# 服务和版本检测
service_detection() {
    echo
    echo "====== 服务/版本检测 ======"
    echo "1) 不做服务检测"
    echo "2) 标准服务检测 (-sV)"
    echo "3) 轻量级服务检测 (--version-light)"
    echo "4) 全面服务检测 (--version-all)"
    echo -n "请选择服务检测选项 [1-4]: "
    read service_choice

    case $service_choice in
        1) echo "不进行服务检测" ;;
        2) NMAP_CMD="$NMAP_CMD -sV" ;;
        3) NMAP_CMD="$NMAP_CMD -sV --version-light" ;;
        4) NMAP_CMD="$NMAP_CMD -sV --version-all" ;;
        *) echo "无效选择，不进行服务检测" ;;
    esac
}

# 系统检测
os_detection() {
    echo
    echo "====== 操作系统检测 ======"
    echo "是否启用操作系统检测? (-O) [y/N]: "
    read os_choice
    
    case $os_choice in
        [Yy]|[Yy][Ee][Ss]) NMAP_CMD="$NMAP_CMD -O" ;;
        *) echo "不进行操作系统检测" ;;
    esac
}

# 脚本扫描
script_scan() {
    echo
    echo "====== NSE 脚本扫描 ======"
    echo "1) 不使用脚本扫描"
    echo "2) 默认脚本扫描 (-sC)"
    echo "3) 自定义脚本类别"
    echo -n "请选择脚本扫描选项 [1-3]: "
    read script_choice

    case $script_choice in
        1) echo "不使用脚本扫描" ;;
        2) NMAP_CMD="$NMAP_CMD -sC" ;;
        3) 
            echo "请输入脚本类别或名称 (例如: vuln,safe,discovery): "
            read script_name
            NMAP_CMD="$NMAP_CMD --script=$script_name"
            ;;
        *) echo "无效选择，不使用脚本扫描" ;;
    esac
}

# 时序和性能设置
timing_performance() {
    echo
    echo "====== 时序和性能设置 ======"
    echo "1) 默认 (正常速度)"
    echo "2) T0 - 偏执 (极慢，隐蔽性极高)"
    echo "3) T1 - 偷偷摸摸 (慢速，隐蔽性高)"
    echo "4) T2 - 文雅 (较慢)"
    echo "5) T3 - 普通 (默认)"
    echo "6) T4 - 凶猛 (较快，可能被检测)"
    echo "7) T5 - 疯狂 (极快，精确度低)"
    echo -n "请选择时序模板 [1-7]: "
    read timing_choice

    case $timing_choice in
        1) echo "使用默认时序" ;;
        2) NMAP_CMD="$NMAP_CMD -T0" ;;
        3) NMAP_CMD="$NMAP_CMD -T1" ;;
        4) NMAP_CMD="$NMAP_CMD -T2" ;;
        5) NMAP_CMD="$NMAP_CMD -T3" ;;
        6) NMAP_CMD="$NMAP_CMD -T4" ;;
        7) NMAP_CMD="$NMAP_CMD -T5" ;;
        *) echo "无效选择，使用默认时序" ;;
    esac
}

# 输出选项
output_options() {
    echo
    echo "====== 输出选项 ======"
    echo "是否要保存扫描结果? [y/N]: "
    read save_results
    
    if [[ $save_results =~ ^[Yy] ]]; then
        echo -n "请输入输出文件名 (不含扩展名): "
        read output_file
        
        if [ -n "$output_file" ]; then
            echo "1) 保存为标准格式 (-oN)"
            echo "2) 保存为XML格式 (-oX)"
            echo "3) 保存为可搜索格式 (-oG)"
            echo "4) 同时保存为所有格式 (-oA)"
            echo -n "请选择输出格式 [1-4]: "
            read format_choice
            
            case $format_choice in
                1) NMAP_CMD="$NMAP_CMD -oN $output_file.txt" ;;
                2) NMAP_CMD="$NMAP_CMD -oX $output_file.xml" ;;
                3) NMAP_CMD="$NMAP_CMD -oG $output_file.gnmap" ;;
                4) NMAP_CMD="$NMAP_CMD -oA $output_file" ;;
                *) NMAP_CMD="$NMAP_CMD -oN $output_file.txt" ;;
            esac
        fi
    fi
    
    echo "设置输出详细程度:"
    echo "1) 默认"
    echo "2) 详细 (-v)"
    echo "3) 非常详细 (-vv)"
    echo -n "请选择详细程度 [1-3]: "
    read verbosity_choice
    
    case $verbosity_choice in
        1) echo "使用默认详细程度" ;;
        2) NMAP_CMD="$NMAP_CMD -v" ;;
        3) NMAP_CMD="$NMAP_CMD -vv" ;;
        *) echo "无效选择，使用默认详细程度" ;;
    esac
}

# 额外选项
extra_options() {
    echo
    echo "====== 额外选项 ======"
    echo "是否要添加 -A 参数 (启用操作系统检测、版本检测、脚本扫描和traceroute)? [y/N]: "
    read aggressive
    
    if [[ $aggressive =~ ^[Yy] ]]; then
        NMAP_CMD="$NMAP_CMD -A"
    fi
    
    echo "是否添加其他自定义参数? [y/N]: "
    read custom_params
    
    if [[ $custom_params =~ ^[Yy] ]]; then
        echo -n "请输入其他参数: "
        read params
        NMAP_CMD="$NMAP_CMD $params"
    fi
}

# 主函数
main() {
    get_target
    select_scan_technique
    select_ports
    host_discovery
    service_detection
    os_detection
    script_scan
    timing_performance
    output_options
    extra_options
    
    echo
    echo "====== 最终命令 ======"
    echo "$NMAP_CMD"
    echo
    echo "是否执行此命令? [Y/n]: "
    read execute
    
    if [[ ! $execute =~ ^[Nn] ]]; then
        echo "====== 执行扫描中 ======"
        eval $NMAP_CMD
        echo "====== 扫描完成 ======"
    else
        echo "命令未执行。您可以手动复制并运行上面的命令。"
    fi
}

# 检查是否为root用户
check_root() {
    echo "某些Nmap功能需要root权限才能正常工作。"
    if [ "$(id -u)" -ne 0 ]; then
        echo "警告: 当前非root用户，某些扫描类型可能无法工作。"
        echo "是否继续? [Y/n]: "
        read continue_nonroot
        
        if [[ $continue_nonroot =~ ^[Nn] ]]; then
            echo "请使用sudo或root权限重新运行此脚本。"
            exit 1
        fi
    else
        echo "当前以root权限运行，所有扫描类型可用。"
    fi
}

# 执行程序
check_root
main
