#!/bin/bash

sudo ./install_vagrant.sh
sudo ./install_virtualbox.sh
vagrant plugin install vagrant-vbguest
sed -i 's/File.exists?/File.exist?/g' /home/losylves/.vagrant.d/gems/3.3.8/gems/vagrant-vbguest-0.32.0/lib/vagrant-vbguest/hosts/virtualbox.rb