Swarm usage notes for HW5 (Speckit)

This README explains how to pin the Postgres DB to a specific worker using a node label and how to prepare the worker host directory used by the `pgdata` bind mount. The stack file `HW5/content/swarm/stack.yml` expects the DB service to be scheduled on nodes with the label `db=true`.

1) Find the worker node name

Run on a manager:

```bash
docker node ls
```

Locate the worker node name (HOSTNAME / NAME column).

2) Label the worker node for DB

Run on a manager (replace `<worker-node>`):

```bash
# add label 'db=true' to the desired worker
docker node update --label-add db=true <worker-node>

# verify the label was applied
docker node inspect <worker-node> --format '{{json .Spec.Labels}}' | jq
```

3) Prepare the host directory for Postgres data (on the worker)

The stack uses a host bind to `/var/lib/postgres-data` on the node that runs the DB. Create and secure that directory on the labeled worker:

```bash
# on the worker node
sudo mkdir -p /var/lib/postgres-data
# set ownership to Postgres UID (official image commonly uses 999)
sudo chown -R 999:999 /var/lib/postgres-data
sudo chmod 700 /var/lib/postgres-data
```

If your Postgres image uses a different UID/GID, adjust the chown command accordingly.

4) Deploy / update the stack

From a manager or any machine with Docker configured to the manager:

```bash
docker stack deploy -c HW5/content/swarm/stack.yml speckit

# or to force rescheduling of only the db service:
docker service update --force speckit_db
```

5) Verify the DB is running on the labeled worker

```bash
docker service ps speckit_db
```

Expected: the NODE column for the `speckit_db` tasks shows the labeled worker node.

Notes

- Host bind mounts tie data to the filesystem of the worker. If you move the DB task to another node that doesn't have the same path, data won't be present. Use shared storage for HA.
- To remove the label later:

```bash
docker node update --label-rm db <worker-node>
```

Questions or next steps

- I can update the stack to use a cluster volume driver (NFS/Longhorn) instead of a host bind if you want the DB to be movable between nodes.
- I can also add a small script to automate the label & prepare steps.
Swarm deployment for MC App
===========================

This folder contains a Docker Swarm stack example to deploy the HW5 web/api/db split with the DB forced to run on the lab worker node and persistent storage located at `/var/lib/postgres-data` on that node.

Files
- `stack.yaml` — the Swarm stack file. Deploy with `docker stack deploy -c swarm/stack.yaml mcapp` from the manager.

Quick Swarm commands (run on MANAGER — your student laptop)

1. Initialize Swarm on the manager (if not already):

```
docker swarm init
```

2. On the WORKER (lab node) join the swarm (run on worker using the token from manager):

```
docker swarm join --token <token> <mgr-ip>:2377
```

3. Label the lab node so the DB only schedules there (run on MANAGER):

```
docker node update --label-add role=db=true <lab-node-hostname>
```

4. Create the DB secret (on MANAGER):

```
echo "your-db-password" | docker secret create db_password -
```

5. Deploy the stack (on MANAGER):

```
docker stack deploy -c swarm/stack.yaml mcapp
```

6. Inspect services and placement (on MANAGER):

```
docker stack services mcapp
docker service ps mcapp_db
docker service ps mcapp_api
docker service ps mcapp_web
```

Health checks and quick tests

- Check web ingress (on manager, or from other machine if accessible):

```
curl -fsS http://<manager-ip>/
curl -fsS http://<manager-ip>/healthz
```

- The API must be able to reach the DB by DNS name `db` (service discovery inside the overlay `appnet`).
- The DB service runs only on nodes with label `role=db` and stores data in `/var/lib/postgres-data` on that node (volume `dbdata`).

Notes and assumptions
- The stack expects you to have an `HW5/content/db/init.sql` initialization file (the stack binds `./HW5/content/db/init.sql` into the container). Adjust paths if your project uses a different layout.
- The stack defines a docker secret `db_password` as external; create it on the manager before deploying.
- The API is expected to read DB password from `/run/secrets/db_password` (environment `DATABASE_PASSWORD_FILE` is set). Adjust your app to read secret file accordingly.
- The `dbdata` volume is created as a host bind to `/var/lib/postgres-data` on the node that runs the DB (driver_opts with bind). Ensure the lab node filesystem has that path and Docker has permission to write there.

If you want,下一步我可以：

- (A) 產生一個對應的 `docker-compose.override.yml`（local dev），或
- (B) 把 `api` 與 `web` 的 image build/push steps 加入到一個簡易部署 script（CI 模式），或
- (C) 幫你修改後端程式讓它直接從 `/run/secrets/db_password` 讀取密碼並在啟動時建立 `DATABASE_URL`。

請告訴我你要我先做哪一項（A/B/C）或有其他變更需求。
