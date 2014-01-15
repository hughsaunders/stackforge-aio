install_package(){
    apt-get -y install $@
}

git_clone(){
    install_package git
    git clone $1
}

setup_ssh(){
    # under sudo, ~ expands to non-sudo user dir
    user=$(whoami)
    mkdir -p $HOME/.ssh
    [ -f $HOME/.ssh/id_rsa ] || ssh-keygen -N '' -f ~/.ssh/id_rsa
    cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

    # Jenkins mangles ssh config file? 
    sed -ie 's/PermitRootLogin no//' /etc/ssh/sshd_config
    /etc/init.d/ssh restart

    ssh $user@localhost date
}

setup_sudo(){
    grep -F '#includedir /etc/sudoers.d' /etc/sudoers || {
        cp /etc/sudoers{,.bak}
        sed -i -e '$a#includedir /etc/sudoers.d' /etc/sudoers
    }
}

chef_zero(){
   # Install chef-zero server
   install_package ruby1.9.3 build-essential screen
   which chef-zero || gem install chef-zero
   screen -x chef-zero -X quit >/dev/null ||:
   screen -d -m -S chef-zero chef-zero
}

setup_knife(){
   # Install chef client
   which knife >/dev/null \
       || curl -L https://www.opscode.com/chef/install.sh | sudo bash

   # Configure knife
   mkdir -p ~/.chef

   # Chef-zero has not auth, but knife still requires a cert to
   # sign requests with.
   # NO I DON'T care that this private key is public on github.
   cat > ~/.chef/no_auth_but_still_need_a_random_pem.pem <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1FOIpA7UOJalAj2FgfMpypkhbp3SGSdiTWgHZ6fd3XJlySSA
ZFnpJubbF8/5e1ZYkYgKcBt7VESaVlzNe57pK2P3cbILSD9Rrx8q9pC+JKoXHIAb
FQZar3BbYbV19437VhplT+MnE+ndctpFXyoz5ADBIsYN3Tjd0NmA6WjVWsZ0xuuX
EtL6SwdWuEwErg9XS50BgPNRmER24LZlTFUQEdckYdLX04kLf4379jtpPFKKWaeH
vSmLvyDxAkr13owJY8QmMHxLug93wJU6uq1ZjQ8SSzQD7mNoZ80OlnJnFS9LLtVK
melPe7HGA0qfirBUXV/oexsV6MB+vC/SbcTlhwIDAQABAoIBAF12/BJD2NWkMrTe
whNnKAFgESBxZpfeB17NqVzOv1KI1heJ8t652XFfdBhyW38YjlpZyUZ6QnrgzBOy
PF3roPaRxc4Nsvu1q85r6Oyq4JihKxVHqyRBLNBHpGJJj8lOfdH0Qp68/mm8q9ew
D5OJr1fxoRMeneHA85vI8v9MP4b6Qg5ijr3JwkrvOhcI6VBxnXqQdRsjN9Q2J5C/
1jpDEtdf8uwf8HvwFqBER3BwEvOQOL7ZFjpoJU/RfeeIKfb2u/hjiH4fyKOPxnDx
Grg7Kdx11KuQawN4PRlhp1FX8w1mhBRB+mHceEl6M3wMeXrLxHBWx4UfER7nBGT+
OfESVskCgYEA64tvAdwM30k8BwYiCHJSzu5aQPDv4hfJ13edUPo0hroWLc8lKNgG
06+tiyujafiQy1zkutM1kqTtbO2euN1EHcYGSjoILLhsQcrexBTtdKI75LtVTWsi
LAz1gj3jw/b/6vU3Oq7Ps8TplknLZZDWOds5AK2/pe4IJdoMUDYRZSsCgYEA5sPq
bi8X9OWUbTwG91l/8W/wzj/hVXiifFnd8dPXbKZcEwxdsJSxHGpchDyCy0/VH6hm
ODGR8BrJ5Mc7CjFKczKfI6OtKfipl0yHcbp4jpZnA6E8NgDjQdwnLy4VuCnXFhYo
QcXSkn6djFaQPeDIBEUN0g2rUTAGFDfGLv8cSxUCgYBmjLVO1PRRvnvA/x2QGd4N
s95diciW4g6BndVDLTvzME95sEcYaj1GqqTfA6fI+mxn7dCzukMHzoCEPUwuZj9C
yzVv2aY3ei+/0Uh9jDL55aw34Iu6AhvFm/rDsphYeFBhhlN+XB+Xv/KG+Sfx10Y9
uEEwF3VqE6E+gZl8zp1yMwKBgQC6FeJFV9SJt1gpfe5gJ9v0ZcBZkUm0EsN0Y0OG
br2Y783vzlj+u+jWcS6JtAIE0Subi8BiMBbu96s2wTHq1jSjEH8jziklX0/ioePW
4fe1g7MuSiazpaOcyFsQwKjjCVpYhSWRZGSZnWCOen92ZnzkdIrgiAVOQtukEhXO
cAnwwQKBgQCltwQedsEKV27qA16cSX0XCDORz0uEv+X+46FgBCca0X5owd+ElRTh
/z4YvwoALX6oC3d9ACgEzEqKEl8n7R1efAPzBpFhxBrlDvO2pWcG1TzHflk+I0y6
V6RZ+seOD8FXtO7572Km4Lsixp6k4WXNIPhIotPx+bvrZC+L5co1UA==
-----END RSA PRIVATE KEY-----
EOF

   cat > ~/.chef/knife.rb <<EOF
chef_server_url   'http://127.0.0.1:8889'
node_name         '$HOSTNAME'
client_key        '~/.chef/no_auth_but_still_need_a_random_pem.pem'
EOF

    setup_ssh
}

populate_chef_server(){
    git_clone https://github.com/stackforge/openstack-chef-repo
    which berks || gem install berkshelf
    pushd openstack-chef-repo
    rm Berksfile.lock
    berks install
    berks upload
    knife role from file roles/*.rb
    cat > env.rb <<EOF
name "example"
override_attributes(
  "mysql" => {
    "allow_remote_root" => true,
    "root_network_acl" => "%"
  },
  "openstack" => {
    "developer_mode" => true,
    "compute" => {
        "libvirt" => {
            "virt_type" => "qemu"
        }
    }
  },
   "glance" => {
     "images" => ["precise","cirros"],
     "image" => {
       "cirros" => "http://hypnotoad/cirros-0.3.0-x86_64-disk.img",
       "precise" => "http://hypnotoad/precise-server-cloudimg-amd64.tar.gz"
     }
   },
  "osops_networks" => {
     "public" => "10.0.111.0/24",
     "management" => "10.0.111.0/24",
     "nova" => "10.0.111.0/24"
   },
   "nova" => {
     "network" => {
       "fixed_range" => "192.168.100.0/24",
       "public_interface" => "eth0"
     },
     "networks" => [
       {
         "label" => "public",
         "ipv4_cidr" => "192.168.100.0/24",
         "num_networks" => "1",
         "network_size" => "255",
         "bridge" => "br100",
         "bridge_dev" => "eth1",
         "dns1" => "8.8.8.8",
         "dns2" => "8.8.4.4"
       }
     ]
   }
  )
EOF
    knife environment from file env.rb
    popd
}

store_env_vars(){
    cat >gerrit_env <<EOF
GERRIT_PROJECT="$GERRIT_PROJECT"
GERRIT_REFSPEC="$GERRIT_REFSPEC"
EOF
}

apply_gerrit_patch(){
    GERRIT_REPO="https://review.openstack.org/${GERRIT_PROJECT}"
    PROJECT_SHORT=$(basename $GERRIT_PROJECT)
    git clone $GERRIT_REPO
    pushd $PROJECT_SHORT
    git fetch $GERRIT_REPO $GERRIT_REFSPEC
    git checkout FETCH_HEAD
    popd
    knife cookbook upload --force -o . $PROJECT_SHORT
}

bootstrap_chef_client(){
    env=${1:-example}
    host=${2:-localhost}
    mkdir -p /etc/chef
    cp ~/.chef/no_auth_but_still_need_a_random_pem.pem /etc/chef/validation.pem
    knife bootstrap -E $env $host
}

prepare_ubuntu_image(){
    wget --no-verbose http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img
    glance image-create --name=precise --disk-format=qcow2 --container-format=ovf --is-public=True <precise-server-cloudimg-amd64-disk1.img
    nova flavor-create small 10 256 30 1
}

prepare_cinder_lvm(){
    install_package lvm2
    truncate cinder.img --size 50G
    losetup -f cinder.img
    loopdev=$(losetup --show -f cinder.img)
    vgcreate cinder-volumes $loopdev
}


exerstack(){
    git_clone https://github.com/rcbops/exerstack
    pushd exerstack
    export DEFAULT_IMAGE_NAME="precise"
    ./exercise.sh havana cinder-cli.sh glance.sh keystone.sh nova-cli.sh
    popd
}
