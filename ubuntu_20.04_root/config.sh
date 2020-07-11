#!/bin/bash

EMULATOR_NAME="Nexus-One-10"

echo "******************** Configuring environment ********************"
export TZ=America/Sao_Paulo
export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#export _JAVA_OPTIONS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
export PATH=$ANDROID_SDK_ROOT/tools/:$ANDROID_SDK_ROOT/platform-tools:$PATH
# patch emulator issue: Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
# https://doc.qt.io/qt-5/qtwebengine-platform-notes.html#sandboxing-support
export QTWEBENGINE_DISABLE_SANDBOX=1

echo "******************** Installing base libraries ********************"
apt-get update 
apt-get install -y --no-install-recommends openjdk-8-jdk git wget unzip qt5-default nano python2.7 python-pip-whl python-setuptools python-protobuf curl tree nano vim aapt apktool expect tcl-expect zipalign gnuplot
apt-get upgrade --yes
apt-get dist-upgrade --yes
	
echo "******************** Install Android SDK ********************"
rm -Rf /opt/*
unzip android-sdk.zip -d /opt
unzip android_home -d /root


############# BENCHMARK ############
echo "******************** Installing PIP ********************"

# pip and python libraries
cd /opt && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py && \
	python2 get-pip.py && \
	pip2 install pandas numpy matplotlib Jinja2 uiautomator	


#benchmark
echo "******************** Installing benchmark ********************"
cd /opt && if [ -d benchmark ]; then rm -Rf benchmark; fi && \ 
	git clone https://github.com/droidxp/benchmark.git
rm -Rf ./benchmark/data/instrumented
export BENCHMARK_HOME=/opt/benchmark
cd $BENCHMARK_HOME
#TODO alterar o emulador (-no-window) antes de executar


# droidbot
function droidbot(){
	echo "******************** Installing droidbot ********************"
	cd /opt && if [ -d droidbot ]; then rm -Rf droidbot; fi && \ 
		git clone https://github.com/honeynet/droidbot.git && \
		cd droidbot && \
		pip2 install -e . && \
		rm /opt/get-pip.py
}

# stoat
function stoat(){
	echo "******************** Installing Stoat ********************"
	cd /opt && apt-get install -y --no-install-recommends ruby2.7 build-essential patch ruby-dev zlib1g-dev liblzma-dev && \
		gem install nokogiri && \
		git clone https://github.com/rbonifacio/Stoat.git
	export STOAT_HOME=/opt/Stoat/Stoat
	export PATH=$PATH:$STOAT_HOME/bin
}

# sapienz
function sapienz(){
	echo "******************** Installing Sapienz ********************"
	cd /opt && apt-get install -y --no-install-recommends libfreetype6-dev libxml2-dev libxslt1-dev python-dev && \
		git clone https://github.com/droidxp/sapienz.git && \
		cd sapienz && \
		pip install -r requirements.txt
	export SAPIENZ_HOME=/opt/sapienz/
}

# humanoid
function humanoid(){
	echo "******************** Installing Humanoid and docker ********************"
	apt-get remove -y docker docker-engine docker.io containerd runc
	apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	apt-get update
	apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io
	if [ $(getent group docker) ]; then
		echo "group docker exists."
	else
	  	groupadd -f docker 
		usermod -aG docker $USER 
		newgrp docker 
	fi
	systemctl enable docker
	docker pull phtcosta/humanoid:1.0
}


# TOOLS 
# TODO: descomentar qdo for instalar de verdade
droidbot 
#stoat 
#sapienz 
#humanoid 


# clean up
echo "******************** Clean up!!! ********************"
apt-get clean
apt-get autoremove -y 
rm -rf /var/lib/apt/lists/* /var/tmp/*
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1

echo "SUCCESS!!!"
