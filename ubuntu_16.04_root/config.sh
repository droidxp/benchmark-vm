#!/bin/bash

ANDROID_SDK_VERSION=6514223
ANDROID_PLATFORM=android-19
#ANDROID_EMULATOR_PACKAGE_ARM="system-images;android-19;google_apis;armeabi-v7a"
ANDROID_EMULATOR_PACKAGE_x86="system-images;${ANDROID_PLATFORM};google_apis;x86"
ANDROID_PLATFORM_VERSION="platforms;${ANDROID_PLATFORM}"
ANDROID_SDK_PACKAGES="${ANDROID_EMULATOR_PACKAGE_x86} ${ANDROID_PLATFORM_VERSION} platform-tools emulator"
#ANDROID_SDK_PACKAGES="${ANDROID_EMULATOR_PACKAGE_ARM} ${ANDROID_EMULATOR_PACKAGE_x86} ${ANDROID_PLATFORM_VERSION} platform-tools emulator"
EMULATOR_NAME_x86="Nexus-One-10"
#EMULATOR_NAME_ARM="Nexus-One-10_arm"
EMULATOR_DEVICE="pixel"

echo "******************** Configuring environment ********************"
export TZ=America/Sao_Paulo
export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#export _JAVA_OPTIONS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator
# WORKAROUND: for issue https://issuetracker.google.com/issues/37137213
export LD_LIBRARY_PATH=$ANDROID_SDK_ROOT/emulator/lib64:$ANDROID_SDK_ROOT/emulator/lib64/qt/lib
# patch emulator issue: Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
# https://doc.qt.io/qt-5/qtwebengine-platform-notes.html#sandboxing-support
export QTWEBENGINE_DISABLE_SANDBOX=1

echo "******************** Installing base libraries ********************"
dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses5 lib32z1 zlib1g:i386 && \
    apt-get install -y --no-install-recommends openjdk-8-jdk git wget unzip qt5-default nano \
    qemu-kvm libvirt-daemon-system bridge-utils virt-manager && \
	apt-get upgrade --yes && \
	apt-get dist-upgrade --yes
#libvirt-clients lib32ncurses6
	
echo "******************** Download and install Android SDK ********************"
mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
	wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
	unzip -o *tools*linux*.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
	rm *tools*linux*.zip

# sdkmanager
mkdir /root/.android/
touch /root/.android/repositories.cfg
yes Y | sdkmanager --licenses 
yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES} 

# avdmanager
echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME_x86}" --device "${EMULATOR_DEVICE}" --package "${ANDROID_EMULATOR_PACKAGE_x86}"
#RUN echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME_ARM}" --device "${EMULATOR_DEVICE}" --package "${ANDROID_EMULATOR_PACKAGE_ARM}"

# accept the license agreements of the SDK components
chmod +x ./license_accepter.sh && ./license_accepter.sh $ANDROID_SDK_ROOT && rm ./license_accepter.sh



############# BENCHMARK ############
echo "******************** Installing python 2.7 ********************"
apt-get update && \
	apt-get install -y --no-install-recommends python2.7 python-pip-whl python-setuptools python-protobuf && \
	apt-get install -y --no-install-recommends curl tree nano vim aapt apktool expect tcl-expect zipalign gnuplot 

# pip and python libraries
cd /opt && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py && \
	python2 get-pip.py && \
	pip2 install pandas numpy matplotlib && \
	pip2 install Jinja2 uiautomator	

#benchmark
echo "******************** Installing benchmark ********************"
cd /opt && if [ -d benchmark ]; then rm -Rf benchmark; fi && \ 
	git clone https://github.com/droidxp/benchmark.git
rm -Rf ./benchmark/data/instrumented
export BENCHMARK_HOME=/opt/benchmark
cd $BENCHMARK_HOME
#TODO alterar o emulador (-no-window) antes de executar

# droidbot
echo "******************** Installing droidbot ********************"
cd /opt && if [ -d droidbot ]; then rm -Rf droidbot; fi && \ 
	git clone https://github.com/honeynet/droidbot.git && \
	cd droidbot && \
	pip2 install -e . && \
	rm /opt/get-pip.py

# stoat
echo "******************** Installing Stoat ********************"
cd /opt && apt-get install -y --no-install-recommends ruby2.3 build-essential patch ruby-dev zlib1g-dev liblzma-dev && \
	gem install nokogiri && \
	git clone https://github.com/rbonifacio/Stoat.git
export STOAT_HOME=/opt/Stoat/Stoat
export PATH=$PATH:$STOAT_HOME/bin

# sapienz
echo "******************** Installing Sapienz ********************"
cd /opt && apt-get install -y --no-install-recommends libfreetype6-dev libxml2-dev libxslt1-dev python-dev && \
	git clone https://github.com/droidxp/sapienz.git && \
	cd sapienz && \
	pip install -r requirements.txt
export SAPIENZ_HOME=/opt/sapienz/

# humanoid
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


# clean up
echo "******************** Clean up!!! ********************"
apt-get remove -y unzip wget && \
	apt-get clean && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	#update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 && \
	update-alternatives --install /usr/bin/python python /usr/bin/python2.7 2

echo "SUCCESS!!!"

#TODO: eh necessario adicionar ao grupo KVM???
#echo "**************************** KVM .... tmp"
#https://www.itzgeek.com/how-tos/linux/ubuntu-how-tos/install-kvm-qemu-on-ubuntu-14-10.html
#https://blog.programster.org/set-up-ubuntu-16-04-KVM-server
#usermod -aG kvm $USER
#newgrp kvm