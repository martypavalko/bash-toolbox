#!/bin/bash

rm /etc/netplan/50-cloud-init.yaml
truncate -s0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
cloud-init clean
truncate -s0 ~/.bash_history
truncate -s0 /root/.bash_history
truncate -s0 ~/.zsh_history
truncate -s0 /root/.zsh_history
shutdown -h
