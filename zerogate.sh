#!/bin/bash -xe

# Import functions
. ./lib.sh

# Configure ephemeral chef server, upload recipes and configure localhost as
# client
chef_zero
setup_knife
populate_chef_server
configure_chef_client

# Deploy openstack
chef-client

. openrc
prepare_ubuntu_image
exerstack
