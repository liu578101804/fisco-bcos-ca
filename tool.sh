#!/bin/bash


# 判断并创建目录
funCheckAndCreateDir(){
    if [ ! -d ${outPath} ]; then
        mkdir ${outPath}
    fi
}

# 清空删除目录
funDeleteFile(){
    rm -rf $1
}

