#! /bin/bash
source ./tools/funcs.sh
source ./tools/getopts.sh

source ./envs.sh

function tipInit() {
  tipsWait "请下载一下内容到指定位置
0. 请设置django项目中settings中的ALLOWED_HOSTS;DATABASES;STATIC_URL,STATIC_ROOT,STATICFILES_DIRS;MEDIA_URL,MEDIA_ROOT
1. https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tgz --> /root/Downloads/python/Python-3.9.0.tgz
"
}


##http转发配置
##params -- $1: uwsgi或者nginx,代表两个地方的配置
function httpTransmit(){
  if [[ $1 == uwsgi ]]; then
    cd ${django_proc_dir}
    echo "
[uwsgi]
chdir = ${django_proc_dir}
wsgi-file = ${django_proc_name}/wsgi.py
; http模式下可以直接访问,socket不可以
http = 0.0.0.0:${uwsgi_port}
master = true
processes = 10
buffer-size = 65536
chmod-socket = 664
vacuum = true
; log日志路径
daemonize = ${django_proc_dir}/uwsgi.log
" > uwsgi.ini # 注意:这里需要用/root绝对路径，而不是~
    myEcho "=====覆盖写uwsgi.ini完成=====" g
  else
    echo "
server {
	listen ${nginx_port};
	server_name ${ip};
	location / {
	  include uwsgi_params;
	  proxy_pass http://127.0.0.1:${uwsgi_port};
	  try_files \$uri \$uri/ =404;
	}
	location /static {
        alias ${django_proc_dir}/static;
    }
    location /media {
        alias ${django_proc_dir}/media;
    }
}
" >/etc/nginx/sites-enabled/${django_proc_name}_nginx.conf
    myEcho "=====覆盖写${django_proc_name}_nginx.conf完成=====" g
  fi
}

##socket链接转发配置
##params -- $1: uwsgi或者nginx,代表两个地方的配置
function socketTransmit(){
  if [[ $1 == uwsgi ]]; then
    cd ${django_proc_dir}
    echo "
[uwsgi]
chdir = ${django_proc_dir}
wsgi-file = ${django_proc_name}/wsgi.py
; socket的url
socket = ${ip}:${uwsgi_port}
master = true
processes = 10
buffer-size = 65536
chmod-socket = 664
vacuum = true
; log日志路径
daemonize = ${django_proc_dir}/uwsgi.log
" > uwsgi.ini # 注意:这里需要用/root绝对路径，而不是~
    myEcho "=====覆盖写uwsgi.ini完成=====" g
  else
    echo "
upstream mydjango {
	server ${ip}:${uwsgi_port};
}
server {
	listen ${nginx_port};
	server_name ${ip};
	location / {
	  uwsgi_pass mydjango;
	  include uwsgi_params;
	  try_files \$uri \$uri/ =404;
	}
	location /static {
        alias ${django_proc_dir}/static;
    }
    location /media {
        alias ${django_proc_dir}/media;
    }
}
" >/etc/nginx/sites-enabled/${django_proc_name}_nginx.conf
    myEcho "=====覆盖写${django_proc_name}_nginx.conf完成=====" g
  fi
}

##.sock文件转发配置
##params -- $1: uwsgi或者nginx,代表两个地方的配置
function sockFileTransmit(){
  if [[ $1 == uwsgi ]]; then
    cd ${django_proc_dir}
    echo "
[uwsgi]
chdir = ${django_proc_dir}
wsgi-file = ${django_proc_name}/wsgi.py
; http模式下可以直接访问,socket不可以
socket = ${django_proc_name}.sock
master = true
processes = 10
buffer-size = 65536
chmod-socket = 664
vacuum = true
; log日志路径
daemonize = ${django_proc_dir}/uwsgi.log
" > uwsgi.ini # 注意:这里需要用/root绝对路径，而不是~
    myEcho "=====覆盖写uwsgi.ini完成=====" g
  else
    echo "
upstream mydjango {
	server unix://${django_proc_dir}/${django_proc_name}.sock;
}
server {
	listen ${nginx_port};
	server_name ${ip};
	location / {
	  uwsgi_pass mydjango;
	  include uwsgi_params;
	  try_files \$uri \$uri/ =404;
	}
	location /static {
        alias ${django_proc_dir}/static;
    }
    location /media {
        alias ${django_proc_dir}/media;
    }
}
" >/etc/nginx/sites-enabled/${django_proc_name}_nginx.conf
    myEcho "=====覆盖写${django_proc_name}_nginx.conf完成=====" g
  fi
}

##uwsgi与django连接
##params : $1 -- 转发方式,有http,socket,sockfile
function uwsgiDjango() {
  cd ${django_proc_dir}
  ##pip安装需要的包
  pip install pipreqs -i ${image_source}
  myEcho "=====pipreqs安装完成=====" g
  pipreqs . --encoding=utf8 --force
  myEcho "=====requirements覆盖生成完成=====" g
  pip install -r requirements.txt -i ${image_source}
  myEcho "=====requirements中的包安装完成=====" g
  pip install uwsgi -i ${image_source}
  myEcho "=====uwsgi安装完成=====" g
  ##通过uwsgi启动django项目
  python manage.py migrate
  myEcho "=====python manage.py migrate数据库初始化完成=====" g
  python manage.py collectstatic --noinput
  myEcho "=====python manage.py collectstatic --noinput静态文件集合完成=====" g
  mkdir -p static
  mkdir -p media
  lsof -i :${uwsgi_port} | awk '$0~/'${uwsgi_port}'/{print $2}' | xargs kill -9
  myEcho "=====删除占用${uwsgi_port}端口的进程完成(有一个失败是正常的,为删除进程本身)=====" g
  if [[ $1 == http ]]; then
    httpTransmit uwsgi
  elif [[ $1 == socket ]]; then
    socketTransmit uwsgi
  elif [[ $1 == sockfile ]]; then
    sockFileTransmit uwsgi
  else
    myEcho "=====参数错误！！！=====" r
    exit 1
  fi
  sleep 1
  uwsgi -d --ini uwsgi.ini
  myEcho "=====uwsgi -d --ini uwsgi.ini中uwsgi启动端口为${uwsgi_port}的${django_proc_name} django项目完成=====" g
}

##nginx访问django项目的静态文件
##params : $1 -- 转发方式,有http,socket,sockfile
function nginxDjango() {
  mkdir -p /etc/nginx/default_bak
  if [[ -e /etc/nginx/sites-available/default ]]; then
    mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak_avai
    mv /etc/nginx/sites-available/default.bak_avai /etc/nginx/default_bak
    myEcho "=====移动/etc/nginx/sites-available/default完成=====" g
  fi
  if [[ -e /etc/nginx/sites-enabled/default ]]; then
    mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak_en
    mv /etc/nginx/sites-enabled/default.bak_en /etc/nginx/default_bak
    myEcho "=====移动/etc/nginx/sites-enabled/default完成=====" g
  fi
  lsof -i :${nginx_port} | awk '$0~/'${nginx_port}'/{print $2}' | xargs kill -9
  myEcho "=====强制删除${nginx_port}端口进程完成=====" g
  lsof -i :80 | awk '$0~/'$80'/{print $2}' | xargs kill -9
  myEcho "=====强制删除80端口进程完成=====" g
  ##安装和启动nginx
  nginx -h >/tmp/error 2>&1
  if [[ ! $? == 0 ]]; then
    apt-get -y install nginx
    myEcho "=====nginx安装完成=====" g
  else
    myEcho "=====请勿重复安装nginx！！！=====" y
  fi
  replace "/etc/nginx/nginx.conf" "user www-data;\n" "user ${nginx_user}; \n"
  if [[ $1 == http ]]; then
    httpTransmit nginx
  elif [[ $1 == socket ]]; then
    socketTransmit nginx
  elif [[ $1 == sockfile ]]; then
    sockFileTransmit nginx
  else
    myEcho "=====参数错误！！！=====" y
    exit 1
  fi
  myEcho "-----nginx.conf文件检查结果如下:-----" g
  nginx -t
  sleep 1
  service nginx start
  sleep 1
  service nginx restart
  myEcho "=====端口为${nginx_port}的nginx服务启动完成=====" g
}


if [[ ! ${isNotip} == true ]]; then
  tipInit
fi
if [[ ${isUwsgi} == true ]]; then
  uwsgiDjango ${transmitType}
fi
if [[ ${isNginx} == true ]]; then
  nginxDjango ${transmitType}
fi


