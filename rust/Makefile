CARGO := $(shell which cargo)
INSTALL_DIR = "."

all:
	sed 's~<INSTALL_DIR>~$(INSTALL_DIR)~' Cargo.toml > Cargo.toml.new
	mv Cargo.toml.new Cargo.toml
	$(CARGO) build

install:

test:
	cp "$(INSTALL_DIR)/user.crt" .
	cp /usr/local/etc/intecture/auth_pub.crt auth.crt
	target/debug/test
