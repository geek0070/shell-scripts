
# 添加变量，主要是环境变量
# params: $1-->filepath; $2-->var
function addVar() {
  file_cont=$(cat $1)
  var=$(echo -e "\n$2")
  if [[ "$file_cont" =~ "$var" ]]; then
    #    echo "container"
    echo "$1已经配置了$2环境变量，请勿重复配置"
  else
    #    echo " not container"
    echo $var >>$1
    echo "成功添加变量 $2"
  fi
}
# 添加该环境变量，防止echo中文乱码
#addVar "/etc/profile" "export LANG=zh_CN.gbk"
#source "/etc/profile"


## 修改文件变量，使用old_var_name为了应对注释的情况
## 参数 -- filepath, old_var_name, new_var_name, new_value
function modifyVar() {
  file_cont=$(cat $1)
  var_name_=$(echo -e "\n$2")
  var_value_=$(echo -e "\n$3")
  line=$(grep ^$2=* $1)
  # $line匹配的等于空值""
  if [[ "$line" == "" ]]; then
    echo "$1文件中不存在变量$2,请检查！"
  else
    new_line="$3=$4"
    #    echo $line        # 原行
    #    echo $new_line    # 替换后的行
    sed -ig "s:$line:$new_line:g" $1 # 将/g删除,将替换所有的变量
    echo "成功修改$2=$4"
  fi
}
#将./bootstrap.sh中的VERSION改为VERSION2=2.4.1
#modifyVar "./bootstrap.sh" "VERSION" "VERSION2" "2.4.1"


## 自己的echo进行输出，增加了颜色参数
## params: cont: 输出的内容; color: 输出文本的颜色(kb:天蓝色;y:黄色;r:红色;g:绿色;rk:红第黑字;k:黑色;bk:蓝底黑字;_r:下划线红字;b_:蓝字斜体)
function myEcho() {
  if [[ $2 == "kb" ]]; then
    echo -e "\033[36m$1\033[0m"
  elif [[ $2 == "y" ]]; then
    echo -e "\033[33m$1\033[0m"
  elif [[ $2 == "r" ]]; then
    echo -e "\033[31m$1\033[0m"
  elif [[ $2 == "rk" ]]; then
    echo -e "\033[41;30m$1\033[0m"
  elif [[ $2 == "k" ]]; then
    echo -e "\033[30m$1\033[0m"
  elif [[ $2 == "g" ]]; then
    echo -e "\033[32m$1\033[0m"
  elif [[ $2 == "bk" ]]; then
    echo -e "\033[46;30m$1\033[0m"
  elif [[ $2 == "_r" ]]; then
    echo -e "\033[4;31m$1\033[0m"
  elif [[ $2 == "b_" ]]; then
    echo -e "\033[5;34m$1\033[0m"
  else
    echo "参数错误"
  fi
}
#myEcho testText _r


## 直到输入exit退出,进行手动操作中的文本提示
## params -- tipText(提示文本)
function tipsWait() {
  while true; do
    echo -e "\033[36m$1\033[0m"
    read -p "  -- [输入q退出当前循环进入下一条命令] > " val
    if [[ $val == "q" ]]; then
      break
    else
      echo "非输入q,继续循环"
    fi
  done
}
#inputWait "请访问https,进行手动操作"


## 替换函数,将文件中所有指定文本替换为另一个值(文件中不能只有一行,至少两行)
## 支持单引号和双引号替换
## params -- filepath: 文件路径; old_text: 被替换文本; new_text: 替换文本
function replace(){
  if [[ ! "$3" =~ "$2" ]]; then
#    echo -e "$(sed "s|$2|$3|g" $1)" > $1
    echo -e "$(sed ":a;N;s|$2|$3|g;ba" $1)" > $1
    echo "成功将 $1 中所有 $2 --> $3"
  else
    myEcho "两者之间存在包含关系,需要想办法使 $2 不被 $3 包含" r
    myEcho "------tips:使用空格进行微调 使两者之间不存在包含关系--------"
  fi
}
#replace $MY_PROJ_DIR/docker-compose.bak1.yaml.bak "../organizations" "crypto-config"


##复制或下载本地文件或者网上下载文件;文件存在不操作
##params: $1--文件或者目录的目标路径; $2--临时存放的本地路径(存在的话); $3--url下载的地址; $4--是否复制或者下载替换已存在的文件
##除非有$引用,否则本地路径不要使用双引号
function myDownload(){
  goal_path=$1
  local_path=$2
  url=$3
  is_replace=$4
  if [[ ! -e $(dirname ${goal_path}) ]]; then
    mkdir -p $(dirname ${goal_path})
  fi
  if [[ -e ${local_path} && ! -e ${goal_path} ]]; then
    #本地的文件是一个目录
    if [[ -d ${local_path} ]]; then
      #将目录复制带目标路径的所在目录中
      cp -r ${local_path} $(dirname ${goal_path})
      myEcho "成功将${local_path}文件夹复制到$(dirname ${goal_path})" g
    else
      cp ${local_path} $(dirname ${goal_path})
      myEcho "成功将${local_path}文件复制到$(dirname ${goal_path})" g
    fi
  elif [[ ! -e ${goal_path} && ! -e ${local_path} ]]; then
    myEcho "开始下载${url}" y
    wget -P $(dirname ${goal_path}) -t 0 -T 10 ${url}
    myEcho "成功下载${url}到$(dirname ${goal_path})" g
  else  # ${goal_path}已存在
    if [[ ${is_replace} == "y" ]]; then
      if [[ ${local_path} != ${goal_path} ]]; then
        rm -rf ${goal_path}
      fi
      if [[ -d ${local_path} ]]; then
        cp -r ${local_path} $(dirname ${goal_path})
        myEcho "复制文件夹覆盖了${goal_path}！" g
      elif [[ -e ${local_path} ]]; then
        cp ${local_path} $(dirname ${goal_path})
        myEcho "复制文件覆盖了${goal_path}！" g
      else
        wget -P $(dirname ${goal_path}) -t 0 -T 10 ${url}
        myEcho "下载文件覆盖了${goal_path}！" g
      fi
    else
      myEcho "目标路径${goal_path}已存在,请勿重复复制或下载！" y
    fi
  fi
}
#如果${EXPLORE_PROJ_DIR}/config.json不存在,将~/Downloads/exploreConfig/config.json复制到${EXPLORE_PROJ_DIR};如果~/Downloads/exploreConfig/config.json也不存在,从url中下载到${EXPLORE_PROJ_DIR}
#myDownload "${EXPLORE_PROJ_DIR}/config.json" "~/Downloads/exploreConfig/config.json" "https://raw.githubusercontent.com/hyperledger/blockchain-explorer/main/examples/net1/config.json"

