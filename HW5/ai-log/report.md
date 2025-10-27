# AI Log — HW5 Changes and Spec Mapping

Date: 2025-10-27
Author: automated assistant

Summary
-------
This report summarizes recent infrastructure and code changes made for HW5, and ties those changes to the design/specification under `content/spec/`.

High-level changes
------------------
- Added a health endpoint to the backend API so the system can report service and DB health.
  - File: `HW5/content/backend/application.py`
  - Purpose: Provide a concise `/healthz` endpoint that verifies DB connectivity.
- Fixed Nginx routing for `/healthz` and improved static routing.
  - File: `HW5/content/frontend/nginx.conf`
  - Purpose: Ensure health checks are proxied to the API and static assets are served correctly.
- Created a formal spec describing DB placement, storage, overlay network, and risks.
  - File: `HW5/content/spec/db-design-spec.md`
  - Purpose: Capture placement constraints, persistence choices, network design, and risk mitigations.
- Created operational scripts to streamline cluster lifecycle and CI-like operations.
  - Files: `HW5/ops/init-swarm.sh`, `HW5/ops/deploy.sh`, `HW5/ops/verify.sh`, `HW5/ops/cleanup.sh`
  - Purpose: Initialize swarm, deploy stack, verify health, and clean up resources.
- Updated and redeployed the stack images and stack definition.
  - Files: `HW5/content/swarm/stack.yaml`, built/pushed images `chien314832001/hw5_api:latest` and `chien314832001/hw5_web:latest`

Spec mapping
------------
- Placement
  - Spec: `content/spec/db-design-spec.md` documents a placement constraint: database runs on nodes labeled `role=db`.
  - Implementation: `stack.yaml` includes placement constraints for the `db` service (and scripts include optional `--label-db`).

- Storage & Persistence
  - Spec: `db-design-spec.md` describes use of a named Docker volume (`dbdata`) mounted at `/var/lib/postgresql/data`.
  - Implementation: `stack.yaml` mounts `dbdata` for the `db` service. `cleanup.sh` documents volume removal caveats.

- Overlay Network
  - Spec: `db-design-spec.md` notes the overlay network `appnet` used for multi-host service discovery and inter-service communication.
  - Implementation: `init-swarm.sh` will create `appnet` when initializing the swarm. Services in the stack connect to `appnet`.

- Risk Analysis
  - Spec: `db-design-spec.md` enumerates data loss, node failure, network partitions, and security risks plus mitigations (backups, labels, internal-only DB access, health checks).
  - Implementation: Basic mitigations implemented:
    - No DB ports exposed externally in `stack.yaml` (DB accessible only within overlay network).
    - `/healthz` endpoint validates DB connectivity and can be used by monitoring systems.
    - Operational scripts provide documented, repeatable actions to initialize, deploy, verify, and cleanup.

Verification performed
----------------------
- Built and pushed updated Docker images for backend and frontend.
- Redeployed the stack with `docker stack deploy`.
- Verified `/healthz` returns `200` and a JSON payload indicating DB connectivity:
  - Example: `{"database":"connected","status":"healthy"}`

Files created/changed (summary)
------------------------------
- Created: `HW5/content/ai-log/report.md` (this file)
- Created: `HW5/content/spec/db-design-spec.md` (design/spec for DB)
- Created: `HW5/ops/init-swarm.sh`, `HW5/ops/deploy.sh`, `HW5/ops/verify.sh`, `HW5/ops/cleanup.sh`
- Updated: `HW5/content/backend/application.py` (added `/healthz`)
- Updated: `HW5/content/frontend/nginx.conf` (healthz proxy + static route)
- Updated: `HW5/content/swarm/stack.yaml` (ports and placement already present or adjusted)

How to reproduce
----------------
1. Initialize swarm and create overlay network (on manager):

```bash
HW5/ops/init-swarm.sh --label-db
```

2. (Optional) Build and push images, then deploy the stack:

```bash
HW5/ops/deploy.sh --build
# or without build if images already pushed
HW5/ops/deploy.sh
```

3. Verify health endpoint (adjust host if remote):

```bash
HW5/ops/verify.sh 100.109.55.80 80
```

4. Cleanup (optional):

```bash
HW5/ops/cleanup.sh --remove-volumes
```

Next steps & recommendations
---------------------------
- Make the `HW5/ops/*.sh` scripts executable (`chmod +x HW5/ops/*.sh`).
- Implement automated backups for the `dbdata` volume and test restore procedures.
- Consider adding a lightweight log/metrics pipeline (Prometheus + Grafana) and a containerized backup job.
- For production-like reliability, evaluate PostgreSQL replication or managed DB services.

Notes
-----
- Named volumes are local to nodes in a Swarm; in a multi-node cluster, the DB volume lives on the node where the DB task runs. `cleanup.sh` documents this caveat.
- Secrets are currently passed via environment variables; migrating to Docker secrets or a secrets manager is recommended.

