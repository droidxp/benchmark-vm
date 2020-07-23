FROM ubuntu:20.04

# Based on https://hub.docker.com/r/thyrlian/android-sdk/

ENV TZ America/Sao_Paulo

# install common libraries and update system
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses6 lib32z1 zlib1g:i386 && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends openjdk-8-jdk git wget unzip qt5-default sudo \
	python3 python3-setuptools python3-pip \	
	curl tree nano vim aapt apktool expect zipalign gnuplot \
	ruby2.7 build-essential patch ruby-dev zlib1g-dev liblzma-dev \
	libfreetype6-dev libxml2-dev libxslt1-dev python3-dev \
#	qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager \
	libgl1-mesa-dri libgl1-mesa-glx libcanberra-gtk-module	&& \
	gem install nokogiri && \
	apt-get upgrade --yes && \
	apt-get dist-upgrade --yes && \
	apt-get clean && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
	update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Add user
ARG SALT=123
ARG PASS=droidxp
ADD license_accepter.sh /opt/
RUN groupadd -r droidxp && \ 
	useradd -rm -d /home/droidxp -s /bin/bash -g root -G droidxp,audio,video,sudo -u 1001 -p $(openssl passwd -1 -salt $SALT $PASS) droidxp && \
	chown -R droidxp:droidxp /opt && chmod +x /opt/license_accepter.sh 

# Run as non privileged user
USER droidxp

# set some environment variables
ENV TZ America/Sao_Paulo
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV ANDROID_HOME /opt/android-sdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH ${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:/home/droidxp/.local/bin:${PATH}
# WORKAROUND: for issue https://issuetracker.google.com/issues/37137213
#ENV LD_LIBRARY_PATH ${ANDROID_SDK_ROOT}/emulator/lib64:${ANDROID_SDK_ROOT}/emulator/lib64/qt/lib
# patch emulator issue: Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
# https://doc.qt.io/qt-5/qtwebengine-platform-notes.html#sandboxing-support
#ENV QTWEBENGINE_DISABLE_SANDBOX 1

WORKDIR /opt

# download and install Android SDK
# https://developer.android.com/studio#command-tools
ARG ANDROID_SDK_VERSION=6609375
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
	wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
	unzip commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
	rm commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip
 
ARG ANDROID_PLATFORM="android-25"
ARG ANDROID_EMULATOR_PACKAGE_ARM="system-images;${ANDROID_PLATFORM};google_apis;armeabi-v7a"
ARG ANDROID_PLATFORM_VERSION="platforms;${ANDROID_PLATFORM}"
ARG ANDROID_SDK_PACKAGES="${ANDROID_EMULATOR_PACKAGE_ARM} ${ANDROID_PLATFORM_VERSION} platform-tools emulator"

# sdkmanager
RUN mkdir /home/droidxp/.android/ && \ 
	touch /home/droidxp/.android/repositories.cfg && \
	yes Y | sdkmanager --verbose --licenses && \
	yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES} 

# avdmanager
ENV EMULATOR_NAME="Nexus-One-10"
RUN echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME}" --device "pixel" --package "${ANDROID_EMULATOR_PACKAGE_ARM}"

# accept the license agreements of the SDK components
RUN /opt/license_accepter.sh $ANDROID_SDK_ROOT && rm /opt/license_accepter.sh



# BENCHMARK	
RUN pip3 install pandas numpy matplotlib Jinja2 uiautomator	

# droidbot
RUN cd /opt && \ 
	git clone https://github.com/honeynet/droidbot.git && \	
	pip3 install -e droidbot 
	
# stoat
RUN cd /opt && \
	git clone https://github.com/rbonifacio/Stoat.git
ENV STOAT_HOME /opt/Stoat/Stoat
ENV PATH $PATH:$STOAT_HOME/bin

# sapienz
#RUN cd /opt && git clone https://github.com/droidxp/sapienz.git && \
#	cd sapienz && \
#	pip2 install -r requirements.txt
#ENV SAPIENZ_HOME /opt/sapienz/

# where to find the benchmark, APKs, results, report
WORKDIR /opt/benchmark
ENV BENCHMARK_HOME /opt/benchmark
VOLUME /opt/benchmark
