#!/bin/bash

if [ ! -e '/etc/redhat-release' ]; then
echo "仅支持centos7"
exit
fi
if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
echo "仅支持centos7"
exit
fi

install_docker(){

    if ! [ -x "$(command -v docker)" ]
    then		
	yum install -y yum-utils device-mapper-persistent-data lvm2
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum makecache fast
	yum -y install docker-ce
	systemctl start docker
	systemctl enable docker
	echo "docker安装完成"
    else
        echo "docker已经存在"
    fi

}

install_seafile(){
  
  read -p "输入你的VPS绑定的域名：" domain
  read -p "设置管理员用户名（邮箱）：" user
  read -p "设置管理员密码：" password
  docker run -d --name seafile \
  --restart=always \
  -e SEAFILE_SERVER_LETSENCRYPT=true \
  -e SEAFILE_SERVER_HOSTNAME=$domain \
  -e SEAFILE_ADMIN_EMAIL=$user \
  -e SEAFILE_ADMIN_PASSWORD=$password \
  -v /opt/seafile-data:/shared \
  -p 80:80 \
  -p 443:443 \
  seafileltd/seafile:latest
  
  echo "安装完成，访问域名使用seafile"
  
}

remove_cache(){

    docker exec seafile /scripts/gc.sh

}

config_iptables(){
    systemctl stop firewalld
    systemctl disable firewalld
    yum install -y iptables-services
    systemctl start iptables
    systemctl enable iptables
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    ssh_port=$(awk '$1=="Port" {print $2}' /etc/ssh/sshd_config)
    iptables -A INPUT -p tcp -m tcp --dport ${ssh_port} -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    service iptables save
    echo "防火墙配置完成"
}

install_fail2ban(){

    yum install -y epel-release
    yum --enablerepo=epel -y install fail2ban
    systemctl enable fail2ban
    port=$(awk '$1=="Port" {print $2}' /etc/ssh/sshd_config)
    
cat > /etc/fail2ban/jail.local <<-EOF    
[DEFAULT]
ignoreip = 127.0.0.1 172.31.0.0/24 10.10.0.0/24 192.168.0.0/24
bantime = 18000
maxretry = 5
findtime = 300 
[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=$port, protocol=tcp]
logpath = /var/log/secure
EOF

    service fail2ban restart
}

start_menu(){
    clear
    echo "========================="
    echo " 介绍：适用于CentOS7"
    echo " 作者：atrandys"
    echo " 网站：www.atrandys.com"
    echo " Youtube：atrandys"
    echo "========================="
    echo "1. 安装seafile"
    echo "2. 垃圾回收"
    echo "3. 退出"
    echo
    read -p "请输入数字:" num
    case "$num" in
    	1)
	config_iptables
	install_fail2ban
	install_docker
	install_seafile
	;;
	2)
	remove_cache
	;;
	3)
	exit 1
	;;
	*)
	clear
	echo "请输入正确数字"
	sleep 5s
	start_menu
	;;
    esac
}

start_menu

