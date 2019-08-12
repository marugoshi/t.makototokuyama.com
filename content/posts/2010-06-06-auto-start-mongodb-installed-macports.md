---
title: "MacPorts で起動した MongoDB の自動起動"
date: "2010-06-06T00:00:00+09:00"
draft: false
---
MacPorts の MongoDB パッケージには起動スクリプトが含まれていないので自分で書く必要がある。ファイルそのものを用意して置いてもいいのだけど、複数のマシンで使うことがあるので以下のようなシェルスクリプトを用意した。

{{< highlight sh "linenos=pre" >}}
#!/bin/sh

#
# MongoDB OSX Launch Item
#
# usage: sudo ./install.sh
#

# initialize
DAEMON_PATH=`which mongod`
DATA_DIR="/opt/local/var/db/mongodb"

LOG_DIR="/opt/local/var/log/mongodb"
LOG_FILE="$LOG_DIR/mongodb.log"

ITEM_FILE="/Library/LaunchDaemons/org.mongo.mongod.plist"

# be should run as root
USER_ID=`id -u`
if [ $USER_ID -ne 0 ] ; then
    echo "Current user is not root."
    echo "usage: sudo ./install.rb"
    exit 1
fi

# start
echo "Installing MongoDB Launchctl Item..."
echo "Before run this script, you should install mongodb via Macports."

# create data directory
echo "Input mongodb data directory: [$DATA_DIR]"
read data_dir
if [ "$data_dir" = "" ] ; then
    data_dir=$DATA_DIR
fi
mkdir -p $data_dir
chown root:admin $data_dir

# create log directory
echo "Input log directory: [$LOG_DIR]"
read log_dir
if [ "$log_dir" = "" ] ; then
    log_dir=$LOG_DIR
fi
mkdir -p $log_dir
chown root:admin $log_dir
touch $LOG_FILE
chown root:admin $LOG_FILE

# write launchctl item
cat << EOF > $ITEM_FILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>org.mongo.mongod</string>
	<key>RunAtLoad</key>
	<true/>
	<key>ProgramArguments</key>
	<array>
		<string>$DAEMON_PATH</string>
		<string>--dbpath</string>
		<string>$DATA_DIR</string>
		<string>--logpath</string>
		<string>$LOG_FILE</string>
	</array>
</dict>
</plist>
EOF

# finish
echo "Done."
{{< / highlight >}}

ファイルに以下を書き込んで root ユーザで実行すると `/Library/LaunchDeamons` 以下に起動スクリプトを作るようになっている。ファイルを置いただけでは自動起動しないので、以下のコマンドで登録する必要がある。

{{< highlight sh >}}
sudo launchctl load -w /Library/LaunchDaemons/org.mongo.mongod.plist
{{< / highlight >}}

Leopard で動作確認したけど、多分 Snow Leopard でも動くと思う。
