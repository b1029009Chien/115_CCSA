### 1.How to bring up the environment?
Perprocess: VirtualBox 7.1.4 (or latest 7.1.x release) & Vagrant 2.4.1 (or latest 2.4.x release)
This environment brings up two Ubuntu 22.04 VMs on a host-only network:

server.local — 192.168.56.10
Runs python3 -m http.server 8000 via systemd and serves files from the project folder (/vagrant).

client.local — 192.168.56.11
Has curl installed for testing the server.

use comment: `vagrant up` 
Result:
```
Bringing machine 'server' up with 'virtualbox' provider...
Bringing machine 'client' up with 'virtualbox' provider...
==> server: This machine used to live in C:/Users/emily/Desktop/test but it's now at C:/Users/emily/Desktop/115_CCSA.
==> server: Depending on your current provider you may need to change the name of
==> server: the machine to run it as a different machine.
==> server: Checking if box 'bento/ubuntu-22.04' version '202508.03.0' is up to date...
...
==> client: Depending on your current provider you may need to change the name of
==> client: the machine to run it as a different machine.
==> client: Checking if box 'bento/ubuntu-22.04' version '202508.03.0' is up to date...
...
```

### 2.How to log into the client and test the connection?
use comment: `vagrant ssh client` 

VagrantFile (test the connection):
```
for i in $(seq 1 120); do
        if curl -fsS http://192.168.56.10:8000 >/dev/null; then
          echo "Server is reachable."
          exit 0
        fi
        sleep 2
      done
```

### 3.Screenshots/logs showing a successful client request to the server?
use commend: `curl http://192.168.56.10:8000`
```
vagrant@client:~$ curl http://192.168.56.10:8000
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href=".git/">.git/</a></li>
<li><a href=".vagrant/">.vagrant/</a></li>
<li><a href="README.md">README.md</a></li>
<li><a href="Vagrantfile">Vagrantfile</a></li>
</ul>
<hr>
</body>
</html>
```
