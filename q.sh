#!/bin/bash

#########################################################################
# 脚本名称: setup_bookweb.sh
#
# 功能说明:
#   - 一键部署 Flask + MySQL 的简易书籍管理 Web App
#   - 自动安装依赖、生成基础代码、创建目录结构
#   - 支持通过浏览器管理书籍数据，数据保存在 MySQL
#
# 使用方法:
#   1. 赋予脚本执行权限: chmod +x setup_bookweb.sh
#   2. 运行脚本: ./setup_bookweb.sh
#   3. 按提示配置数据库账号和表
#   4. 启动服务后，浏览器访问 http://公网IP:3333/
#
# 适用环境:
#   - Ubuntu 22.04 及以上
#   - 需具备 sudo 权限
#
# 作者: ws
# 日期: 2025-05-26
#########################################################################

# 打印 LOGO
echo " __        __"
echo "/__\\__/\\__/__\\"
echo "|   |    |   |"
echo "| W |    | S |"
echo "|___|    |___|"
echo "   ws - WebApp一键部署脚本"
echo

# 1. 安装依赖
echo "[1/7] 安装 Python3、pip3、MySQL客户端..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv default-mysql-client

# 2. 初始化目录
APPDIR="bookweb"
mkdir -p "$APPDIR/templates"
cd "$APPDIR"

# 3. 创建虚拟环境并激活
echo "[2/7] 创建 Python 虚拟环境..."
python3 -m venv venv
source venv/bin/activate

# 4. 安装Python依赖
echo "[3/7] 安装 Flask 和 pymysql..."
pip install --upgrade pip
pip install flask pymysql

# 5. 生成 app.py
echo "[4/7] 生成 app.py ..."
cat > app.py <<'EOF'
from flask import Flask, render_template, request, redirect
import pymysql

app = Flask(__name__)

# 修改这些MySQL参数为你的实际数据库信息
DB_HOST = "localhost"
DB_USER = "your_mysql_user"
DB_PASSWORD = "your_mysql_password"
DB_NAME = "your_db_name"

def get_db():
    return pymysql.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASSWORD,
        database=DB_NAME, charset="utf8mb4"
    )

@app.route('/')
def index():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT id, title, author, publisher FROM books")
    books = cursor.fetchall()
    cursor.close()
    db.close()
    return render_template('index.html', books=books)

@app.route('/add', methods=['GET', 'POST'])
def add_book():
    if request.method == 'POST':
        title = request.form['title']
        author = request.form['author']
        publisher = request.form['publisher']
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO books (title, author, publisher) VALUES (%s, %s, %s)",
            (title, author, publisher)
        )
        db.commit()
        cursor.close()
        db.close()
        return redirect('/')
    return render_template('add_book.html')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3333, debug=True)
EOF

# 6. 生成模板
echo "[5/7] 生成 index.html ..."
cat > templates/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>书籍管理</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
</head>
<body class="container">
    <h1 class="mt-4">书籍列表</h1>
    <a class="btn btn-primary mb-3" href="/add">添加书籍</a>
    <table class="table table-bordered">
      <tr>
        <th>ID</th><th>书名</th><th>作者</th><th>出版社</th>
      </tr>
      {% for id, title, author, publisher in books %}
      <tr>
        <td>{{id}}</td><td>{{title}}</td><td>{{author}}</td><td>{{publisher}}</td>
      </tr>
      {% endfor %}
    </table>
</body>
</html>
EOF

echo "[6/7] 生成 add_book.html ..."
cat > templates/add_book.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>添加书籍</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
</head>
<body class="container">
    <h1 class="mt-4">添加书籍</h1>
    <form method="post">
        <div class="mb-3">
            <label class="form-label">书名</label>
            <input class="form-control" type="text" name="title" required>
        </div>
        <div class="mb-3">
            <label class="form-label">作者</label>
            <input class="form-control" type="text" name="author" required>
        </div>
        <div class="mb-3">
            <label class="form-label">出版社</label>
            <input class="form-control" type="text" name="publisher" required>
        </div>
        <button class="btn btn-success" type="submit">提交</button>
        <a class="btn btn-secondary" href="/">返回</a>
    </form>
</body>
</html>
EOF

# 7. 说明和数据库建表提醒
echo
echo "====== 部署完成 ======"
echo
echo "【数据库建表】请先登录MySQL，执行如下命令创建数据库和表："
echo
echo "   CREATE DATABASE your_db_name DEFAULT CHARACTER SET utf8mb4;"
echo "   USE your_db_name;"
echo "   CREATE TABLE books ("
echo "     id INT PRIMARY KEY AUTO_INCREMENT,"
echo "     title VARCHAR(255),"
echo "     author VARCHAR(255),"
echo "     publisher VARCHAR(255)"
echo "   );"
echo
echo "【配置数据库账号】"
echo "请编辑 $APPDIR/app.py 修改 DB_USER、DB_PASSWORD 和 DB_NAME 部分为你的实际信息。"
echo
echo "【启动服务】"
echo "cd $APPDIR"
echo "source venv/bin/activate"
echo "python app.py"
echo
echo "【公网访问】"
echo "确保服务器防火墙和云安全组已开放 3333 端口。"
echo "浏览器访问: http://38.246.250.90:3333/"
echo
echo "完成！"
echo "======================"
