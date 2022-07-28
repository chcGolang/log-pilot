#!/bin/bash
# 自定义要清除的日志索引
searchIndexs=(ws-dev unraid segment api-dev admin-dev)
elastic_url=192.168.43.68
elastic_port=9200
# 日志存储时间
save_days=5

date2stamp () {
    date --utc --date "$1" +%s
}

dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}

# 删除指定的过期的索引
for searchIndex in ${searchIndexs[*]}; do
  for index in $(curl -s "${elastic_url}:${elastic_port}/_cat/indices?v" | grep -E " ${searchIndex}-20[0-9][0-9].[0-1][0-9].[0-3][0-9]" | awk '{ print $3 }'); do
    date=$(echo ${index: -10} | sed 's/\./-/g')
    cond=$(date +%Y-%m-%d)
    diff=$(dateDiff -d $date $cond)
    #echo -n "${index} (${diff})"
    if [ $diff -gt $save_days ]; then
      echo "curl -XDELETE \"${elastic_url}:${elastic_port}/${index}?pretty\""
      curl -XDELETE "${elastic_url}:${elastic_port}/${index}?pretty"
    else
      echo "skip delete index: ${index}"
    fi
  done
done 

# 删除全部过期索引
for index in $(curl -s "${elastic_url}:${elastic_port}/_cat/indices?v" | awk '{ print $3 }' | grep -E " *-20[0-9][0-9].[0-1][0-9].[0-3][0-9]$"); do
    date=$(echo ${index: -10} | sed 's/\./-/g')
    cond=$(date +%Y-%m-%d)
    diff=$(dateDiff -d $date $cond)
    # echo -n "${index} (${diff})"
    if [ $diff -gt $save_days ]; then
      echo "curl -XDELETE \"${elastic_url}:${elastic_port}/${index}?pretty\""
      curl -XDELETE "${elastic_url}:${elastic_port}/${index}?pretty"
    else
      echo "skip delete index: ${index}"
    fi
done