#!/bin/bash

# 获取当前时间的时间戳
current_time=$(date +%s)

# 列出所有容器ID
container_ids=$(docker ps -a -q)

# 遍历所有容器
for id in $container_ids; do
    # 获取容器的最后停止时间
    finished_at=$(docker inspect --format '{{.State.FinishedAt}}' $id)
    echo "Container $id last used on $finished_at"
    
    # 如果容器从未停止过，finished_at将是空的，跳过这些容器
    if [ -z "$finished_at" ] || [ "$finished_at" == "0001-01-01T00:00:00Z" ]; then
        continue
    fi
    
    # 将Docker时间转换为时间戳
    finished_timestamp=$(date -d "$finished_at" +%s)
    
    # 计算时间差，单位是秒
    difference=$((current_time - finished_timestamp))
    
    # 定义6个月的秒数（大约）
    six_months=$((6 * 30 * 24 * 3600))

    
    # 如果时间差大于6个月，删除该容器
    if [ $difference -ge $six_months ]; then
        echo "Deleting container $id last used on $finished_at"
        docker rm $id
    fi
done
