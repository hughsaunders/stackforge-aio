#!/bin/bash -xe

# Import functions
. ./lib.sh

chef_zero
setup_knife
populate_chef_server
configure_chef_client
chef-client
exerstack
