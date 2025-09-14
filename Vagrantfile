Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.boot_timeout = 600
  config.ssh.insert_key = false

  # -------------------------
  # Server VM
  # -------------------------
  config.vm.define "server" do |server|
    server.vm.hostname = "server.local"
    server.vm.network "private_network", ip: "192.168.56.10"
    server.vm.provider :virtualbox do |vb|
      vb.name   = "server.local"
      vb.memory = 1024
      vb.cpus   = 1
    end
    server.vm.provision "shell", inline: <<-'SHELL'
      set -e
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y python3

      # Create a systemd unit to serve /vagrant on port 8000
      cat >/etc/systemd/system/vagrant-http.service <<'UNIT'
[Unit]
Description=Python http.server serving /vagrant on port 8000
After=network-online.target vagrant.mount
Wants=network-online.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/vagrant
ExecStart=/usr/bin/python3 -m http.server 8000 --directory /vagrant
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

      systemctl daemon-reload
      systemctl enable --now vagrant-http
      systemctl --no-pager --full status vagrant-http || true
    SHELL
  end

  # -------------------------
  # Client VM
  # -------------------------
  config.vm.define "client" do |client|
    client.vm.hostname = "client.local"
    client.vm.network "private_network", ip: "192.168.56.11"
    client.vm.provider :virtualbox do |vb|
      vb.name   = "client.local"
      vb.memory = 1024
      vb.cpus   = 1
    end
    client.vm.provision "shell", inline: <<-'SHELL'
      set -e
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y curl

      echo "Waiting for server at http://192.168.56.10:8000 ..."
      for i in $(seq 1 120); do
        if curl -fsS http://192.168.56.10:8000 >/dev/null; then
          echo "Server is reachable."
          exit 0
        fi
        sleep 2
      done
      echo "WARNING: Server not reachable yet; try manually."
    SHELL
  end
end
