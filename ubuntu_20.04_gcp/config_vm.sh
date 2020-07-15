#!/bin/bash

SCRIPT_DIR=~/script

function base(){		
	echo "******************** Installing base libraries ********************"
	sudo apt-get update 
	sudo apt-get install -y --no-install-recommends openjdk-8-jdk git wget unzip qt5-default nano python2.7 python-pip-whl python-setuptools python-protobuf curl tree nano vim aapt apktool expect tcl-expect zipalign gnuplot
	sudo apt-get upgrade --yes
	sudo apt-get dist-upgrade --yes		
}

function android() {
	echo "******************** Install Android SDK ********************"
	EMULATOR_NAME="Nexus-One-10"
	ANDROID_SDK_VERSION=6609375
	ANDROID_EMULATOR_PACKAGE="system-images;android-19;google_apis;armeabi-v7a"
	#ANDROID_EMULATOR_PACKAGE_x86="system-images;android-19;google_apis;x86"
	ANDROID_PLATFORM_VERSION="platforms;android-19"
	ANDROID_SDK_PACKAGES="${ANDROID_EMULATOR_PACKAGE} ${ANDROID_PLATFORM_VERSION} platform-tools emulator"
	#ARG ANDROID_SDK_PACKAGES="${ANDROID_EMULATOR_PACKAGE} ${ANDROID_EMULATOR_PACKAGE_x86} ${ANDROID_PLATFORM_VERSION} platform-tools emulator"
	
	ANDROID_SDK_ROOT=/opt/android-sdk
	ANDROID_HOME=/opt/android-sdk
	JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
	
	export PATH=$JAVA_HOME/bin:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${HOME}/.local/bin:${PATH}
	
	sudo rm -Rf /opt/*
	sudo chown -R $USER:$USER /opt 
	sudo chmod -R a+rw /opt
	
	mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools
	wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip
	unzip commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools 
	rm commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip
	
	mkdir ~/.android/  
	touch ~/.android/repositories.cfg
	yes Y | sdkmanager --verbose --licenses 
	yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES} 
	
	echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME}" --device "pixel" --package "${ANDROID_EMULATOR_PACKAGE}"
	
	cd $SCRIPT_DIR
	chmod +x license_accepter.sh 
	./license_accepter.sh $ANDROID_SDK_ROOT 
}

############# BENCHMARK ############
function pip(){
	echo "******************** Installing PIP ********************"	
	cd /opt && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py	
	python2 get-pip.py 
	pip2 install pandas numpy matplotlib Jinja2 uiautomator	
}


#benchmark
function benchmark(){
	echo "******************** Installing benchmark ********************"
	cd /opt && if [ -d benchmark ]; then rm -Rf benchmark; fi
	git clone https://github.com/droidxp/benchmark.git
	rm -Rf ./benchmark/data/instrumented	
		
	#...........................................................
	#TODO >>>> alterar o emulador (-no-window) antes de executar
	#...........................................................
}


# droidbot
function droidbot(){
	echo "******************** Installing droidbot ********************"
	cd /opt && if [ -d droidbot ]; then rm -Rf droidbot; fi
	git clone https://github.com/honeynet/droidbot.git 
	cd droidbot 
	pip2 install -e . 
	rm /opt/get-pip.py
}

# stoat
function stoat(){
	echo "******************** Installing Stoat ********************"
	cd /opt 
	sudo apt-get install -y --no-install-recommends ruby2.7 build-essential patch ruby-dev zlib1g-dev liblzma-dev 
	gem install nokogiri 
	git clone https://github.com/rbonifacio/Stoat.git
	echo 'export STOAT_HOME=/opt/Stoat/Stoat' >> ~/.bashrc
	echo 'export PATH=$PATH:$STOAT_HOME/bin' >> ~/.bashrc
}

# sapienz
function sapienz(){
	echo "******************** Installing Sapienz ********************"
	cd /opt 
	sudo apt-get install -y --no-install-recommends libfreetype6-dev libxml2-dev libxslt1-dev python-dev 
	git clone https://github.com/droidxp/sapienz.git 
	cd sapienz 
	pip2 install -r requirements.txt
	echo 'export SAPIENZ_HOME=/opt/sapienz/' >> ~/.bashrc
}

# humanoid
function humanoid(){
	echo "******************** Installing Humanoid and docker ********************"
	sudo apt-get remove -y docker docker-engine docker.io containerd runc
	sudo apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update
	sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io
	if [ $(getent group docker) ]; then
		echo "group docker exists."
	else
	  	sudo groupadd -f docker 
		sudo usermod -aG docker $USER 
		newgrp docker 
	fi
	sudo systemctl enable docker
	docker pull phtcosta/humanoid:1.0
}

function environment(){
	echo "******************** Configuring environment ********************"	
	
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
	
	mkdir ~/Android
	cd ~/Android
	ln -s /opt/android-sdk/ Sdk
	
	echo 'export ANDROID_SDK_ROOT=/opt/android-sdk' >> ~/.bashrc
	echo 'export ANDROID_SDK_HOME=/opt/android-sdk' >> ~/.bashrc
	echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.bashrc	
	echo 'export BENCHMARK_HOME=/opt/benchmark' >> ~/.bashrc
	echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
	echo 'export PATH=${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${HOME}/.local/bin:${PATH}' >> ~/.bashrc
	# patch emulator issue: Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
	# https://doc.qt.io/qt-5/qtwebengine-platform-notes.html#sandboxing-support
	echo 'export QTWEBENGINE_DISABLE_SANDBOX=1' >> ~/.bashrc	
		
	source ~/.bashrc
	
	#sudo addgroup droidxp
	#sudo chgrp -R droidxp /opt	
	#sudo usermod -a -G droidxp $USER
	#sudo chmod -R a+rw /opt
	
	cd /opt/benchmark	
}

# clean up
function clean(){
	echo "******************** Clean up!!! ********************"
	sudo apt-get clean
	sudo apt-get autoremove -y 
	sudo rm -rf /var/lib/apt/lists/* /var/tmp/*	
}


#*************************************************
#******************** INSTALL ********************
base 
android
pip
benchmark 
droidbot 
stoat 
sapienz 
humanoid 
environment
clean
#*************************************************


echo "SUCCESS!!!"
