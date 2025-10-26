# Speckit specification (detailed)

This file contains the exact deployment requirements for Speckit in HW5.

Requirements (as requested):

- Managers run the web (Nginx) and api (Flask) tasks.
- The stack publishes port 80:80 so HTTP traffic reaches the frontend.
- Worker nodes run the PostgreSQL database only; DB data is stored on the worker host at `/var/lob/postgres-data`.
- The overlay network used for service-to-service communication is named `appnet`.
- Service discovery must work so the API can reach the DB by the service DNS name `db`.
- Healthchecks:
  - DB readiness: use `pg_isready`.
  - API readiness/health: HTTP GET `/healthz` should return JSON `{"status":"ok"}`.

Notes and assumptions:

- I'm using the literal path you specified `/var/lob/postgres-data` as the host bind mount location for DB data. If that was a typo and you meant `/var/lib/postgres-data` please let me know and I will update the stack to use that path instead.
- The API image must listen on a port inside the container (the stack below assumes the API listens on port 8000). The API container should expose an endpoint `/healthz` that returns 200 with the body `{ "status":"ok" }`.
- The API can reach the DB at the hostname `db` because Docker Swarm provides service discovery via the overlay network `appnet`.
- The DB service uses a bind-mounted volume so data is persisted on the worker host filesystem at `/var/lob/postgres-data`.
- For production use replace plaintext DB credentials with Swarm secrets.

Quick verification checklist after deploy:

1. Ensure worker hosts have `/var/lob/postgres-data` created and writable by the docker runtime.
2. Deploy the stack: `docker stack deploy -c HW5/content/swarm/stack.yml speckit`.
3. Check services and placement:
   - `docker service ls` should show `nginx` and `api` running on manager nodes.
   - `docker service ps speckit_db` should show tasks on worker nodes only.
4. Verify healthchecks:
   - `docker service ps --no-trunc speckit_db` show healthy state (pg_isready should pass).
   - `curl -sSf http://<manager-ip>/healthz` returns `{"status":"ok"}`.
