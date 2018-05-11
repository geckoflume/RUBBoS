#!/bin/bash
#Script made for Ubuntu 14.04 LTS amd64
#Credits to Michael Mior from University of Waterloo (https://github.com/michaelmior/RUBBoS.git)
#Result content will be in rubbosResult.txt

if [[ $# -ne 1 ]] || [[ "$1" != "install" && "$1" != "run" ]]; then
	echo "Syntax : $0 install or $0 run"
	exit 1
fi

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

BASEDIR=$(pwd)

case $1 in
	install)
		echo -e "\033[0;32mInstalling RUBBoS...\033[0m"
		#Installing required packages
		sudo add-apt-repository ppa:ondrej/php -y
		sudo add-apt-repository ppa:openjdk-r/ppa -y
		sudo apt-get -q update
		#MySQL Username:root
		#MySQL Password:1a2b3c
		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password 1a2b3c'
		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password 1a2b3c'
		sudo apt-get -y -q install git openjdk-8-jdk sysstat apache2 libapache2-mod-php7.1 php7.1-cli mysql-server gnuplot
		export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
		#Installing RUBBoS
		sudo cp -r PHP/ /var/www/html/
		echo -e "\033[0;32mBuilding client...\033[0m"
		#Building client
		cd Client
		make
		replace "BASEDIR" "$BASEDIR" -- rubbos.properties
		echo -e "\033[0;32mDatabase setup...\033[0m"
		#Configuring MySQL database
		sudo sed -i 's/\[mysqld\]/[mysqld]\nsecure_file_priv = ""/' /etc/mysql/my.cnf
		sudo /etc/init.d/mysql restart
		#Filling database
		cd ../database
		mysql -u root -p1a2b3c < rubbos.sql
		tar -jxf database.tar.bz2
		sudo cp *.data /var/lib/mysql/rubbos/
		mysql -u root -p1a2b3c -D rubbos < load.sql
		echo -e "\033[0;32mInstallation completed successfully!\033[0m"
		exit 0
		;;
	run)
		echo -e "\033[0;32mRunning RUBBoS benchmark...\033[0m"
		#Running Browser Emulator (RUBBoS benchmark) and data analysis
		make emulator
		echo -e "\033[0;32mResult located in rubbosResult.txt\033[0m"
		#TODO:export data from benchmark analysis (bench/xxxx-xx-xx@xx:xx:xx/stat_client0.html) to rubbosResult.txt
		exit 0
esac