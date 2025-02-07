#!/bin/bash

# define the directory SCORCH is cloned into
BASEDIR=$PWD

echo -e """
###############################################################
# installing development tools for compiling GWOVina & MGLTools
###############################################################
"""

# install dependencies for xgboost, GWOVina & MGLTools
if [[ "$OSTYPE" == "darwin"* ]]; then
    # dependencies for mac
    echo -e "\nDetected Max OS X!"
    echo -e "Due to GWOVina and MGLTools incompatibilities, please use the SCORCH Docker \nimage to run SCORCH on Mac OS!"
    exit

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "\nDetected Linux OS!"
    # check if debian or redhat linux distro
    installcommand=$(command -v yum)

    # if yum doesn't exist, assume debian
  	if [ -z "$installcommand" ]; then
            echo -e "\nDetected Debian! Using apt-get to install packages..."
            yes | sudo apt-get update
            # install dependencies for debian with apt-get
            yes | sudo apt-get install build-essential libboost-all-dev
  	else
            echo -e "\nDetected RedHat! Using yum to install packages..."
            # install dependencies for redhat with yum
            yes | sudo yum update
            yes | sudo yum install boost-devel
        		yes | sudo yum groupinstall 'Development Tools' --setopt=group_package_types=mandatory,default,optional
  	fi
fi

echo -e """
###############################################################
# verifying conda install or installing miniconda3 if not found
###############################################################
"""

# check if conda is installed, and install miniconda3 if not

# if conda is not a recognised command then download and install
if ! command -v conda &> /dev/null; then
    echo -e "\nNo conda found - installing..."
    cd utils && mkdir miniconda3
    # if linux then get linux version
    if [[ "$OSTYPE" == "linux"* ]]; then
    	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda3/miniconda.sh --no-check-certificate
    # if mac then get mac version
    fi

    # install miniconda3
    cd miniconda3 && chmod -x miniconda.sh
    cd $BASEDIR && bash utils/miniconda3/miniconda.sh -b -u -p utils/miniconda3

    # remove the installer
    rm -f utils/miniconda3/miniconda.sh

    # define conda installation paths
    CONDA_PATH="utils/miniconda3/bin/conda"
    CONDA_BASE=$BASEDIR/utils/miniconda3
    CONDA_SH="utils/miniconda3/etc/profile.d/conda.sh"
else
    echo -e "\nFound existing conda install!"
    # if conda not installed then find location of existing installation
    CONDA_PATH=$(which conda)
    CONDA_BASE=$(conda info --base)
    CONDA_SH=$CONDA_BASE/etc/profile.d/conda.sh
fi

echo -e """
###############################################################
# installing the SCORCH conda environment
###############################################################
"""
# source the bash files to enable conda command in the same session
if test -f ~/.bashrc; then
    source ~/.bashrc
fi

if test -f ~/.bash_profile; then
    source ~/.bash_profile
fi

# initiate conda
$CONDA_PATH init bash

# source the conda shell script once initiated
source $CONDA_SH

# configure conda to install environment quickly and silently
$CONDA_PATH config --set auto_activate_base false
conda config --set channel_priority strict

# create the conda environment
conda env create -f scorch.yml python=3.6.9



# if linux system, install GWOVina 1.0
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    echo -e """
    ###############################################################
    # building GWOVina 1.0 in utils/
    ###############################################################
    """
    cd utils && tar -xzvf gwovina-1.0.tar.gz
    cd gwovina-1.0/build/$PLATFORM/release
    rm Makefile
    echo -e "BASE=/usr/bin\n"\
    "BOOST_VERSION=1_59\n"\
    "BOOST_INCLUDE=/usr/bin/include\n"\
    "C_PLATFORM= -pthread\n"\
    "GPP=g++\n"\
    "C_OPTIONS= -O3 -DNDEBUG\n"\
    "BOOST_LIB_VERSION=\n\n"\
    "include ../../makefile_common\n"\ > Makefile
    make -j2
fi

# return to the base directory
cd $BASEDIR

echo -e """
###############################################################
# building MGLTools 1.5.6 in utils/
###############################################################
"""

# download the correct install tarball for user OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM='linux'
    MGLFOLDER="mgltools_x86_64Linux2_1.5.6"
    wget https://ccsb.scripps.edu/download/548/ -O utils/mgltools1-5-6.tar.gz --no-check-certificate
fi

# build MGLTools 1.5.6 in utils folder
cd utils && tar -xzvf mgltools1-5-6.tar.gz
mv $MGLFOLDER MGLTools-1.5.6
cd MGLTools-1.5.6 && ./install.sh

# notify user setup is complete

echo -e "\nSCORCH setup complete!"
