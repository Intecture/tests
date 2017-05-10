Vagrant.configure("2") do |config|
  config.vm.define "centos6" do |centos|
    centos.vm.box = "centos/6"
    centos.vm.network :private_network, ip: "192.168.178.42"
    centos.ssh.forward_agent = true
    centos.vm.synced_folder ".", "/vagrant", type: "nfs"
    centos.vm.synced_folder "../", "/intecture", type: "nfs"
    centos.vm.provision "shell", path: "provision.sh", args: "centos6"
  end

  config.vm.define "centos7" do |centos|
    centos.vm.box = "centos/7"
    centos.vm.network :private_network, ip: "192.168.178.43"
    centos.ssh.forward_agent = true
    centos.vm.synced_folder ".", "/vagrant", type: "nfs"
    centos.vm.synced_folder "../", "/intecture", type: "nfs"
    centos.vm.provision "shell", path: "provision.sh", args: "centos7"
  end

  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu/trusty64"
    ubuntu.vm.network :private_network, ip: "192.168.178.44"
    ubuntu.ssh.forward_agent = true
    ubuntu.vm.synced_folder ".", "/vagrant", type: "nfs"
    ubuntu.vm.synced_folder "../", "/intecture", type: "nfs"
    ubuntu.vm.provision "shell", path: "provision.sh", args: "ubuntu"

    # Ubuntu runs out of memory compiling syntex_syntax, which kills the build
    ubuntu.vm.provider :virtualbox do |vb, override|
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["modifyvm", :id, "--cpus", "2"]
    end
  end

  config.vm.define "debian" do |debian|
    debian.vm.box = "debian/jessie64"
    debian.vm.network :private_network, ip: "192.168.178.45"
    debian.ssh.forward_agent = true
    debian.vm.synced_folder ".", "/vagrant", type: "nfs"
    debian.vm.synced_folder "../", "/intecture", type: "nfs"
    debian.vm.provision "shell", path: "provision.sh", args: "debian"
  end

  config.vm.define "fedora" do |fedora|
    fedora.vm.box = "boxcutter/fedora24"
    fedora.vm.box_version = "3.0.4"
    fedora.vm.network :private_network, ip: "192.168.178.47"
    fedora.ssh.forward_agent = true
    fedora.vm.synced_folder ".", "/vagrant", type: "nfs"
    fedora.vm.synced_folder "../", "/intecture", type: "nfs"
    fedora.vm.provision "shell", path: "provision.sh", args: "fedora"
  end

  config.vm.define "freebsd" do |freebsd|
    freebsd.vm.guest = :freebsd
    freebsd.vm.box = "freebsd/FreeBSD-10.2-STABLE"
    freebsd.vm.network :private_network, ip: "192.168.178.48"
    freebsd.vm.synced_folder ".", "/vagrant", id: "vagrant-root", type: "nfs"
    freebsd.vm.synced_folder "../", "/intecture", id: "vagrant-in", type: "nfs"
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

  config.vm.define "macos" do |osx|
   osx.vm.box = "jhcook/macos-sierra"
   osx.vm.network :private_network, ip: "192.168.178.49"
   osx.ssh.forward_agent = true
   osx.vm.synced_folder "./", "/intecture", type: "nfs"
   osx.vm.provision "shell", path: "provision.sh", args: "macos"
  end
end
