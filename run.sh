#!/bin/bash

######################################################################
## run.sh
##
## modification:
##  0.0.1 - initial version [mifan] 
##
######################################################################

## cd to work dir (ie. one dir of this script)
cd `dirname ${0}`
echo "current working dir is [`dirname ${0}`]"


## read in the apphome file
. apphome
echo "app home: [$APP_HOME]"


#Static Variables
CURRENT_PATH=$APP_HOME/current
SHARED_PATH=$APP_HOME/shared
PID_FILE=$SHARED_PATH/pids/unicorn.pid
UNICORN_LOG=$SHARED_PATH/log/unicorn.log
SOCKET_FILE=$CURRENT_PATH/tmp/sockets/unicorn.socket


#choose rvm ree
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" && rvm use $RVM_VERSION
echo "change rvm to :[$RVM_VERSION]"

#copy config files
copy_config_files() {
  (
    if [ -f "$SHARED_PATH/config/database.yml" ] ; then
      cp -f $SHARED_PATH/config/database.yml $CURRENT_PATH/config/database.yml
      echo "[database.yml] copyed."
    fi
    if [ -f "$CURRENT_PATH/Gemfile.linode" ] ; then
      mv -f $CURRENT_PATH/Gemfile.linode $CURRENT_PATH/Gemfile
      echo "[Gemfile.yml] copyed."
    fi
    echo "config files copy finished."
  )
}


# init and update submodule
handle_git_submodule() {
  (
    if [ -f "$CURRENT_PATH/.gitmodules" ] ; then
      cd "$CURRENT_PATH"
      git submodule init
      git submodule update
      echo "git submodule init & updated."
    else
      echo "git submodule doesn't existed,ignore."
    fi
  )
}


#update bundle
update_bundle() {
  (
    cd "$CURRENT_PATH"
    bundle update
    echo "bundle updated."
  )
}

#bunlde check
check_bundle() {
  (
    cd "$CURRENT_PATH"
    bundle check
    if [ $? != 0 ] ; then
      echo "bundle check failed, update bundle."
      update_bundle
    else
      echo "bundle check passed."
    fi
  )
}



#stop unicorn if existed
stop_unicorn() {
  (
    if [ -f "$PID_FILE" ] ; then
      kill -QUIT  `cat $PID_FILE`
      echo "killed unicorn, status is [$?]."
    else
      echo "can not find pid file: [$PID_FILE]."
    fi
    sleep 1 
  )
}


#start unicorn
start_unicorn() {
  (
    cd "$CURRENT_PATH"
    #taskset -c 1,2,3 unicorn_rails -E production -D -l $SOCKET_FILE > $UNICORN_LOG 2>&1
    taskset -c 1,2,3 unicorn_rails -c $SHARED_PATH/config/unicorn.rb -E production -D
    echo $?
  )
}


#main functions

#variables
unicorn_status=1
start_count=0

copy_config_files
check_bundle
handle_git_submodule
stop_unicorn
while [ $unicorn_status != 0 ]
do
  unicorn_status=`start_unicorn`
  echo "unicorn started, status is [$unicorn_status], socket file is: [$SOCKET_FILE]"
  if [ $unicorn_status != 0 ] ; then
    echo "unicorn status is [$unicorn_status], try to update bundle and try again..."
    update_bundle
  fi

  if [ $start_count == 5 ] ; then
    echo "too many times [$start_count] attemped, please check the environment and try again, exist now."
    exit 1
  fi

  start_count=`expr $start_count "+" 1`
  echo "this is the [$start_count] times attemp start unicorn."

done
