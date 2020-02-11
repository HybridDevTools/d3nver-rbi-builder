#!/bin/bash

# Execute post-boot setup with Ansible
cd /opt/d3nver/post-boot/
ansible-playbook playbook.yml

# Allow internet connection from inside the pods 
iptables -P FORWARD ACCEPT

exit 0