## Speckit Constitution

This document specifies the architecture and orchestration choices for the Speckit application in HW5.

### Overview

Speckit is composed of three core components:
- Nginx — reverse proxy and static web server for the frontend.
- Flask — Python web API (backend) serving application logic.
- PostgreSQL — relational database storing persistent data.

Two deployment modes are supported:
- Local development: use `docker-compose.yml` (keeps things simple for a dev machine).
- Production / cluster: use Docker Swarm with `stack.yml` to deploy services on a Swarm cluster.

### Service placement (Swarm)

Services are placed according to their operational requirements and the instructor's request:
- web (Nginx) and api (Flask) run on Swarm manager nodes.
  - Rationale: In small lab clusters, manager nodes may also host control-plane-aware services and are often reachable at advertised IPs. The request explicitly asks for these services on managers.
  - Implemented with placement constraints in the stack file (node.role == manager).
- db (PostgreSQL) runs on Swarm worker nodes.
  - Rationale: Databases should be separated from manager/control-plane duties. We constrain DB to worker nodes using node.role == worker.

Note: placing services by role uses simple node.role constraints; in production you may wish to use node labels to target specific machines (e.g. `node.labels.db==true`).

### Networking and volumes

- A user-defined overlay network is used for inter-service communication in Swarm.
- Persistent data for PostgreSQL is stored in a named volume so data survives container restarts.

### Resilience and scaling

- API (Flask) is configured for one or more replicas in the stack file. Use an external WSGI server (gunicorn) inside the image to handle concurrency.
- Nginx runs as a replicated service or a global service depending on your preference; the example stack uses a single replica with routing managed by the Swarm ingress/load-balancer.
- PostgreSQL runs as a single replica (replication not configured here) and pinned to worker nodes.

### Local development

For local development keep and use `HW5/content/docker-compose.yml`. The compose file mirrors the stack configuration but is intended to be run with `docker compose up` on a developer machine. This avoids requiring a Swarm cluster for everyday development.

Differences between compose and stack usage:
- stack (Swarm): uses `docker stack deploy -c HW5/content/swarm/stack.yml speckit` and runs services across the cluster using overlay networks and placement constraints.
- compose (local): use `docker compose -f HW5/content/docker-compose.yml up --build` for single-host testing.

### Environment and secrets

- Environment variables required for the DB, API, and Nginx should be provided via `.env` files or Docker Swarm secrets when sensitive.
- The stack file included with this repo demonstrates environment variables for non-sensitive values. Replace with secrets for production.

### How to deploy (quick)

1. Local dev:
   - cd to `HW5/content`
   - `docker compose up --build`

2. Swarm deploy (cluster):
   - Initialize or join a Swarm cluster.
   - From the repo root: `docker stack deploy -c HW5/content/swarm/stack.yml speckit`

### Next steps and optional improvements

- Add node labels and use them for more precise placement (e.g., labeled DB workers).
- Add Postgres replication and backup strategy for production readiness.
- Use Swarm secrets for DB credentials.

---

This file complements the repository `HW5/content/docker-compose.yml` and the Swarm stack file `HW5/content/swarm/stack.yml`.
