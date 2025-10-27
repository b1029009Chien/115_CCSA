Live Demo Video: https://youtu.be/1rOy-jnlwb0
1. `docker node ls`
output: 
```
ID                            HOSTNAME            STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
taw6nbnfe71fuenc4271oxjh3 *   chien-VMware-Virtual-Platform   Ready     Active         Leader           28.5.1
1y0x6qik6wge5sk31tw9i0ebs     isl3080                         Ready     Active                          27.4.1
```
2. `docker stack services mcapp`
output:
```
ID             NAME        MODE         REPLICAS   IMAGE                           PORTS
siel59l1ozkt   mcapp_api   replicated   1/1        chien314832001/hw5_api:latest   
wyi3uu2et64c   mcapp_db    replicated   1/1        postgres:16                     
hs4ikrsujepq   mcapp_web   replicated   1/1        chien314832001/hw5_web:latest   *:80->80/tcp
```
3. `docker service ps mcapp_*`
output:
```
docker service ps mcapp_api
ID             NAME              IMAGE                           NODE                            DESIRED STATE   CURRENT STATE           ERROR                         PORTS
ulzu71kxufm3   mcapp_api.1       chien314832001/hw5_api:latest   chien-VMware-Virtual-Platform   Running         Running 4 minutes ago                                 
c8z7xx6ulvj4    \_ mcapp_api.1   chien314832001/hw5_api:latest   chien-VMware-Virtual-Platform   Shutdown        Failed 5 minutes ago    "task: non-zero exit (255)"   

docker service ps mcapp_db
ID             NAME         IMAGE         NODE      DESIRED STATE   CURRENT STATE           ERROR     PORTS
8fi8nhi4ovlz   mcapp_db.1   postgres:16   isl3080   Running         Running 5 minutes ago  

ID             NAME              IMAGE                           NODE                            DESIRED STATE   CURRENT STATE           ERROR                         PORTS
v698378zheht   mcapp_web.1       chien314832001/hw5_web:latest   chien-VMware-Virtual-Platform   Running         Running 5 minutes ago                                 
ij578vvjkqg5    \_ mcapp_web.1   chien314832001/hw5_web:latest   chien-VMware-Virtual-Platform   Shutdown        Failed 5 minutes ago    "task: non-zero exit (255)"  
```
4. `docker inspect`
output:
```
docker inspect mcapp_api
[
    {
        "ID": "siel59l1ozktre834v1ufvh0d",
        "Version": {
            "Index": 458
        },
        "CreatedAt": "2025-10-27T06:08:42.800013065Z",
        "UpdatedAt": "2025-10-27T06:30:03.340209889Z",
        "Spec": {
            "Name": "mcapp_api",
            "Labels": {
                "com.docker.stack.image": "chien314832001/hw5_api:latest",
                "com.docker.stack.namespace": "mcapp"
            },
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "chien314832001/hw5_api:latest@sha256:590909675c97b52e2049374c4ff643c9a6a7bf8ee79562014de67d52497a3cd9",
                    "Labels": {
                        "com.docker.stack.namespace": "mcapp"
                    },
                    "Env": [
                        "DATABASE_HOST=db",
                        "DATABASE_NAME=appdb",
                        "DATABASE_PASSWORD=password",
                        "DATABASE_URL=postgresql://postgres:password@db:5432/appdb",
                        "DATABASE_USER=postgres",
                        "POSTGRES_DB=appdb",
                        "POSTGRES_HOST=db",
                        "POSTGRES_PASSWORD=password",
                        "POSTGRES_PORT=5432",
                        "POSTGRES_USER=postgres"
                    ],
                    "Privileges": {
                        "CredentialSpec": null,
                        "SELinuxContext": null,
                        "NoNewPrivileges": false
                    },
                    "StopGracePeriod": 10000000000,
                    "DNSConfig": {},
                    "Isolation": "default"
                },
                "Resources": {},
                "RestartPolicy": {
                    "Condition": "any",
                    "Delay": 5000000000,
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "x1xqxiq44uy1g1ss2pz2ohuby",
                        "Aliases": [
                            "api"
                        ]
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "UpdateConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "RollbackConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "EndpointSpec": {
                "Mode": "vip"
            }
        },
        "PreviousSpec": {
            "Name": "mcapp_api",
            "Labels": {
                "com.docker.stack.image": "chien314832001/hw5_api:latest",
                "com.docker.stack.namespace": "mcapp"
            },
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "chien314832001/hw5_api:latest@sha256:590909675c97b52e2049374c4ff643c9a6a7bf8ee79562014de67d52497a3cd9",
                    "Labels": {
                        "com.docker.stack.namespace": "mcapp"
                    },
                    "Env": [
                        "DATABASE_HOST=db",
                        "DATABASE_NAME=appdb",
                        "DATABASE_PASSWORD=password",
                        "DATABASE_URL=postgresql://postgres:password@db:5432/appdb",
                        "DATABASE_USER=postgres",
                        "POSTGRES_DB=appdb",
                        "POSTGRES_HOST=db",
                        "POSTGRES_PASSWORD=password",
                        "POSTGRES_PORT=5432",
                        "POSTGRES_USER=postgres"
                    ],
                    "Privileges": {
                        "CredentialSpec": null,
                        "SELinuxContext": null,
                        "NoNewPrivileges": false
                    },
                    "Isolation": "default"
                },
                "Resources": {},
                "Placement": {
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "x1xqxiq44uy1g1ss2pz2ohuby",
                        "Aliases": [
                            "api"
                        ]
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "EndpointSpec": {
                "Mode": "vip"
            }
        },
        "Endpoint": {
            "Spec": {
                "Mode": "vip"
            },
            "VirtualIPs": [
                {
                    "NetworkID": "x1xqxiq44uy1g1ss2pz2ohuby",
                    "Addr": "10.0.1.2/24"
                }
            ]
        }
    }
]

docker inspect mcapp_db
[
    {
        "ID": "wyi3uu2et64c9y8pu7urpepfq",
        "Version": {
            "Index": 460
        },
        "CreatedAt": "2025-10-27T06:08:49.930497876Z",
        "UpdatedAt": "2025-10-27T06:30:09.644345984Z",
        "Spec": {
            "Name": "mcapp_db",
            "Labels": {
                "com.docker.stack.image": "postgres:16",
                "com.docker.stack.namespace": "mcapp"
            },
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "postgres:16@sha256:4eb532412200f7fbbf15d62ee0d96e020a9eae9eaed76066692474a7371c4d83",
                    "Labels": {
                        "com.docker.stack.namespace": "mcapp"
                    },
                    "Env": [
                        "POSTGRES_DB=appdb",
                        "POSTGRES_PASSWORD=password",
                        "POSTGRES_USER=postgres"
                    ],
                    "Privileges": {
                        "CredentialSpec": null,
                        "SELinuxContext": null,
                        "NoNewPrivileges": false
                    },
                    "Mounts": [
                        {
                            "Type": "volume",
                            "Source": "mcapp_dbdata",
                            "Target": "/var/lib/postgresql/data",
                            "VolumeOptions": {
                                "Labels": {
                                    "com.docker.stack.namespace": "mcapp"
                                }
                            }
                        }
                    ],
                    "StopGracePeriod": 10000000000,
                    "DNSConfig": {},
                    "Isolation": "default"
                },
                "Resources": {},
                "RestartPolicy": {
                    "Condition": "on-failure",
                    "Delay": 5000000000,
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Constraints": [
                        "node.labels.role == db"
                    ],
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "arm64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "386",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "ppc64le",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "riscv64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "s390x",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "x1xqxiq44uy1g1ss2pz2ohuby",
                        "Aliases": [
                            "db"
                        ]
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "UpdateConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "RollbackConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "EndpointSpec": {
                "Mode": "vip"
            }
        },
        "PreviousSpec": {
            "Name": "mcapp_db",
            "Labels": {
                "com.docker.stack.image": "postgres:16",
                "com.docker.stack.namespace": "mcapp"
            },
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "postgres:16@sha256:4eb532412200f7fbbf15d62ee0d96e020a9eae9eaed76066692474a7371c4d83",
                    "Labels": {
                        "com.docker.stack.namespace": "mcapp"
                    },
                    "Env": [
                        "POSTGRES_DB=appdb",
                        "POSTGRES_PASSWORD=password",
                        "POSTGRES_USER=postgres"
                    ],
                    "Privileges": {
                        "CredentialSpec": null,
                        "SELinuxContext": null,
                        "NoNewPrivileges": false
                    },
                    "Mounts": [
                        {
                            "Type": "volume",
                            "Source": "mcapp_dbdata",
                            "Target": "/var/lib/postgresql/data",
                            "VolumeOptions": {
                                "Labels": {
                                    "com.docker.stack.namespace": "mcapp"
                                }
                            }
                        }
                    ],
                    "Isolation": "default"
                },
                "Resources": {},
                "RestartPolicy": {
                    "Condition": "on-failure",
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Constraints": [
                        "node.labels.role == db"
                    ],
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "arm64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "386",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "ppc64le",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "riscv64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        },
                        {
                            "Architecture": "s390x",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "unknown",
                            "OS": "unknown"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "x1xqxiq44uy1g1ss2pz2ohuby",
                        "Aliases": [
                            "db"
                        ]
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "EndpointSpec": {
                "Mode": "vip"
            }
        },
        "Endpoint": {
            "Spec": {
                "Mode": "vip"
            },
            "VirtualIPs": [
                {
                    "NetworkID": "x1xqxiq44uy1g1ss2pz2ohuby",
                    "Addr": "10.0.1.7/24"
                }
            ]
        }
    }
]

docker inspect mcapp_web
[
    {
        "ID": "hs4ikrsujepq2n3rlxc5h7cz9",
        "Version": {
            "Index": 459
        },
        "CreatedAt": "2025-10-27T06:08:46.888203428Z",
        "UpdatedAt": "2025-10-27T06:30:06.833573508Z",
        "Spec": {
            "Name": "mcapp_web",
            "Labels": {
                "com.docker.stack.image": "chien314832001/hw5_web:latest",
                "com.docker.stack.namespace": "mcapp"
            },
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "chien314832001/hw5_web:latest@sha256:569d184ad916daff99b52f072d8fc5aaef7ae7d0c3039d2a69d753d04a9b7e36",
                    "Labels": {
                        "com.docker.stack.namespace": "mcapp"
                    },
                    "Privileges": {
                        "CredentialSpec": null,
                        "SELinuxContext": null,
                        "NoNewPrivileges": false
                    },
                    "StopGracePeriod": 10000000000,
                    "DNSConfig": {},
                    "Isolation": "default"
                },
                "Resources": {},
                "RestartPolicy": {
                    "Condition": "on-failure",
                    "Delay": 5000000000,
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Constraints": [
                        "node.hostname != isl3080"
                    ],
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "x1xqxiq44uy1g1ss2pz2ohuby",
                        "Aliases": [
                            "web"
                        ]
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "UpdateConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "RollbackConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "EndpointSpec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 80,
                        "PublishMode": "ingress"
                    }
                ]
            }
        },
        "PreviousSpec": {
            "Name": "mcapp_web",
            "Labels": {
                "com.docker.stack.image": "chien314832001/hw5_web:latest",
                "com.docker.stack.namespace": "mcapp"
            },
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "chien314832001/hw5_web:latest@sha256:569d184ad916daff99b52f072d8fc5aaef7ae7d0c3039d2a69d753d04a9b7e36",
                    "Labels": {
                        "com.docker.stack.namespace": "mcapp"
                    },
                    "Privileges": {
                        "CredentialSpec": null,
                        "SELinuxContext": null,
                        "NoNewPrivileges": false
                    },
                    "Isolation": "default"
                },
                "Resources": {},
                "RestartPolicy": {
                    "Condition": "on-failure",
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Constraints": [
                        "node.hostname != isl3080"
                    ],
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "x1xqxiq44uy1g1ss2pz2ohuby",
                        "Aliases": [
                            "web"
                        ]
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "EndpointSpec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 80,
                        "PublishMode": "ingress"
                    }
                ]
            }
        },
        "Endpoint": {
            "Spec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 80,
                        "PublishMode": "ingress"
                    }
                ]
            },
            "Ports": [
                {
                    "Protocol": "tcp",
                    "TargetPort": 80,
                    "PublishedPort": 80,
                    "PublishMode": "ingress"
                }
            ],
            "VirtualIPs": [
                {
                    "NetworkID": "icalubxbcodxkb15rmy3or40p",
                    "Addr": "10.0.0.21/24"
                },
                {
                    "NetworkID": "x1xqxiq44uy1g1ss2pz2ohuby",
                    "Addr": "10.0.1.5/24"
                }
            ]
        }
    }
]
```
5. `mount for mcapp_db`
output:
```
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS                  PORTS                                           NAMES
20539dab2036   postgres:16            "docker-entrypoint.s…"   31 minutes ago   Up 31 minutes           5432/tcp
```
6. `curl to /, /api/…, /healthz`
output:
```
curl -fsS http://100.109.55.80/healthz
{"database":"connected","status":"healthy"}

curl -fsS http://100.109.55.80
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>CCSA HW3</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    body { font: 16px system-ui, sans-serif; margin: 2rem; }
    form, ul { max-width: 520px; }
    input { padding: 0.5rem; width: 100%; max-width: 360px; }
    button { padding: 0.5rem 0.8rem; margin-left: 0.5rem; }
    li { margin: 0.3rem 0; }
    code { background: #f6f6f6; padding: 0 0.3rem; }
  </style>
</head>
<body>
  <h1>CCSA HW5</h1>

  <form id="nameForm">
    <input id="nameInput" placeholder="Enter a name (<= 50 chars)" maxlength="50" />
    <button type="submit">Add</button>
  </form>

  <h2>Stored names</h2>
  <ul id="names"></ul>

  <script>
    const list = document.getElementById('names');
    const input = document.getElementById('nameInput');
    const form = document.getElementById('nameForm');

    async function refresh() {
      const res = await fetch('/api/names');
      const data = await res.json();
      list.innerHTML = '';
      data.forEach(row => {
        const li = document.createElement('li');
        li.textContent = `${row.name} (created_at: ${row.created_at}) `;
        const btn = document.createElement('button');
        btn.textContent = 'Delete';
        btn.onclick = async () => {
          await fetch(`/api/names/${row.id}`, { method: 'DELETE' });
          await refresh();
        };
        li.appendChild(btn);
        list.appendChild(li);
      });
    }

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = input.value.trim();
      if (!name) { alert('Name cannot be empty.'); return; }
      const res = await fetch('/api/names', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ name })
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        alert(err.error || 'Error');
      } else {
        input.value = '';
        await refresh();
      }
    });

    refresh();
  </script>
</body>
</html>
```