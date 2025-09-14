### 1.How to bring up the environment?
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
```
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-144-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sun Sep 14 04:05:44 PM UTC 2025

  System load:           0.78
  Usage of /:            16.4% of 30.34GB
  Memory usage:          20%
  Swap usage:            0%
  Processes:             151
  Users logged in:       0
  IPv4 address for eth0: 10.0.2.15
  IPv6 address for eth0: fd17:625c:f037:2:a00:27ff:fe7d:1a4a
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
