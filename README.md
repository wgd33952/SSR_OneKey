# SSR_OneKey
这是一个SSR一键包，自带了一些功能。

`wget -N --no-check-certificate https://raw.githubusercontent.com/kot4ri/SSR_OneKey/master/ssr-install.sh && bash ssr-install.sh`

# SSR一键包 命令
```
启动              =ssr start
停止              =ssr stop
状态              =ssr status
添加用户          =ssr adduser
删除用户          =ssr deluser
更新服务端        =ssr update
安装BBR           =ssr bbr
安装锐速          =ssr serverspeeder
卸载锐速          =ssr userverspeeder
安装支持锐速的内核=ssr kernel
卸载SSR           =ssr uninstall
```

# 安装libsodium
如果要使用 salsa20 或 chacha20 或 chacha20-ietf 算法，请安装 libsodium :

### centos：
```
yum install epel-release
yum install libsodium
```
### 如果想自己编译，那么可以用以下的命令
```
yum -y groupinstall "Development Tools"
wget https://github.com/jedisct1/libsodium/releases/download/1.0.15/libsodium-1.0.15.tar.gz
tar xf libsodium-1.0.15.tar.gz && cd libsodium-1.0.15
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
```

### ubuntu/debian：
```
apt-get install build-essential
wget https://github.com/jedisct1/libsodium/releases/download/1.0.15/libsodium-1.0.15.tar.gz
tar xf libsodium-1.0.15.tar.gz && cd libsodium-1.0.15
./configure && make -j2 && make install
ldconfig
```
如果曾经安装过旧版本，亦可重复用以上步骤更新到最新版，仅1.0.4或以上版本支持chacha20-ietf
