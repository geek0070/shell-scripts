#[usually]
##django项目的根目录路径
django_proc_dir=$(cd ~/web/django/projs/testProj && pwd)
##nginx端口号
nginx_port=8005
##uwsgi端口号
uwsgi_port=8006

#[mini modify]
##nginx.conf中user变量
nginx_user=root
##pip镜像源
image_source="https://pypi.tuna.tsinghua.edu.cn/simple"
##django使用的mysql数据库名字
dbname="testdb"
##所在机器网卡名称
#netcardName='ens33'
 netcardName='bond0'

#[no modify]
#当前文件所在目录路径
cur_dir=$(pwd)
##django项目的名字(自动提取)
django_proc_name=$(echo "${django_proc_dir}" | rev | cut -d "/" -f 1 | rev)
##ip地址(自动提取)
ip=$(ifconfig | grep -n -A1 "${netcardName}" | awk '$0~/broadcast/{print $3}')



