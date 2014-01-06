#!/bin/bash -xe

# Import functions
. ./lib.sh

chef_zero
knife
populate_chef_server
configure_chef_client
exerstack
