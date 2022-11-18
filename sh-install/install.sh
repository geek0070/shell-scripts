#! /bin/bash
source ./tools/funcs.sh
source ./tools/getopts.sh
source ./envs.sh

cur_dir=$(pwd)

function tipInit() {
  mkdir -p ~/Downloads/go
  mkdir -p ~/Downloads/python
  mkdir -p ~/Downloads/docker
  tipsWait "请下载一下内容到指定位置
0. 请设置django项目中settings中的ALLOWED_HOSTS;DATABASES;STATIC_URL,STATIC_ROOT,STATICFILES_DIRS;MEDIA_URL,MEDIA_ROOT
1. https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tgz --> ~/Downloads/python/Python-3.9.0.tgz
2. https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_V}/docker-compose-linux-x86_64 --> ~/Downloads/docker/docker-compose-linux-x86_64
3. https://dl.google.com/go/go${GO_V}.linux-amd64.tar.gz --> ~/Downloads/go/go${GO_V}.linux-amd64.tar.gz
"
}

##apt-get配置更新升级、nameserver配置
function initApt() {
  #passwd root   # 修改root密码	azAZ0112@
  echo "nameserver 114.114.114.114" | tee /etc/resolv.conf >/dev/null
  myEcho "=====修改naneserver完成=====" g
  chmod 777 -R /tmp
  myEcho "=====/tmp授权完成=====" g
  ##apt-get镜像源配置、更新、升级
  # if [[ ! -e /etc/apt/sources.list || ! "$(cat /etc/apt/sources.list)" =~ "https://mirrors.aliyun.com/ubuntu/" ]]; then
  echo ${cur_dir}/configfiles/ubuntu18-04-apt-get-images.txt
  if [[ -e ${cur_dir}/configfiles/ubuntu18-04-apt-get-images.txt ]]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    myEcho "=====备份sources.list完成=====" g
    cp ${cur_dir}/configfiles/ubuntu18-04-apt-get-images.txt /etc/apt/sources.list
    myEcho "=====写入sources.list完成=====" g
    myEcho "-----开始apt-get更新-----" g
    apt-get update
    myEcho "=====apt-get更新完成=====" g
  else
    myEcho "=====ubuntu18-04-apt-get-images.txt不存在！！！=====" y
  fi
}

##安装ssh-open、vim、sudo
function installSshVimSudoCurlNettoolsLsof() {
  ##安装vim
  vim --help >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    myEcho "-----开始vim安装-----" g
    apt-get -y install vim
    myEcho "=====vim安装完成=====" g
  else
    myEcho "=====请勿重复安装vim！！！=====" y
  fi
  ##安装sudo
  sudo --help >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    myEcho "-----开始sudo安装-----" g
    apt-get -y install sudo
    myEcho "=====sudo安装完成=====" g
  else
    myEcho "=====请勿重复安装sudo！！！=====" y
  fi
  ##安装ssh
  if [[ ! -e /usr/bin/ssh ]]; then
    myEcho "-----开始openssh-server安装-----" g
    apt-get -y install openssh-server
    myEcho "=====openssh-server安装完成=====" g
    replace "/etc/ssh/sshd_config" "#Port 22\n" "Port 22 \n"
    replace "/etc/ssh/sshd_config" "#ListenAddress 0.0.0.0\n" "ListenAddress 0.0.0.0 \n"
    replace "/etc/ssh/sshd_config" "#PermitRootLogin" "PermitRootLogin yes  #"
    replace "/etc/ssh/sshd_config" "#PasswordAuthentication yes\n" "PasswordAuthentication yes \n"
    myEcho "-----开始ssh重启-----" g
    /etc/init.d/ssh restart
    myEcho "=====ssh重启完成=====" g
    myEcho "-----当前的ssh进程如下-----" y
    ps -ef | grep ssh # 检查ssh是否启动
  else
    myEcho "=====请勿重复安装ssh！！！=====" y
  fi
  ##安装curl
  curl --help >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    myEcho "-----开始curl安装-----" g
    apt-get -y install curl
    myEcho "=====curl安装完成=====" g
  else
    myEcho "=====请勿重复安装curl！！！=====" y
  fi
  ##安装nettools
  ifconfig >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    myEcho "-----开始net-tools安装-----" g
    apt-get -y install net-tools
    myEcho "=====net-tools安装完成=====" g
  else
    myEcho "=====请勿重复安装net-tools！！！=====" y
  fi
  ##安装lsof
  lsof >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    myEcho "-----开始lsof安装-----" g
    apt-get -y install lsof
    myEcho "=====lsof安装完成=====" g
  else
    myEcho "=====请勿重复安装lsof！！！=====" y
  fi
}

##安装python
function installPython() {
  ##安装python安装需要的工具
  checkinstall --help >/tmp/error 2>&1
  if [[ ! $? == 1 ]]; then
    myEcho "-----开始apt-get安装wget build-essential checkinstall-----" g
    apt-get -y install wget build-essential checkinstall
    myEcho "=====wget build-essential checkinstall通过apt-get安装完成=====" g
  else
    myEcho "=====请勿重复安装wget build-essential checkinstall！！！=====" y
  fi
  myEcho "-----开始apt-get安装libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev-----" g
  apt-get -y install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev
  myEcho "===== libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev通过apt-get安装完成=====" g
  ##安装python3.9
  myEcho "-----开始python3.9解压-----" g
  cd ~/Downloads/python
  if [[ -e ~/Downloads/python/Python-3.9.0 ]]; then
    rm -rf Python-3.9.0
  fi
  tar xzf Python-3.9.0.tgz
  myEcho "=====python3.9解压完成=====" g
  if [[ ! -e /usr/local/bin/python3.9 || ! -e /usr/local/bin/pip3.9 ]]; then
    myEcho "-----开始./configure --enable-optimizations-----" g
    cd Python-3.9.0
    ./configure --enable-optimizations
    myEcho "=====./configure --enable-optimizations完成=====" g
    myEcho "-----开始make altinstall-----" g
    make altinstall
    myEcho "=====make altinstall完成=====" g
    cd .. && rm -rf Python-3.9.0
    myEcho "=====删除Python-3.9.0完成=====" g
  else
    myEcho "=====请勿对python3.9进行重复configure和altinstall！！！=====" y
  fi
  if [[ ! -e /usr/local/bin/pip ]]; then
    ln -s /usr/local/bin/python3.9 /usr/bin/python
    ln -s /usr/local/bin/pip3.9 /usr/local/bin/pip
    myEcho "=====python3.9和pip3.9软链接创建完成=====" g
  else
    myEcho "=====请勿对pip3.9重复创建软链接！！！=====" y
  fi
}

##安装mysql
##params : $1 -- root_secret root账户的密码
function installMysql() {
  ##安装mysql
  mysql --help >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    myEcho "-----开始安装mysql-----" g
    apt-get -y install mysql-server
    myEcho "-----安装mysql完成-----" g
  else
    myEcho "-----请勿重复安装mysql！！！-----" y
  fi
  replace "/etc/mysql/mysql.conf.d/mysqld.cnf" "bind-address		= 127.0.0.1\n" "#bind-address		= 127.0.0.1 \n"
  debian_secret=$(cat /etc/mysql/debian.cnf | awk '$1 == "password" {print $3}' | sed -n '1p')
  mysql -udebian-sys-maint -p${debian_secret} -e "use mysql; \
update user set plugin='mysql_native_password'; \
alter user 'root'@'localhost' identified with mysql_native_password by '${root_secret}'; \
flush privileges; \
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${root_secret}';"
  myEcho "=====root密码修改-->${root_secret},root远程命令设置完成=====" g
  mysql -uroot -p${root_secret} -e "create database ${dbname}"
  myEcho "=====root创建数据库${dbname}完成=====" g
  all_user_info=$(mysql -udebian-sys-maint -p${debian_secret} -e "use mysql;select user from user;")
  if [[ ! ${all_user_info} =~ ${new_account} ]]; then
    mysql -udebian-sys-maint -p${debian_secret} -e "use mysql; \
create USER '${new_account}'@localhost IDENTIFIED BY '${new_account_secret}';"
    myEcho "=====${new_account}创建完成=====" g
  else
    myEcho "=====mysql中${new_account}用户已存在,无需重复创建！！！=====" y
  fi
  service mysql restart
  myEcho "=====mysql重启完成=====" g
}

## 安装和配置docker, no params
function installDocker() {
  docker version >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    # 安装docker
    curl -fsSL get.docker.com | bash -s
    # 设置docker开机自启
    sudo systemctl enable docker.service
    # 将root用户添加到docker用户组
    sudo usermod -a -G docker root
    myEcho "=====docker安装与配置成功 --> 版本: latest=====" g
  else
    myEcho "=====docker已经安装过了,请勿重复安装=====" y
  fi
  # 配置docker的四个加速器 && 重载docker配置文件 && 重载docker服务
  mkdir -p /etc/docker
  touch daemon.json
  echo '
{"registry-mirrors":
  [
      "https://yub5b8wr.mirror.aliyuncs.com",
      "http://f1361db2.m.daocloud.io",
      "https://registry.docker-cn.com"
  ]
}' >/etc/docker/daemon.json
  myEcho "=====增加docker镜像源完成=====" g
  sudo systemctl daemon-reload
  myEcho "=====docker镜像文件重载完成=====" g
  sudo systemctl restart docker.service
  myEcho "=====docker服务重启完成=====" g
}

## 安装docker-compose, no params
function installDockerCompose() {
  mkdir -p ~/Downloads/docker
  docker-compose >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    if [[ -e $DOCKER_CONFIG/cli-plugins/docker-compose ]]; then
      rm -rf $DOCKER_CONFIG/cli-plugins/docker-compose
    fi
    cp ~/Downloads/docker/docker-compose-linux-x86_64 $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo usermod -a -G docker root
    if [[ ! -e /usr/bin/docker-compose ]]; then
      ln -s ~/.docker/cli-plugins/docker-compose /usr/bin/docker-compose
    fi
    myEcho "==================docker-compose下载与配置成功 --> $(docker-compose version)=================\n" g
  else
    myEcho "==================docker-compose已经安装过了,请勿重复安装！====================" y
  fi
}

## 安装go语言, no params
function installGo() {
  mkdir -p ~/Downloads
  # 解压go安装包
  go version >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    tar -xvf ~/Downloads/go/go${GO_V}.linux-amd64.tar.gz -C /usr/local
    mkdir -p /usr/local/go/gopath
    myEcho "======================goV${GO_V}下载安装成功=======================" g
  else
    myEcho "======================go${GO_V}已经安装过了,请勿重复安装======================" y
  fi
  if [[ ! $(cat /etc/profile) =~ GOROOT ]]; then
    echo 'export GOROOT=/usr/local/go' >>/etc/profile
    echo 'export GOPATH=/usr/local/go/gopath' >>/etc/profile
    echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >>/etc/profile
    myEcho "=====go环境变量添加完成=====" g
  else
    myEcho "=====请勿重复配置go环境变量！！！=====" g
  fi
  bash /etc/profile
  myEcho "=====/etc/profile激活完成=====" g
  go env -w GO111MODULE=on
  go env -w GOPROXY=https://goproxy.cn,direct
  myEcho "=====go env配置完成=====" g
  go version
}

if [[ ! ${isnotip} == true ]]; then
  tipInit
fi
for funcname in ${funcNames[@]}; do
  ${funcname}
done
