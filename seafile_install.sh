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

	yum remove -y docker docker-client docker-client-latest docker-common docker-latest  docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine		
	yum install -y yum-utils device-mapper-persistent-data lvm2
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum makecache fast
	yum -y install docker-ce
	systemctl start docker
	systemctl enable docker

}

install_seafile(){
  
  read -p "输入你的VPS绑定的域名：" domain
  read -p "设置管理员用户名（邮箱）：" user
  read -p "设置管理员密码：" password
  docker run -d --name seafile \
  -e SEAFILE_SERVER_LETSENCRYPT=true \
  -e SEAFILE_SERVER_HOSTNAME=$domain \
  -e SEAFILE_ADMIN_EMAIL=$user \
  -e SEAFILE_ADMIN_PASSWORD=$password \
  -v /opt/seafile-data:/shared \
  -p 80:80 \
  -p 443:443 \
  seafileltd/seafile:latest
  
  echo "安装完成"
  
}

remove_seafile(){

    docker stop seafile
    docker rm -f seafile
    echo "卸载完成"

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
    echo "2. 卸载seafile"
    echo "3. 退出"
    echo
    read -p "请输入数字:" num
    case "$num" in
    	1)
	install_docker
	install_seafile
	;;
	2)
	remove_seafile
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


