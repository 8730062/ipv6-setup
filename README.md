运行以下代码执行添加ipv6脚本。脚本为网络上大佬编写，适合Debian和Ubuntu系统，目前亲测在甲骨文服务器有效。

~~~shell
wget -O ipv6_manager.sh "https://raw.githubusercontent.com/8730062/ipv6-setup/refs/heads/main/ipv6_manager.sh" && chmod +x ipv6_manager.sh && ./ipv6_manager.sh
~~~


下面是流量转发的脚本


~~~shell
wget -O manage_realm.sh "https://raw.githubusercontent.com/8730062/ipv6-setup/refs/heads/main/manage_realm.sh" && chmod +x manage_realm.sh && ./manage_realm.sh
~~~

服务器如果不能下载转发脚本的，可以下载脚步上传到服务器指定目录。
然后：
~~~shell
chmod +x manage_realm.sh
sudo ./manage_realm.sh
~~~
学习研究使用，请勿用于违法用途。
