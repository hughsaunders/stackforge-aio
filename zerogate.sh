#!/bin/bash -xe

# Import job environment variables
[ -f gerrit_env ] && . gerrit_env

# Import functions
. ./lib.sh
setup

# Configure ephemeral chef server, upload recipes and configure localhost as
# client
setup_sudo

# Get cookbooks, including gerrit patch
get_parent_repo
[ -z "$GERRIT_PROJECT" ] || get_gerrit_patch

chef_zero
setup_knife
populate_chef_server
[ -z "$GERRIT_PROJECT" ] || upload_patched_cookbook

# should be done before OS deploy so VG is detected.
prepare_cinder

bootstrap_chef_client


# Deploy openstack
chef-client -o 'role[allinone-compute]'

# import openstack credentials
. /root/openrc

# Create flavor With low RAM and some disk.
create_sensible_flavor

# Create lvm vol group for cinder
exerstack
