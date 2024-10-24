#!/bin/bash

# 菜单显示函数
show_menu() {
    echo "请选择一个选项:"
    echo "1) 从 GitHub 下载并运行添加 IPv6 的脚本"
    echo "2) 查看 IPv6 是否添加成功"
    echo "3) 退出"
}

# 执行选项的函数
execute_choice() {
    read -p "输入选项 [1-3]: " choice
    case $choice in
        1)
            echo "从 GitHub 下载并运行添加 IPv6 的脚本..."
            # 替换为你在 GitHub 上的脚本链接
            wget -O ipv6_setup.sh "https://raw.githubusercontent.com/8730062/ipv6-setup/refs/heads/main/ipv6_setup.sh"
            if [[ -f "ipv6_setup.sh" ]]; then
                chmod +x ipv6_setup.sh
                bash ipv6_setup.sh
            else
                echo "下载失败，请检查 GitHub 链接是否正确。"
            fi
            ;;
        2)
            echo "检查 IPv6 是否添加成功..."
            ip addr | grep net6
            ;;
        3)
            echo "退出..."
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择。"
            ;;
    esac
}

# 主程序循环
while true; do
    show_menu
    execute_choice
done
