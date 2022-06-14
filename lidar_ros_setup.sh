#!/bin/bash

# Exit on error
set -e
set -x

if grep -q Raspberry /proc/cpuinfo; then
    echo "Running on a Raspberry Pi"
else
    echo "Not running on a Raspberry Pi. Use at your own risk!"
fi

echo "Update sources list"
# Chinese users, please uncomment the following 3 lines:
#ARCHIVE_SOURCE='deb https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ buster main ui'
#sudo cp /etc/apt/sources.list.d/raspi.list /etc/apt/sources.list.d/raspi.list.orig
#echo "$ARCHIVE_SOURCE" | sudo tee /etc/apt/sources.list.d/raspi.list > /dev/null

# If you are a user outside China please uncomment one of the following SOURCE lines:
# Install any source from the following URL: https://www.raspbian.org/RaspbianMirrors
# Example:
# [1]
#SOURCE='deb http://mirror.nus.edu.sg/raspbian/raspbian/ buster main contrib non-free rpi'
# [2]
#SOURCE='deb http://ftp.jaist.ac.jp/raspbian/ buster main contrib non-free rpi'
# [3]
SOURCE='deb http://mirror.ox.ac.uk/sites/archive.raspbian.org/archive/raspbian/ buster main contrib non-free rpi'
# [4]
#SOURCE='deb http://mirrors.ocf.berkeley.edu/raspbian/raspbian/ buster main contrib non-free rpi'
# [5]
#SOURCE='deb http://reflection.oss.ou.edu/raspbian/raspbian/ buster main contrib non-free rpi'
# [6]
#SOURCE='deb http://mirror.liquidtelecom.com/raspbian/raspbian/ buster main contrib non-free rpi'
# [7]
#SOURCE='deb http://mirrordirector.raspbian.org/raspbian/ buster main contrib non-free rpi'
# [8]
#SOURCE='deb https://archive.raspbian.org/raspbian/ buster main contrib non-free rpi'
# [9]
#SOURCE='deb https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main contrib non-free rpi'
# [10]
#SOURCE='deb http://mirrors.aliyun.com/raspbian/raspbian/ buster main contrib non-free rpi'
# [11]
#SOURCE='deb http://ftp.cse.yzu.edu.tw/Linux/raspbian/raspbian/ buster main contrib non-free rpi'

# Chinese users, please uncomment the following source:
#SOURCE='deb http://mirrors.ustc.edu.cn/raspbian/raspbian/ buster main contrib non-free rpi'

sudo cp /etc/apt/sources.list /etc/apt/sources.list.orig
echo "$SOURCE" | sudo tee /etc/apt/sources.list > /dev/null

echo "STEP1: Install Dependencies and Download ROS source packages"

# Where will the output go?
WORK_DIR=~/ros_catkin_ws

BUILD_DEPS="build-essential cmake"
PYTHON_DEPS="python-rosdep python-rosinstall-generator python-wstool python-rosinstall"

echo "Adding ros repo https://www.ros.org/"
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

sudo apt update
sudo apt install -y $BUILD_DEPS $PYTHON_DEPS
pwd
echo "Press space bar to continue"
read -r -s -d ' '

echo "STEP2: Initialising ROS"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
fi
rosdep update
pwd
echo "Press space bar to continue"
read -r -s -d ' '

echo "STEP3: Install Melodic Desktop"
if [ ! -d "$WORK_DIR" ]; then
    mkdir "$WORK_DIR"
fi
cd $WORK_DIR

rosinstall_generator desktop --rosdistro melodic --deps --wet-only --tar > melodic-desktop-wet.rosinstall
if [ ! -d "$WORK_DIR"/src ]; then
    wstool init -j8 src melodic-desktop-wet.rosinstall
else
    #echo "If wstool init fails or is interrupted, you can resume the download by running:"
    wstool update -j4 -t src
fi
pwd
echo "Press space bar to continue"
read -r -s -d ' '

echo "STEP4: Fix the Issues"
# Install compatible version of Assimp (Open Asset Import Library) to fix collada_urdf dependency problem.
if [ ! -d "$WORK_DIR"/external_src ]; then
    mkdir "$WORK_DIR"/external_src
fi

cd "$WORK_DIR/external_src"

wget https://github.com/assimp/assimp/archive/refs/tags/v5.0.1.zip
unzip -o v5.0.1.zip
cd assimp-5.0.1
cmake .
make
sudo make install
pwd
echo "Press space bar to continue"
read -r -s -d ' '

echo "Install OGRE for rviz"
sudo apt install -y libogre-1.9-dev
pwd
echo "Press space bar to continue"
read -r -s -d ' '

cd $WORK_DIR

echo "Install other deps using rosdep"
rosdep install -y --from-paths src --ignore-src --rosdistro melodic -r --os=debian:buster
pwd
echo "Press space bar to continue"
read -r -s -d ' '

echo "STEP5: Build and Source the Installation"
cd $WORK_DIR

sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/melodic -j2
pwd
echo "Press space bar to continue"
read -r -s -d ' '

echo "Update bashrc"
if ! grep -xq 'source /opt/ros/melodic/setup.bash' ~/.bashrc; then
	echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc
fi

# *************************
# End of ROS build
# reboot and test with:
# roscore
