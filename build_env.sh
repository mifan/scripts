#!/bin/bash

set -eu

BUILD_TIME=`/bin/date +%Y%m%d%H%M%S`

RESOURCES_PATH=`pwd`

WORKSPACE=/home/mifan/workspace


#nginx
NGINX_CONFIG_FILE=/usr/local/nginx/conf/nginx.conf
NGINX_VERSION=1.0.10
#NGINX_INSTLL_VERSION_LOCATION is just for check if need build nginx
NGINX_INSTLL_VERSION_LOCATION=/usr/local/nginx-$NGINX_VERSION
NGINX_INSTLL_LOCATION=/usr/local/nginx-$NGINX_VERSION-$BUILD_TIME
NGINX_LINK_LOCATION=/usr/local/nginx
NGINX_SOURCE=nginx-$NGINX_VERSION
#nginx_upload_module
NGINX_UPLOAD_MODULE_SOURCE=nginx_upload_module-2.2.0



check_workspace() {
  if [ ! -d $WORKSPACE ] ; then
    mkdir -p $WORKSPACE
  fi
}

check_install_essential() {
   dpkg -s build-essential || apt-get -y install build-essential
}



####################################################
# NOTICE: before run this script, do following steps
# copy nginx int script to /etc/init.d/
# sudo chmod +x /etc/init.d/nginx
# sudo /usr/sbin/update-rc.d -f nginx defaults
####################################################


check_nginx_dependence() {
  #libgeoip-dev for geo
  dpkg -s libgeoip-dev || apt-get -y install libgeoip-dev
  #nginx required lib
  dpkg -s libpcre3-dev || apt-get -y install libpcre3-dev
  dpkg -s libpcre3-dev || apt-get -y install libpcre3-dev
  dpkg -s libssl-dev   || apt-get -y install libssl-dev
  dpkg -s zlib1g-dev   || apt-get -y install zlib1g-dev
}

clean_nginx_build_env() {
  cd $WORKSPACE
  #clean old directorys if existed
  [[ -d $NGINX_SOURCE ]] && rm -rf $NGINX_SOURCE
  [[ -d $NGINX_UPLOAD_MODULE_SOURCE ]] && rm -rf $NGINX_UPLOAD_MODULE_SOURCE

  #download sources
  if [ ! -f $NGINX_SOURCE.tar.gz ] ; then
    wget http://nginx.org/download/$NGINX_SOURCE.tar.gz
  fi
  if [ ! -f $NGINX_UPLOAD_MODULE_SOURCE.tar.gz ] ; then
    wget http://www.grid.net.ru/nginx/download/$NGINX_UPLOAD_MODULE_SOURCE.tar.gz
  fi
    #extract sources
  tar -xzf $NGINX_SOURCE.tar.gz
  tar -xzf $NGINX_UPLOAD_MODULE_SOURCE.tar.gz
}

build_nginx() {
  cd $WORKSPACE/$NGINX_SOURCE
  ./configure --with-http_geoip_module \
              --with-http_ssl_module \
              --with-http_flv_module \
              --with-http_gzip_static_module \
              --add-module=$WORKSPACE/$NGINX_UPLOAD_MODULE_SOURCE \
              --prefix=$NGINX_INSTLL_LOCATION

  make
  make install

}


config_recycle_nginx() {

  if [ -f $NGINX_CONFIG_FILE ] ; then
    cp -f $NGINX_CONFIG_FILE  $NGINX_INSTLL_LOCATION/conf
    echo "copied nginx config file."
  else
    cp -f $RESOURCES_PATH/nginx/nginx.conf  $NGINX_INSTLL_LOCATION/conf
    echo "copied original nginx config file."
  fi


  if [ ! -f /etc/init.d/nginx ] ; then
    cp -f $RESOURCES_PATH/nginx/nginx  /etc/init.d/nginx
    echo "copied nginx config file."
    chmod +x /etc/init.d/nginx
    /usr/sbin/update-rc.d -f nginx defaults
  fi

  /etc/init.d/nginx stop
  echo "stop nginx service."

  [[ -d $NGINX_LINK_LOCATION ]] && rm -rf $NGINX_LINK_LOCATION
  ln -s  $NGINX_INSTLL_LOCATION $NGINX_LINK_LOCATION
  ln -s  $NGINX_INSTLL_VERSION_LOCATION $NGINX_LINK_LOCATION
  echo "ln nginx to work directory."

  /etc/init.d/nginx start
  echo "start nginx service."

}


check_build_nginx() {

  check_nginx_dependence
  if [ ! -d $NGINX_INSTLL_VERSION_LOCATION ] ; then
    clean_nginx_build_env
    build_nginx
  fi

}


check_install_mysql() {
  #ubuntu already installed libreadline6-dev as default, 
  #  but why still require libreadline5-dev??
  dpkg -s libreadline5-dev || apt-get -y install libreadline5-dev
  dpkg -s libmysqlclient-dev || apt-get -y install libmysqlclient-dev
  dpkg -s mysql-server || apt-get -y install mysql-server
}


check_install_additional() {
  dpkg -s imagemagick || apt-get -y install imagemagick
}



#steps for build a product server
check_workspace
check_build_essential
check_build_nginx
check_install_mysql
check_install_additional

