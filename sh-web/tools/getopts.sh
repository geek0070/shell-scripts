####获取参数,将参数进行复制处理


function print_help(){
  echo "[options] --
  --uwsgi         使用uwsgi启动django项目
  --nginx         是否让nginx连接django项目的静态文件(注意保证settings的static_root和media_root)
  -ty|--transmitType
                  http        --采用http转发方式
                  socket      --采用socket链接转发方式(默认)
                  sockfile    --nginx采用.sock文件转发方式
  --notip         不进行初始提示
  "
  echo "----------------------------------------"
}

##初始化
transmitType="socket"

while [[ $# -gt 0 ]]; do
  ##防止-opt后面没有参数造成的死循环
  if [[ ! $1 == "" && $1 == ${tempopt} ]]; then
    myEcho "==========相同参数或死循环,请检查参数名！==========" r
    exit 1
  fi
  tempopt=$1
  case "$1" in
    --uwsgi)
      isUwsgi=true
      shift
      ;;
    --nginx)
      isNginx=true
      shift
      ;;
    -ty|--transmitType)
      if [[ ! $2 == "" && ! ${2:0:1} == "-" ]]; then
        transmitType=$2
        shift 2
      else
        transmitType="socket"
        shift
      fi
      ;;
    --notip)
      isNotip=true
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


echo "isUwsgi-->${isUwsgi}"
echo "isNginx-->${isNginx}"
echo "isNotip-->${isNotip}"
echo "transmitType-->${transmitType}"
myEcho "==============================" g

