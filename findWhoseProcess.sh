#!/bin/bash
# find docker container by process id
processId=
# 提取程序的名字
PROGNAME=$(basename $0)
usage () {
    echo " $PROGNAME [-p --processId] or $PROGNAME"
    return
}
# 一个while case用来提取参数
while [[ -n $1 ]]; do
    case $1 in  
    -p | --processId) shift
                      processId=$1
                      ;;  
    -h | --help) usage
                 exit
                 ;;  
    *) usage >&2 
       exit 1
       ;;  
    esac
    shift
done

# 定义一个函数
findCon () {
    # $1 是函数的输入
    local pId=$1
    # awk '{print $1,$NF}' 打印第一列和最后一列，即容器ID和容器Name，awk 'NR != 1' 不打印第一行
    # read代表读入变量
    docker ps | awk '{print $1,$NF}' | awk 'NR != 1' | while read conId conName; do
                # 对pId的grep使用正则表达式，不然的话如果输入进程pId为21则会匹配到21274，通过前后加入空格匹配就可以防止出现这种问题
                local temp="[[:space:]]\{1\}${pId}[[:space:]]\{1\}"
                if [[ -n $(docker top $conId | grep -e $temp) ]]; then
                   printf "%s\t\t%s\t\t%s\t\t" $pId $conId $conName
                    break
                fi
            done
    return
}


# 如果 $processId不为空
if [[ -n $processId  ]]; then
    # 判断输入是否为数字
    if [[ $processId =~ ^[0-9]+$ ]]; then
        printf "conId%s\t\t\tconName%s\n" $conId $conName
        findCon $processId
    else
        echo "Please input number"
        exit 1
    fi
else
    num=1
   printf "PID\t\tconId%s\t\t\tconName%s\t\t\tGPU Memory\n" $conId $conName
    # 这一串awk操作为提取进程id和GPU使用情况，然后去掉空格，-F为设定awk分隔符，在命令行输出一边就看懂了
    nvidia-smi -q 2>&1| awk '/Process ID|Used GPU Memory/' | awk '{gsub(/[[:blank:]]*/,"",$0);print $0}' | awk -F ":" '{print $NF}' | while read item; do
    if [[ $(($num % 2)) != 0 ]]; then
        findCon $item
    else
        printf "%s\n" $item
    fi
    num=$((num+1))
    done
fi