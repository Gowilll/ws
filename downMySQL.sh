#!/bin/bash

echo "====== MySQL 交互式安装与配置脚本 ======"

# 检查并安装 expect（自动化交互工具）
if ! command -v expect > /dev/null 2>&1; then
    echo "正在安装 expect..."
    sudo apt update && sudo apt install -y expect
fi

# 检测MySQL是否已安装
if dpkg -l | grep -q mysql-server; then
    echo "MySQL 已安装，跳过安装步骤。"
else
    echo "MySQL 未检测到，开始安装..."
    sudo apt update
    sudo apt install -y mysql-server
    echo "MySQL 安装完成。"
fi

# 检查MySQL服务状态
echo "启动并检查MySQL服务..."
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl status mysql --no-pager

# root 密码设置或重置选项
while true; do
    echo "你想要做什么？"
    echo "1) 设置 root 密码"
    echo "2) 重置 root 密码"
    echo "3) 跳过"
    read -p "请输入选项编号 [1/2/3]: " rootopt
    case "$rootopt" in
        1|2|3) break ;;
        *) echo "无效输入，请输入 1、2 或 3。" ;;
    esac
done

if [[ "$rootopt" == "1" || "$rootopt" == "2" ]]; then
    while true; do
        read -sp "请输入要设置的root密码: " rootpass
        echo
        read -sp "请再次输入root密码进行确认: " rootpass2
        echo
        if [[ "$rootpass" == "$rootpass2" && -n "$rootpass" ]]; then
            break
        else
            echo "两次输入的密码不一致或为空，请重新输入。"
        fi
    done
    expect <<EOF
spawn sudo mysql
expect "mysql>" { send "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY \"$rootpass\";\r" }
expect "mysql>" { send "FLUSH PRIVILEGES;\r" }
expect "mysql>" { send "exit\r" }
EOF
    echo "root 密码已设置。"
else
    echo "跳过 root 密码设置。"
fi

# 询问是否创建新用户
while true; do
    read -p "是否需要创建新用户？(y/n): " create_user_opt
    case "$create_user_opt" in
        [YyNn]) break ;;
        *) echo "无效输入，请输入 y 或 n。" ;;
    esac
done

if [[ "$create_user_opt" =~ ^[Yy]$ ]]; then
    # 用户名输入校验
    while true; do
        read -p "请输入要创建的新用户名: " dbuser
        if [[ -z "$dbuser" ]]; then
            echo "用户名不能为空，请重新输入。"
        else
            break
        fi
    done
    # 密码输入校验
    while true; do
        read -sp "请输入新用户的密码: " dbpass
        echo
        read -sp "请再次输入新用户密码进行确认: " dbpass2
        echo
        if [[ "$dbpass" == "$dbpass2" && -n "$dbpass" ]]; then
            break
        else
            echo "两次输入的密码不一致或为空，请重新输入。"
        fi
    done

    # 获取root密码
    if [[ "$rootopt" == "1" || "$rootopt" == "2" ]]; then
        TMP_ROOT_PASS="$rootpass"
    else
        while true; do
            read -sp "请输入现有的root密码以完成用户创建: " TMP_ROOT_PASS
            echo
            if [[ -n "$TMP_ROOT_PASS" ]]; then
                break
            fi
        done
    fi

    # 检查root密码正确性
    if ! mysql -uroot -p"$TMP_ROOT_PASS" -e ";" 2>/dev/null; then
        echo "root密码验证失败，请检查输入!"
        exit 1
    fi

    # 授权提示
    while true; do
        read -p "新用户是否需要所有数据库权限？(y:所有数据库/n:仅指定数据库): " grant_all_opt
        case "$grant_all_opt" in
            [YyNn]) break ;;
            *) echo "无效输入，请输入 y 或 n。" ;;
        esac
    done

    if [[ "$grant_all_opt" =~ ^[Yy]$ ]]; then
        GRANT_SQL="GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'localhost';"
    else
        while true; do
            read -p "请输入授权的数据库名（如未创建请先用root账号手动创建）: " dbname
            if [[ -z "$dbname" ]]; then
                echo "数据库名不能为空，请重新输入。"
            else
                break
            fi
        done
        GRANT_SQL="GRANT ALL PRIVILEGES ON \`${dbname}\`.* TO '$dbuser'@'localhost';"
    fi

    expect <<EOF
spawn mysql -uroot -p
expect "Enter password:" { send "$TMP_ROOT_PASS\r" }
expect "mysql>" { send "CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';\r" }
expect "mysql>" { send "$GRANT_SQL\r" }
expect "mysql>" { send "FLUSH PRIVILEGES;\r" }
expect "mysql>" { send "exit\r" }
EOF

    echo "新用户 $dbuser 已创建并授权。"
else
    echo "跳过新用户创建。"
fi

echo "====== 完成！ ======"
echo "MySQL root 用户和（如有）新用户已配置完毕。"
echo "如需登录请使用：mysql -u用户名 -p"
