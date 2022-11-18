####获取参数,将参数进行复制处理

function print_help(){
  echo "[options] --
apt               填充apt-get镜像源,更新惊险源
ssh               安装ssh、vim、sudo、curl、net-tools、lsof
python            安装python
mysql             安装mysql,并设置root密码和简历geek用户并设置密码
docker            安装docker并进行镜像源配置
docker-compose    安装docker-compose
go                安装go
--notip           不进行提示
-h|--help         帮助
"
  echo "----------------------------------------"
}

##执行安装的函数名字参数
funcNames=()
##设置的参数
isnotip=false   # 是否不进行提示

while [[ $# -gt 0 ]]; do
  case $1 in
    apt)
      funcNames=("${funcNames[@]}" initApt)
      shift
      ;;
    ssh)
      funcNames=("${funcNames[@]}" installSshVimSudoCurlNettoolsLsof)
      shift
      ;;
    python)
      funcNames=("${funcNames[@]}" installPython)
      shift
      ;;
    mysql)
      funcNames=("${funcNames[@]}" installMysql)
      shift
      ;;
    docker)
      funcNames=("${funcNames[@]}" installDocker)
      shift
      ;;
    docker-compose)
      funcNames=("${funcNames[@]}" installDockerCompose)
      shift
      ;;
    go)
      funcNames=("${funcNames[@]}" installGo)
      shift
      ;;
    --notip)
      isnotip=true
      shift
      ;;
    -h|--help)
      print_help
      shift 1
      exit 0
      ;;
    *)
      myEcho "---------------参数设置错误: $1---------------" r
      print_help
      exit 1
      ;;
  esac
done

echo "funcNames-->${funcNames[@]}"
echo "isnotip-->${isnotip}"
myEcho "==============================" g

