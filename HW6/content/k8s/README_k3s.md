HW6 k3s quickstart
===================

This file explains how to deploy the HW6 stack on a k3s cluster and what to do if something goes wrong. It is intentionally ordered so a first-time user can follow it step-by-step.

Prerequisites
-------------
- A machine with k3s installed and kubectl configured to talk to it. Install k3s:

   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```

- kubectl (locally) or access to the control plane node that has `/etc/rancher/k3s/k3s.yaml` available.
- (Optional) SSH access to the lab node if you plan to use a hostPath PV.

What is included
-----------------
Files under `HW6/content/k3s/`:
- `namespace.yaml` — namespace `hw6`
- `api-deployment.yaml`, `api-service.yaml`
- `web-configmap.yaml`, `web-deployment.yaml`, `web-service.yaml`
- `db-deployment.yaml`, `db-service.yaml`, `db-pv.yaml`, `db-pvc.yaml`
- `ingress.yaml`

Step-by-step quickstart (recommended)
------------------------------------
Follow these steps in order. Commands assume you run them from the repo root.

1) (Optional) Label the lab node that should host Postgres

If you already have a node dedicated to the lab DB, label it (replace the node name shown by `kubectl get nodes -o wide`):

```bash
# find node name and label it (run where kubectl works)
kubectl get nodes -o wide
kubectl label node <lab-node-name> role=db
```

2) Create the data directory on the lab host (only if you use the provided hostPath PV)

SSH into the lab node and run:

```bash
sudo mkdir -p /var/lib/hw6-postgres
sudo chown 999:999 /var/lib/hw6-postgres   # optional: make Postgres owner (UID 999 in official image)
```

3) Apply the namespace and the DB PV/PVC first (ensures the DB will bind to the hostPath)

```bash
kubectl apply -f HW6/content/k3s/namespace.yaml
kubectl apply -n hw6 -f HW6/content/k3s/db-pv.yaml
kubectl apply -n hw6 -f HW6/content/k3s/db-pvc.yaml
```

4) Deploy DB, API and web

```bash
kubectl apply -n hw6 -f HW6/content/k3s/db-deployment.yaml
kubectl apply -n hw6 -f HW6/content/k3s/api-deployment.yaml -f HW6/content/k3s/api-service.yaml
kubectl apply -n hw6 -f HW6/content/k3s/web-configmap.yaml -f HW6/content/k3s/web-deployment.yaml -f HW6/content/k3s/web-service.yaml
```

5) (Optional) Deploy Ingress

If Traefik is enabled in k3s (default), the provided `ingress.yaml` will work. Otherwise install an ingress controller and modify `ingress.yaml` to match it.

```bash
kubectl apply -n hw6 -f HW6/content/k3s/ingress.yaml
```

6) Verify resources

```bash
kubectl -n hw6 get pods,svc,pvc,ingress
kubectl -n hw6 describe pod -l component=db
kubectl -n hw6 get endpoints api -o yaml
```

Initialize the DB schema (important)
-----------------------------------
The repo contains `HW6/content/db/init.sql` which creates the `names` table required by the API. If that script was not executed during first-time DB init, create the table now.

Quick, non-destructive options (run from repo root):

Option A — run the SQL directly into the running Postgres pod:

```bash
DBPOD=$(kubectl -n hw6 get pods -l component=db -o jsonpath='{.items[0].metadata.name}')
kubectl -n hw6 exec -i ${DBPOD} -- psql -U postgres -d appdb <<'SQL'
CREATE TABLE IF NOT EXISTS names (
   id SERIAL PRIMARY KEY,
   name VARCHAR(50) NOT NULL,
   created_at TIMESTAMPTZ DEFAULT now()
);
SQL
```

Option B — copy the repo init.sql into the pod and execute it:

```bash
kubectl -n hw6 cp HW6/content/db/init.sql ${DBPOD}:/tmp/init.sql
kubectl -n hw6 exec -it ${DBPOD} -- psql -U postgres -d appdb -f /tmp/init.sql
```

After the SQL runs, restart the API so it reconnects cleanly:

```bash
kubectl -n hw6 rollout restart deployment/api
kubectl -n hw6 rollout status deployment/api
```

Health checks and debugging
---------------------------
- Test the API health endpoint from inside the cluster (best for DNS/network checks):

```bash
kubectl -n hw6 run --rm -i --tty curlpod --image=curlimages/curl --restart=Never -- curl -sS -v http://api:8000/healthz
```

- Port-forward the API pod for local testing (debug only):

```bash
APIPOD=$(kubectl -n hw6 get pods -l component=api -o jsonpath='{.items[0].metadata.name}')
kubectl -n hw6 port-forward pod/${APIPOD} 8000:8000
# then: curl http://localhost:8000/healthz
```

- If `curl` reports `Connection refused` while port-forwarding, check inside-pod listening and logs:

```bash
kubectl -n hw6 exec -it ${APIPOD} -- sh -c "ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null || echo 'no ss/netstat'"
kubectl -n hw6 logs ${APIPOD} --tail=200
```

Common problems and quick fixes
-------------------------------
- Missing DB schema (you'll see `relation "names" does not exist` in API logs): run the init SQL (see above).
- Service endpoints empty: ensure pod labels match the Service selector and that pods are Ready (`kubectl -n hw6 get endpoints api`).
- Images not found: push to a reachable registry or import the image into the k3s node using `k3s ctr images import`.

Useful commands
---------------
- Check all hw6 resources:
   `kubectl -n hw6 get all,pvc`
- Tail API logs:
   `kubectl -n hw6 logs -f deploy/api`
- Tail DB logs:
   `kubectl -n hw6 logs -f deploy/db`
- Restart components:
   `kubectl -n hw6 rollout restart deployment/api` (or `db`, `web`)

Stop & restart the machine and components
----------------------------------------
Below are safe, copyable commands to stop/restart the k3s service, reboot the host machine, and restart Kubernetes deployments. Replace `hw6` namespace and deployment names where needed.

1) Restart the k3s service on the node (safe, preserves containers):

```bash
# restart k3s service (requires sudo)
sudo systemctl restart k3s

# check k3s / kubelet status
sudo systemctl status k3s --no-pager

# verify kubectl connectivity afterwards
kubectl get nodes
kubectl -n hw6 get pods
```

2) Stop and start k3s (if you need to fully stop it first):

```bash
# stop k3s
sudo systemctl stop k3s

# start it again
sudo systemctl start k3s

# or combine (stop then start)
sudo systemctl restart k3s
```

3) Reboot the host machine (use when OS/network/disk issues need a full reboot):

```bash
# gracefully reboot the node (requires sudo)
sudo reboot

# after reboot, re-check cluster state
kubectl get nodes
kubectl -n hw6 get pods
```

4) Restart hw6 workloads without touching k3s service (Kubernetes way):

```bash
# restart specific deployments
kubectl -n hw6 rollout restart deployment/api
kubectl -n hw6 rollout restart deployment/db
kubectl -n hw6 rollout restart deployment/web

# watch rollout status
kubectl -n hw6 rollout status deployment/api
kubectl -n hw6 rollout status deployment/db
```

Notes & safety
- Restarting the k3s service will briefly interrupt cluster operations; pods will not be deleted but network connections will drop while the service restarts.
- Rebooting the host will stop all containers; ensure data directories (e.g., `/var/lib/hw6-postgres`) are persisted and accessible after boot.
- Use `kubectl -n hw6 rollout restart` when you just need the application processes restarted and prefer not to disturb node-level services.

Next enhancements I can add (suggested)
- Add an idempotent Kubernetes Job to run `init.sql` automatically.
- Add readiness/liveness probes to `api` so the Service only receives traffic when the app is ready.
- Convert DB `Deployment` to a `StatefulSet` for more stable identity/storage behaviour.

If you want, I can add the Job/Probes/StatefulSet as a follow-up and provide a small `deploy_lab_db.sh` helper script to automate the whole flow.


Troubleshooting: why /healthz returned connection refused and how to fix it
---------------------------------------------------------------------

Short answer: port-forwarding and kubectl were working, but the API container inside the pod either wasn't listening yet or the API could not access the database and was failing requests. In your run the DB had no `names` table, so API calls that depend on the DB returned errors — if the API doesn't bind or crashes during startup the forwarded port will refuse connections.

Why this often happens
- The Postgres image runs initialization scripts only on first-time initialization (when the data directory is empty). If the init script wasn't present inside the container at that moment, the app schema (the `names` table) won't be created.
- The app may try to connect to Postgres on startup. If Postgres was not yet ready the app could log connection errors and refuse or fail requests until DB is available.
- `kubectl port-forward svc/api 8000:8000` forwards a local port to the Service, but if the underlying Pod is not listening on port 8000 the connection will be refused.

Quick fixes you can run now

1) Confirm service endpoints and pod status

```bash
kubectl -n hw6 get pods,svc,pvc
kubectl -n hw6 get endpoints api -o wide
kubectl -n hw6 describe pod -l component=api
```

2) Initialize the DB from the repo's `init.sql` (fast, non-destructive)

From the repo root (this repo includes the file at `HW6/content/db/init.sql`):

```bash
# get DB pod name
DBPOD=$(kubectl -n hw6 get pods -l component=db -o jsonpath='{.items[0].metadata.name}')

# copy the init SQL into the DB pod
kubectl -n hw6 cp HW6/content/db/init.sql ${DBPOD}:/tmp/init.sql

# run the SQL inside Postgres
kubectl -n hw6 exec -it ${DBPOD} -- psql -U postgres -d appdb -f /tmp/init.sql
```

Or, without creating a file in the pod (single command):

```bash
kubectl -n hw6 exec -i ${DBPOD} -- psql -U postgres -d appdb <<'SQL'
CREATE TABLE IF NOT EXISTS names (
   id SERIAL PRIMARY KEY,
   name VARCHAR(50) NOT NULL,
   created_at TIMESTAMPTZ DEFAULT now()
);
SQL
```

After creating the table the API should be able to respond to requests that query the `names` table.

3) Test the health endpoint safely

- Test from inside the cluster (tests DNS & networking):

```bash
kubectl -n hw6 run --rm -i --tty curlpod --image=curlimages/curl --restart=Never -- curl -sS -v http://api:8000/healthz
```

- Port-forward the pod directly (bypass the Service) to avoid Service-selector timing issues:

```bash
POD=$(kubectl -n hw6 get pods -l component=api -o jsonpath='{.items[0].metadata.name}')
kubectl -n hw6 port-forward pod/${POD} 8000:8000
# then open another terminal and:
curl -v http://localhost:8000/healthz
```

Why `curl http://localhost:8000/healthz` failed earlier
- If you ran `kubectl port-forward` and immediately attempted curl, the API process inside the pod may not yet have started or may have been refusing DB-dependent requests — so the socket was closed and curl logged "Connection refused".
- Port-forward maps your local port to the remote target, but it does not make the remote process start or become ready — that's the container's job. If the container isn't listening on that port (or if it immediately closes connections because of DB errors), you'll see connection refused.

Longer-term fixes (recommended)
- Add an `init.sql` Job (or mount the init SQL into `/docker-entrypoint-initdb.d/` on first init) so DB schema is created automatically.
- Add `readinessProbe` to the `api` deployment that checks a simple DB-free health check or a DB ping; that prevents the Service receiving traffic until the app is ready.
- Convert the DB `Deployment` to a `StatefulSet` and provide stable storage/identity if you need production-like guarantees.

If you want, I can add a small Kubernetes Job manifest to `HW6/content/k8s/` that runs `init.sql` once and then exits; or add a script that runs the `kubectl cp` + `psql` commands for you. Which would you prefer?
