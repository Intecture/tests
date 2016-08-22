Vagrant.configure("2") do |config|
  config.vm.define "centos" do |centos|
    centos.vm.box = "centos/6"
    centos.vm.network :private_network, ip: "192.168.178.42"
    centos.ssh.forward_agent = true
    centos.vm.synced_folder "../", "/intecture", type: "nfs"
    centos.vm.provision "shell", path: "provision.sh", args: "centos"
  end

  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu/trusty64"
    ubuntu.vm.network :private_network, ip: "192.168.178.43"
    ubuntu.ssh.forward_agent = true
    ubuntu.vm.synced_folder "../", "/intecture", type: "nfs"
    ubuntu.vm.provision "shell", path: "provision.sh", args: "ubuntu"
  end

  config.vm.define "debian" do |debian|
    debian.vm.box = "debian/jessie64"
    debian.vm.network :private_network, ip: "192.168.178.44"
    debian.ssh.forward_agent = true
    debian.vm.synced_folder "../", "/intecture", type: "nfs"
    debian.vm.provision "shell", path: "provision.sh", args: "debian"
  end

  config.vm.define "fedora" do |fedora|
    fedora.vm.box = "box-cutter/fedora22"
    fedora.vm.network :private_network, ip: "192.168.178.45"
    fedora.ssh.forward_agent = true
    fedora.vm.synced_folder "../", "/intecture", type: "nfs"
    fedora.vm.provision "shell", path: "provision.sh", args: "fedora"
  end

  config.vm.define "freebsd" do |freebsd|
    freebsd.vm.guest = :freebsd
    freebsd.vm.box = "freebsd/FreeBSD-10.2-STABLE"
    freebsd.vm.network :private_network, ip: "192.168.178.46"
    freebsd.vm.synced_folder "../", "/intecture", id: "vagrant-in", type: "nfs"
    freebsd.vm.synced_folder ".", "/vagrant", id: "vagrant-root", type: "nfs"
    freebsd.vm.provision "shell", path: "provision.sh", args: "freebsd"
    freebsd.vm.base_mac = "080027D14C66"
    freebsd.ssh.shell = "sh"
    freebsd.vm.provider :virtualbox do |vb, override|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cpus", "1"]
      vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
    end
  end

  #config.vm.define "osx" do |osx|
  #  osx.vm.box = "jhcook/osx-yosemite-10.10"
  #  osx.vm.network :private_network, ip: "192.168.178.47"
  #  osx.ssh.forward_agent = true
  #  osx.vm.synced_folder "./", "/intecture", type: "nfs"
  #  osx.vm.provision "shell", inline: "brew install git php56"
  #  osx.vm.provision "shell", path: "install.sh", args: "-y dev-php"
  #end
end
