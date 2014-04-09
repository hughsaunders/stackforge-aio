#!/bin/bash


apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install git python-dev ruby1.9.3 build-essential lvm2
gem install berkshelf
