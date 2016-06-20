#!/bin/bash

    if [ -z $BUILD_DIR];then
        BUILD_DIR=./
    fi
    MAJOR_VERSION=1
    MINOR=8
    REV=91
    # snippet from https://gist.github.com/P7h/9741922
    ## Latest JDK8 version released on 19th April, 2016: JDK8u91
    BASE_URL_8=http://download.oracle.com/otn-pub/java/jdk/8u91-b14/jdk-8u91

    JDK_VERSION=${BASE_URL_8##*/}
    ##JDK_VERSION=`echo $BASE_URL_8 | rev | cut -d "/" -f1 | rev`
    PLATFORM=-linux-x64.tar.gz

    wget -c -O "$JDK_VERSION$PLATFORM" --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "${BASE_URL_8}${PLATFORM}"

    tar -xzf $JDK_VERSION$PLATFORM -C $BUILD_DIR

    if [ "$?" == "0" ]; then
        echo "Setting JAVA_HOME to $HOME/$JDK_VERSION$PLATFORM"                
        export JAVA_HOME=$HOME/jdk$MAJOR.$MINOR.0_$REV
    fi
