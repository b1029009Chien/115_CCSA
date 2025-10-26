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
