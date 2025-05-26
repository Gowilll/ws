#!/bin/bash

echo "====== MySQL 交互式安装与配置脚本 ======"

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

# 选择设置或重置root密码
echo "你想要做什么？"
echo "1) 设置 root 密码"
echo "2) 重置 root 密码"
echo "3) 跳过"
read -p "请输入选项编号 [1/2/3]: " rootopt

if [[ "$rootopt" == "1" || "$rootopt" == "2" ]]; then
    read -sp "请输入要设置的root密码: " rootpass
    echo
    sudo apt install -y expect > /dev/null 2>&1
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
read -p "是否需要创建新用户？(y/n): " create_user_opt
if [[ "$create_user_opt" =~ ^[Yy]$ ]]; then
    read -p "请输入要创建的新用户名: " dbuser
    read -sp "请输入新用户的密码: " dbpass
    echo

    # 询问 root 密码以便后续登录
    if [[ "$rootopt" == "1" || "$rootopt" == "2" ]]; then
        TMP_ROOT_PASS="$rootpass"
    else
        read -sp "请输入现有的root密码以完成用户创建: " TMP_ROOT_PASS
        echo
    fi

    sudo apt install -y expect > /dev/null 2>&1
    expect <<EOF
spawn mysql -uroot -p
expect "Enter password:" { send "$TMP_ROOT_PASS\r" }
expect "mysql>" { send "CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';\r" }
expect "mysql>" { send "GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'localhost';\r" }
expect "mysql>" { send "FLUSH PRIVILEGES;\r" }
expect "mysql>" { send "exit\r" }
EOF

    echo "新用户 $dbuser 已创建并授权。"
else
    echo "跳过新用户创建。"
fi

echo "====== 完成！ ======"
echo "MySQL root 用户和（如有）新用户已配置完毕。"
