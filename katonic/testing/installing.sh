#!/bin/bash

os=$(sudo cat /etc/os-release | grep NAME -w | awk -F '"'  '{print $2}')

if [[ "${os}" == "Ubuntu" ]]
then
	echo "ubuntu"
elif [[ "${os}" == "CentOS Linux" ]]
then
    echo "centos"
fi
