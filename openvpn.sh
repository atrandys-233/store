#!/bin/bash


rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))  
}

install_openssl(){

    cd /root
    yum install -y libtool perl-core openssl-devel zlib-devel gcc cmake wget pcre* lzo lzo-devel net-tools pam pam-devel epel-release
    sed -i "s/enabled=0/enabled=1/" /etc/yum.repos.d/epel.repo
    wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz
    tar -xvzf openssl-1.1.1a.tar.gz
    cd openssl-1.1.1a
    ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
    make && make install
    mv /usr/bin/openssl /usr/bin/openssl.old
    mv /usr/include/openssl /usr/include/openssl.old
    ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
    ln -s /usr/local/ssl/include/openssl/ /usr/include/openssl
    cd /etc/ld.so.conf.d/
    echo "/usr/local/ssl/lib" >> openssl-1.1.1a.conf
    ldconfig -v
    openssl version -a
}

install_openvpn(){

    cd /root
    wget https://swupdate.openvpn.org/community/releases/openvpn-2.4.7.tar.gz
    tar xzvf openvpn-2.4.7.tar.gz
    cd openvpn-2.4.7
    ./configure --prefix=/etc/openvpn
    make && make install
    yum install -y easy-rsa-3.0.3-1.el7
    #复制easy到openvpn
    cp -rf /usr/share/easy-rsa/ /etc/openvpn/easy-rsa
    #复制server.conf
    cp -f /root/openvpn-2.4.7/sample/sample-config-files/server.conf /etc/openvpn/
    #复制vars
    cp -f /usr/share/doc/easy-rsa-3.0.3/vars.example /etc/openvpn/easy-rsa/3.0.3/vars
    cd /etc/openvpn/easy-rsa/3.0.3/
    #生成ta.key
    /etc/openvpn/sbin/openvpn --genkey --secret ta.key
    #创建pki目录
    ./easyrsa init-pki
    #生成证书
    ./easyrsa --batch build-ca nopass
    #生成服务端证书
    ./easyrsa --batch build-server-full server nopass
    #生成客户端端证书
    ./easyrsa --batch build-client-full client1 nopass
    #生成gen
    ./easyrsa gen-dh
    
    mkdir /etc/openvpn/client

    #管理证书位置
    cp /etc/openvpn/easy-rsa/3.0.3/pki/ca.crt /etc/openvpn/
    cp /etc/openvpn/easy-rsa/3.0.3/pki/issued/server.crt /etc/openvpn/
    cp /etc/openvpn/easy-rsa/3.0.3/pki/dh.pem /etc/openvpn/dh2048.pem
    cp /etc/openvpn/easy-rsa/3.0.3/pki/private/server.key /etc/openvpn/
    cp /etc/openvpn/easy-rsa/3.0.3/ta.key /etc/openvpn/
    cp /etc/openvpn/easy-rsa/3.0.3/pki/issued/client1.crt /etc/openvpn/client/
    cp /etc/openvpn/easy-rsa/3.0.3/ta.key /etc/openvpn/client/
    cp /etc/openvpn/easy-rsa/3.0.3/pki/ca.crt /etc/openvpn/client/
    cp /etc/openvpn/easy-rsa/3.0.3/pki/private/client1.key /etc/openvpn/client/

    #关闭firewalld
    systemctl stop firewalld
    systemctl disable firewalld

    #安装iptables
    yum install -y iptables-services 
    systemctl enable iptables 
    systemctl start iptables 

    #清除规则
    iptables -F
    iptables -t nat -A POSTROUTING -s 10.8.0.0/16 ! -d 10.8.0.0/16 -j MASQUERADE
    service iptables save

    #启用转发
    echo 1 > /proc/sys/net/ipv4/ip_forward

    #永久转发
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p

    #配置服务端server.conf
    cd /etc/openvpn
    rm -f server.conf
    curl -o server.conf https://raw.githubusercontent.com/atrandys/store/master/server.conf

    #将openvpn客户端文件下载到client
    curl -o /etc/openvpn/client/client.ovpn https://raw.githubusercontent.com/atrandys/store/master/client.ovpn

    port=$(rand 10000 60000)
    serverip=$(curl ipv4.icanhazip.com)
    sed -i "s/myip/$serverip/" /etc/openvpn/client/client.ovpn
    sed -i "s/myport/$port/" /etc/openvpn/client/client.ovpn
    sed -i "s/myport/$port/" /etc/openvpn/server.conf

    #启动openvpn
    cd /etc/openvpn 
    nohup /etc/openvpn/sbin/openvpn --config server.conf > open.log 2>&1 &


#增加自启动脚本
cat > /etc/rc.d/init.d/autoopenvpn<<-EOF
#!/bin/sh
#chkconfig: 2345 80 90
#description:autoopenvpn
cd /etc/openvpn 
nohup /etc/openvpn/sbin/openvpn --config server.conf > open.log 2>&1 &
EOF

    #设置脚本权限
    chmod +x /etc/rc.d/init.d/autoopenvpn
    chkconfig --add autoopenvpn
    chkconfig autoopenvpn on

}

install_openssl
install_openvpn


