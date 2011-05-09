#!/bin/bash

set -eu

####################################################
#nginx: http://nginx.org/download/nginx-1.0.1.tar.gz
#nginx_upload_module http://www.grid.net.ru/nginx/download/nginx_upload_module-2.2.0.tar.gz
#


WORKSPACE=/home/mifan/workspace
INSTLL_LOCATION=/usr/local/nginx-1.0.1

#nginx
#NGINX_TAR=nginx-1.0.1.tar.gz
NGINX_SOURCE=nginx-1.0.1


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

#libgeoip-dev foe geo
dpkg -l libgeoip-dev || apt-get install libgeoip-dev


cd $WORKSPACE/$NGINX_SOURCE

./configure --with-http_geoip_module \
            --with-http_ssl_module \
            --with-http_flv_module \
            --with-http_gzip_static_module \
            --add-module=$WORKSPACE/$NGINX_UPLOAD_MODULE_SOURCE \
            --prefix=$INSTLL_LOCATION

make
