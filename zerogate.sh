#!/bin/bash -xe

# Import job environment variables
[ -f gerrit_env ] && . gerrit_env

# Import functions
. ./lib.sh

# Configure ephemeral chef server, upload recipes and configure localhost as
# client
chef_zero
setup_knife
populate_chef_server
bootstrap_chef_client

# apply change specific to this gate
apply_gerrit_patch

# Deploy openstack
chef-client -o 'role[allinone-compute]'

# import openstack credentials
. openrc

# Add ubuntu image to glance
prepare_ubuntu_image
exerstack
