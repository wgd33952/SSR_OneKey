#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#安装目录
ssrdir=#ssrdir#

#判断是否root权限
function rootness(){
    if [[ $EUID -ne 0 ]]; then
        echo "错误:你好像没有root权限呀……/Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

# Check OS
function checkos(){
    if [ -f /etc/redhat-release ];then
        OS=CentOS
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS=Debian
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS=Ubuntu
    else
        echo "你这是啥JB系统……老子都没听说过。/Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}


#防火墙设置
function firewall_set(){
    echo "正在设置防火墙"
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep '${shadowsocksport}' | grep 'ACCEPT' > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo "port ${shadowsocksport} has been set up."
            fi
        else
            echo "WARNING: iptables looks like shutdown or not installed, please manually set it if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ];then
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
            echo "Firewalld looks like not running, try to start..."
            systemctl start firewalld
            if [ $? -eq 0 ];then
                firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
                firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
                firewall-cmd --reload
            else
                echo "WARNING: Try to start firewalld failed. please enable port ${shadowsocksport} manually if necessary."
            fi
        fi
    fi
    echo "防火墙设置完成"
}

#CentOS换内核
function kernel(){
    if [ -f /etc/redhat-release ];then
        read -p "现在准备将你的内核更换为支持锐速的版本，按任意键继续。"
        if centosversion 6; then
            rpm -ivh http://soft.91yun.org/ISO/Linux/CentOS/kernel/kernel-firmware-2.6.32-504.3.3.el6.noarch.rpm
            rpm -ivh http://soft.91yun.org/ISO/Linux/CentOS/kernel/kernel-2.6.32-504.3.3.el6.x86_64.rpm --force
        elif centosversion 7; then
            rpm -ivh http://soft.91yun.org/ISO/Linux/CentOS/kernel/kernel-3.10.0-229.1.2.el7.x86_64.rpm --force
		fi
        echo "安装结束，重启后生效。"
    else
        echo "这个功能仅支持CentOS。"
        exit 1
	fi
}

function adduser(){
	clear
    # Not support CentOS 5
    if centosversion 5; then
        echo "不兹瓷CentOS5，请提高自己的姿势水平。/Not support CentOS 5, please change to CentOS 6+ or Debian 7+ or Ubuntu 12+ and try again."
		echo "Not Support CentOS5."
        exit 1
    fi
    # Set shadowsocks config password
    echo "先来设个密码吧~/Please input password"
    read -p "(Default: ShadowsocksR):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="ShadowsocksR"
    echo
    echo "---------------------------"
    echo "Password = $shadowsockspwd"
    echo "---------------------------"
    echo
    # Set shadowsocks config port
    while true
    do
    read -p "然后再来设定个端口/Please input port for shadowsocksR [1-65535]:" shadowsocksport
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "Port = $shadowsocksport"
            echo "---------------------------"
            echo
            break
        else
            echo "你输入了什么奇怪的东西/Input error! Please input correct numbers."
        fi
    else
        echo "你输入了什么奇怪的东西/Input error! Please input correct numbers."
    fi
    done
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo
    # Set shadowsocks method
    echo "请设置一种加密算法/Please Set method for shadowsocksR:"
	echo "如果使用None算法的话协议请选择auth_chain系列"
    read -p "(Default: chacha20):" method
    [ -z "$method" ] && method="chacha20"
    echo
    echo "---------------------------"
    echo "Method = $method"
    echo "---------------------------"
    echo
    # Set shadowsocks protocol
    echo "请设置一种SSR协议/Please Set protocol for shadowsocksR:"
	echo "可选："
	echo "origin"
	echo "auth_sha1_v4_compatible"
	echo "auth_chain_a"
	echo "auth_chain_b"
	echo "auth_chain_c"
	echo "auth_chain_d"
	echo "如果使用None算法的话协议请选择auth_chain系列"
    read -p "(Default: auth_chain_a):" protocol
    [ -z "$protocol" ] && protocol="auth_chain_a"
    echo
    echo "---------------------------"
    echo "Protocol = $protocol"
    echo "---------------------------"
    echo
    # Set shadowsocks obfs
    echo "最后来设置一个混淆方式/Please Set obfs for shadowsocksR:"
	echo "可选："
	echo "plain"
	echo "auth_sha1_v4_compatible"
	echo "http_simple"
	echo "http_post"
	echo "tls1.2_ticket_auth_compatible"
    read -p "(Default: tls1.2_ticket_auth):" obfs
    [ -z "$obfs" ] && obfs="tls1.2_ticket_auth"
    echo
    echo "---------------------------"
    echo "obfs = $obfs"
    echo "---------------------------"
    echo
    echo "好了，恭喜你都设置完了，按任意键以生效以上配置。"
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
	firewall_set
	#添加用户
	cd ${ssrdir}
	python mujson_mgr.py -a -p ${shadowsocksport} -k ${shadowsockspwd} -m ${method} -O ${protocol} -o ${obfs}
	
}

function deluser(){
    while true
    do
    read -p "输入你要干掉的端口/Please input port which you want to delete:" shadowsocksport
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "port = $shadowsocksport"
            echo "---------------------------"
            echo
            break
        else
            echo "Input error! Please input correct numbers."
        fi
    else
        echo "Input error! Please input correct numbers."
    fi
    done
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
	#添加用户
	cd ${ssrdir}
	python mujson_mgr.py -d -p ${shadowsocksport}
	

}

function update(){
	cd ${ssrdir}
	git pull
}

function bbr(){
	wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
    chmod +x bbr.sh
    ./bbr.sh
}

function serverspeeder(){
	wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh && bash serverspeeder.sh
}

function userverspeeder(){
	chattr -i /serverspeeder/etc/apx* && /serverspeeder/bin/serverSpeeder.sh uninstall -f
}

function uninstall(){
	bash ${ssrdir}stop.sh
	rm -rf /etc/init.d/ssr
	rm -rf /bin/ssr
	rm -rf ${ssrdir}
	echo "卸载完成"
}


case "$1" in
'adduser')
    adduser
    ;;
'deluser')
    deluser
    ;;	
'update')
    update
    ;;	
'bbr')
    bbr
    ;;	
'serverspeeder')
    serverspeeder
    ;;	
'userverspeeder')
    userverspeeder
    ;;
'kernel')
    kernel
    ;;
'uninstall')
    uninstall
    RETVAL=$?
    ;;
*)
    echo "---------------------------"
    echo "SSR一键包 命令"
    echo "启动              =ssr start"
	echo "停止              =ssr stop"
	echo "状态              =ssr status"
	echo "添加用户          =ssr adduser"
	echo "删除用户          =ssr deluser"
	echo "更新服务端        =ssr update"
	echo "安装BBR           =ssr bbr"
	echo "安装锐速          =ssr serverspeeder"
	echo "卸载锐速          =ssr userverspeeder"
	echo "安装支持锐速的内核=ssr kernel"
	echo "卸载SSR           =ssr uninstall"
	echo "---------------------------"
	echo "说明：安装BBR会把系统升级到最新内核，如果有特定内核版本需求请慎用。"
	echo "      锐速破解版使用的是91yun提供的包，如果内核不兼容请手动更换。"
	echo "---------------------------"
    RETVAL=1
    ;;
esac
exit $RETVAL




