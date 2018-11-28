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
  -p 80:443 \
  -p 443:443 \
  seafileltd/seafile:latest
  
}

install_docker
install_seafile
