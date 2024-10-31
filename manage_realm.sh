#!/bin/bash

# 当脚本中任何命令执行失败时，立即退出
set -e

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 打印信息函数
echo_info() {
    echo -e "${GREEN}[信息]${NC} $1"
}

# 打印错误信息函数
echo_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 定义变量
REALM_URL="https://raw.githubusercontent.com/8730062/ipv6-setup/main/realm.tar.gz"
REALM_TAR="/root/realm.tar.gz"
REALM_DIR="/root"
REALM_EXEC="$REALM_DIR/realm"
CONFIG_FILE="/root/config.toml"
SERVICE_FILE="/etc/systemd/system/realm.service"

# 检查是否以root身份运行
if [[ "$EUID" -ne 0 ]]; then
   echo_error "请以root用户运行此脚本。"
   exit 1
fi

# 函数：添加一个转发规则
add_forwarding_rule() {
    echo "请选择转发规则类型："
    echo "1) IPv4 → IPv6 转发"
    echo "2) 纯IPv6 → IPv6 转发"
    read -rp "请输入选择（1或2）： " RULE_TYPE

    if [[ "$RULE_TYPE" == "1" ]]; then
        echo_info "您选择了 IPv4 → IPv6 转发。"

        read -rp "请输入监听的IPv4地址（例如 0.0.0.0）： " LISTEN_V4
        read -rp "请输入监听端口（例如 8000）： " LISTEN_PORT_V4
        read -rp "请输入远程IPv4地址（例如 1.1.1.1）： " REMOTE_V4
        read -rp "请输入远程端口（例如 443）： " REMOTE_PORT_V4

        read -rp "请输入本机IPv4地址（本机V4）： " LOCAL_V4
        read -rp "请输入本机端口（本机端口）： " LOCAL_PORT_V4
        read -rp "请输入落地鸡的IPv6地址（落地鸡V6）： " REMOTE_V6
        read -rp "请输入落地鸡的端口（落地鸡端口）： " REMOTE_PORT_V6

        echo "[[endpoints]]" >> "$CONFIG_FILE"
        echo "listen = "$LISTEN_V4:$LISTEN_PORT_V4"" >> "$CONFIG_FILE"
        echo "remote = "$REMOTE_V4:$REMOTE_PORT_V4"" >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"

        echo "[[endpoints]]" >> "$CONFIG_FILE"
        echo "listen = "$LOCAL_V4:$LOCAL_PORT_V4"" >> "$CONFIG_FILE"
        echo "remote = "[$REMOTE_V6]:$REMOTE_PORT_V6"" >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"

    elif [[ "$RULE_TYPE" == "2" ]]; then
        echo_info "您选择了 纯IPv6 → IPv6 转发。"

        # 设置IPv4的默认值
        DEFAULT_LISTEN_V4="0.0.0.0"
        DEFAULT_LISTEN_PORT_V4="8000"
        DEFAULT_REMOTE_V4="1.1.1.1"
        DEFAULT_REMOTE_PORT_V4="443"

        read -rp "请输入监听的IPv4地址（默认: $DEFAULT_LISTEN_V4）： " LISTEN_V4
        LISTEN_V4=${LISTEN_V4:-$DEFAULT_LISTEN_V4}

        read -rp "请输入监听端口（默认: $DEFAULT_LISTEN_PORT_V4）： " LISTEN_PORT_V4
        LISTEN_PORT_V4=${LISTEN_PORT_V4:-$DEFAULT_LISTEN_PORT_V4}

        read -rp "请输入远程IPv4地址（默认: $DEFAULT_REMOTE_V4）： " REMOTE_V4
        REMOTE_V4=${REMOTE_V4:-$DEFAULT_REMOTE_V4}

        read -rp "请输入远程端口（默认: $DEFAULT_REMOTE_PORT_V4）： " REMOTE_PORT_V4
        REMOTE_PORT_V4=${REMOTE_PORT_V4:-$DEFAULT_REMOTE_PORT_V4}

        # 强制输入IPv6参数
        while true; do
            read -rp "请输入本机IPv6地址（本机V6）： " LOCAL_V6
            if [[ -n "$LOCAL_V6" ]]; then
                break
            else
                echo_error "本机IPv6地址不能为空，请重新输入。"
            fi
        done

        while true; do
            read -rp "请输入本机端口（本机端口）： " LOCAL_PORT_V6
            if [[ -n "$LOCAL_PORT_V6" ]]; then
                break
            else
                echo_error "本机端口不能为空，请重新输入。"
            fi
        done

        while true; do
            read -rp "请输入落地鸡的IPv6地址（落地鸡V6）： " REMOTE_V6
            if [[ -n "$REMOTE_V6" ]]; then
                break
            else
                echo_error "落地鸡的IPv6地址不能为空，请重新输入。"
            fi
        done

        while true; do
            read -rp "请输入落地鸡的端口（落地鸡端口）： " REMOTE_PORT_V6
            if [[ -n "$REMOTE_PORT_V6" ]]; then
                break
            else
                echo_error "落地鸡的端口不能为空，请重新输入。"
            fi
        done

        echo "[[endpoints]]" >> "$CONFIG_FILE"
        echo "listen = "$LISTEN_V4:$LISTEN_PORT_V4"" >> "$CONFIG_FILE"
        echo "remote = "$REMOTE_V4:$REMOTE_PORT_V4"" >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"

        echo "[[endpoints]]" >> "$CONFIG_FILE"
        echo "listen = "[$LOCAL_V6]:$LOCAL_PORT_V6"" >> "$CONFIG_FILE"
        echo "remote = "[$REMOTE_V6]:$REMOTE_PORT_V6"" >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"

    else
        echo_error "无效的选择。请重新添加转发规则。"
        return
    fi
}

# 函数：生成配置文件头部
generate_config_header() {
    echo "[network]" > "$CONFIG_FILE"
    echo "no_tcp = false" >> "$CONFIG_FILE"
    echo "use_udp = true" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
}

# 安装和配置realm
install_realm() {
    echo_info "开始安装realm..."

    # 第1步：下载并解压realm
    echo_info "从$REALM_URL下载realm..."
    wget -O "$REALM_TAR" "$REALM_URL"

    echo_info "解压realm..."
    tar -xvf "$REALM_TAR" -C "$REALM_DIR"

    echo_info "设置realm可执行权限..."
    chmod +x "$REALM_EXEC"

    # 第2步：配置realm
    echo_info "配置realm..."
    > "$CONFIG_FILE" # 清空配置文件

    generate_config_header

    while true; do
        add_forwarding_rule
        echo "是否要添加另一个转发规则？ (y/n)"
        read -rp "请输入选择（y/n）： " add_more
        case "$add_more" in
            [Yy]* ) ;;
            [Nn]* ) break ;;
            * ) echo_error "请输入 y 或 n。";;
        esac
    done

    echo_info "配置文件已创建在 $CONFIG_FILE。"

    # 第3步：创建systemd服务
    echo_info "创建realm的systemd服务..."

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
WorkingDirectory=$REALM_DIR
ExecStart=$REALM_EXEC -c $CONFIG_FILE

[Install]
WantedBy=multi-user.target
EOF

    echo_info "systemd服务文件已创建在 $SERVICE_FILE。"

    # 第4步：启动并启用realm服务
    echo_info "重新加载systemd守护进程..."
    systemctl daemon-reload

    echo_info "设置realm服务开机自启..."
    systemctl enable realm

    echo_info "启动realm服务..."
    systemctl start realm

    echo_info "检查realm服务状态..."
    systemctl status realm --no-pager

    echo_info "realm安装和配置完成。"
}

# 启动realm服务
start_realm() {
    echo_info "启动realm服务..."
    systemctl start realm
    echo_info "检查realm服务状态..."
    systemctl status realm --no-pager
}

# 停止realm服务
stop_realm() {
    echo_info "停止realm服务..."
    systemctl stop realm
    echo_info "realm服务已停止。"
}

# 检查realm服务状态
status_realm() {
    echo_info "检查realm服务状态..."
    systemctl status realm --no-pager
}

# 修改realm配置
modify_realm_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo_error "配置文件 $CONFIG_FILE 未找到，请先安装realm。"
        exit 1
    fi

    echo_info "开始修改realm配置..."

    # 备份当前配置文件
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    echo_info "已备份当前配置文件为 ${CONFIG_FILE}.bak。"

    # 清空配置文件并生成头部
    > "$CONFIG_FILE"
    generate_config_header

    while true; do
        add_forwarding_rule
        echo "是否要添加另一个转发规则？ (y/n)"
        read -rp "请输入选择（y/n）： " add_more
        case "$add_more" in
            [Yy]* ) ;;
            [Nn]* ) break ;;
            * ) echo_error "请输入 y 或 n。";;
        esac
    done

    echo_info "配置文件已更新在 $CONFIG_FILE。"

    # 重启realm服务以应用新配置
    echo_info "重启realm服务以应用新配置..."
    systemctl restart realm

    echo_info "检查realm服务状态..."
    systemctl status realm --no-pager

    echo_info "realm配置修改完成。"
}

# 完全删除realm及相关文件
remove_realm() {
    echo_info "正在删除realm及相关文件..."

    # 停止服务
    if systemctl is-active --quiet realm; then
        echo_info "停止realm服务..."
        systemctl stop realm
    fi

    # 禁用服务
    echo_info "禁用realm服务开机自启..."
    systemctl disable realm || echo_info "realm服务未启用。"

    # 删除systemd服务文件
    if [[ -f "$SERVICE_FILE" ]]; then
        echo_info "删除systemd服务文件..."
        rm -f "$SERVICE_FILE"
    else
        echo_info "未找到systemd服务文件。"
    fi

    # 重新加载systemd守护进程
    echo_info "重新加载systemd守护进程..."
    systemctl daemon-reload

    # 删除realm可执行文件和配置文件
    if [[ -f "$REALM_EXEC" ]]; then
        echo_info "删除realm可执行文件..."
        rm -f "$REALM_EXEC"
    else
        echo_info "未找到realm可执行文件。"
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
        echo_info "删除配置文件..."
        rm -f "$CONFIG_FILE"
    else
        echo_info "未找到配置文件。"
    fi

    # 删除下载的压缩包
    if [[ -f "$REALM_TAR" ]]; then
        echo_info "删除下载的压缩包..."
        rm -f "$REALM_TAR"
    else
        echo_info "未找到下载的压缩包。"
    fi

    echo_info "realm已被彻底删除。"
}

# 显示菜单
show_menu() {
    echo "=============================="
    echo "        Realm 管理脚本"
    echo "=============================="
    echo "1) 安装 realm"
    echo "2) 启动 realm 服务"
    echo "3) 停止 realm 服务"
    echo "4) 查看 realm 服务状态"
    echo "5) 修改 realm 配置"
    echo "6) 删除 realm"
    echo "0) 退出"
    echo "=============================="
}

# 主循环
while true; do
    show_menu
    read -rp "请输入您的选择（0-6）： " choice
    # 去除输入的前后空格
    choice=$(echo "$choice" | xargs)
    case "$choice" in
        0)
            echo_info "退出脚本。"
            exit 0
            ;;
        1)
            install_realm
            ;;
        2)
            start_realm
            ;;
        3)
            stop_realm
            ;;
        4)
            status_realm
            ;;
        5)
            modify_realm_config
            ;;
        6)
            remove_realm
            ;;
        *)
            echo_error "无效的选择，请输入0-6之间的数字。"
            ;;
    esac
    echo # 添加一个空行以提高可读性
done
