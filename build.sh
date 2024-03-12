#!/bin/env bash

# 获取当前的执行脚本名称
arg0=${BASH_SOURCE[0]}
if [ ! $arg0 ];
then
    arg0=$0
fi

# 计算当前的目录，根据当前目录计算命令所在目录
if [ -h $arg0 ]
then
    LINK_PATH=`readlink $arg0`
else
    LINK_PATH=$arg0
fi

export CODE_PREFIX=resource
export WORK_DIR=$(cd `dirname ${LINK_PATH}`; pwd)
export INSTALL_PATH=$WORK_DIR/install
export CLONE_RESOURCE_PATH=$WORK_DIR/$CODE_PREFIX
export CMAKE_PREFIX_PATH=$INSTALL_PATH:$CMAKE_PREFIX_PATH
export PKG_CONFIG_PATH=$INSTALL_PATH/lib/pkgconfig:$PKG_CONFIG_PATH


if [ -d $INSTALL_PATH ]; then
    rm -rf $INSTALL_PATH
fi


function build_package() {
    cd $WORK_DIR/$CODE_PREFIX/$1
    if [ -d "build" ]; then
        rm -rf build
    fi
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH ..
    make -j6 && make install
    cd $WORK_DIR
}

function build_boost() {
    cd $WORK_DIR/$CODE_PREFIX/$1
    ./bootstrap.sh --prefix=$INSTALL_PATH --with-libraries=all
    ./b2 --prefix=$INSTALL_PATH
    ./b2 install --prefix=$INSTALL_PATH
    cd $WORK_DIR
}

function git_clone_repo() {
    repo_url="$1"
    repo_ver=$2
    # 使用basename命令提取仓库名
    repo_name=$CLONE_RESOURCE_PATH/$(basename -s .git $repo_url)
    echo '>>>clone '$repo_name
    if [ -d "$repo_name" ]; then
        cd $repo_name
        git submodule update --init --recursive
        cd $WORK_DIR
    else
        git clone --depth 1 --recursive $repo_url -b $repo_ver $repo_name
    fi
}

# 获取源码
function clone_source_code() {
    git_clone_repo https://github.com/boostorg/boost.git boost-1.84.0
    git_clone_repo https://gitlab.com/libeigen/eigen.git 3.4.0
    git_clone_repo https://github.com/PointCloudLibrary/pcl.git pcl-1.14.0
    git_clone_repo https://github.com/opencv/opencv.git 4.9.0
    git_clone_repo https://gitlab.kitware.com/vtk/vtk.git v9.3.0
    git_clone_repo https://github.com/flann-lib/flann.git 1.9.2
    git_clone_repo https://github.com/lz4/lz4.git v1.9.4
}


function build_kitbag() {
    # 构建 boost 库
    build_boost boost

    # 构建 lz4
    build_package lz4/build/cmake/

    # 构建 flann
    build_package flann

    # 构建 eigen
    build_package eigen

    # 构建 vtk
    build_package vtk

    # 构建 pcl
    build_package pcl
}

# 处理命令行参数
case $1 in
    "clone")
        # 执行克隆操作
        clone_source_code
        ;;
    "build")
        # 执行构建操作
        build_kitbag
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: $0 <clone|build>"
        exit 1
        ;;
esac

exit 0
