#!/bin/bash -xe

# Import job environment variables
[ -f gerrit_env ] && . gerrit_env

# Import functions
. ./lib.sh
setup

# Configure ephemeral chef server, upload recipes and configure localhost as
# client
setup_sudo
chef_zero
setup_knife
populate_chef_server

# should be done before OS deploy so VG is detected.
prepare_cinder

bootstrap_chef_client

# apply change specific to this gate
apply_gerrit_patch

# Deploy openstack
chef-client -o 'role[allinone-compute]'

# import openstack credentials
. /root/openrc

# Create flavor With low RAM and some disk.
create_sensible_flavor

# Create lvm vol group for cinder
exerstack
