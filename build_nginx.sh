#!/bin/bash

set -eu

####################################################
# nginx: http://nginx.org/download/nginx-1.0.1.tar.gz
# nginx_upload_module http://www.grid.net.ru/nginx/download/nginx_upload_module-2.2.0.tar.gz
# NOTICE: before run this script, do following steps
# copy nginx int script to /etc/init.d/
# sudo chmod +x /etc/init.d/nginx
# sudo /usr/sbin/update-rc.d -f nginx defaults
####################################################

BUILD_TIME=`/bin/date +%Y%m%d%H%M%S`

WORKSPACE=/home/mifan/workspace
CONFIG_FILE=/usr/local/nginx/conf/nginx.conf

NGINX_VERSION=1.0.4
INSTLL_LOCATION=/usr/local/nginx-$NGINX_VERSION-$BUILD_TIME
LINK_LOCATION=/usr/local/nginx

#nginx
#NGINX_TAR=nginx-1.0.3.tar.gz
NGINX_SOURCE=nginx-$NGINX_VERSION


#nginx_upload_module
#NGINX_UPLOAD_MODULE_TAR=nginx_upload_module-2.2.0.tar.gz
NGINX_UPLOAD_MODULE_SOURCE=nginx_upload_module-2.2.0

echo "change workspace to $WORKSPACE"
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


#extract check

#libgeoip-dev for geo
dpkg -s libgeoip-dev || apt-get -y install libgeoip-dev

#nginx required lib
dpkg -s libpcre3-dev || apt-get -y install libpcre3-dev
dpkg -s libpcre3-dev || apt-get -y install libpcre3-dev
dpkg -s libssl-dev   || apt-get -y install libssl-dev
dpkg -s zlib1g-dev   || apt-get -y install zlib1g-dev

#add a requrie lib for the ruby/rvm(not really need for nginx)
#ubuntu already installed libreadline6-dev as default, 
#  but why still require libreadline5-dev??
dpkg -s libreadline5-dev || apt-get -y install libreadline5-dev
dpkg -s libmysqlclient-dev || apt-get -y install libmysqlclient-dev


# check depepdence for nginx / rails
dpkg -s imagemagick || apt-get -y install imagemagick


cd $WORKSPACE/$NGINX_SOURCE

./configure --with-http_geoip_module \
            --with-http_ssl_module \
            --with-http_flv_module \
            --with-http_gzip_static_module \
            --add-module=$WORKSPACE/$NGINX_UPLOAD_MODULE_SOURCE \
            --prefix=$INSTLL_LOCATION

make

make install

if [ -f $CONFIG_FILE ] ; then
  cp -f $CONFIG_FILE  $INSTLL_LOCATION/conf
  echo "copied nginx config file."
fi

/etc/init.d/nginx stop
echo "stop nginx service."

[[ -d $LINK_LOCATION ]] && rm -rf $LINK_LOCATION
ln -s  $INSTLL_LOCATION $LINK_LOCATION
echo "ln nginx to work directory."


/etc/init.d/nginx start
echo "start nginx service."



