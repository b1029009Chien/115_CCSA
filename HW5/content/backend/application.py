import os
from flask import Flask, request, jsonify
from sqlalchemy import create_engine, text
from sqlalchemy.pool import QueuePool

DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "postgres")
DB_HOST = os.getenv("POSTGRES_HOST", "db")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "postgres")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    future=True,
)

app = Flask(__name__)


def ensure_schema(retries: int = 6, delay: float = 2.0) -> None:
    """Ensure required DB schema exists. Called on app startup (before first request).

    This will attempt to connect to the database and run a CREATE TABLE IF NOT EXISTS
    for the `names` table. We retry a few times because the DB container may still be
    initializing when the app starts.
    """
    from time import sleep

    sql = text("""
    CREATE TABLE IF NOT EXISTS names (
      id SERIAL PRIMARY KEY,
      name VARCHAR(50) NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );
    """)

    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            with engine.begin() as conn:
                conn.execute(sql)
            app.logger.info("DB schema ensured (names table present)")
            return
        except Exception as e:
            last_exc = e
            app.logger.warning(f"ensure_schema attempt {attempt} failed: {e}")
            sleep(delay)

    app.logger.error("Failed to ensure DB schema after retries", exc_info=last_exc)

@app.get("/healthz")
def healthz():
    """Kubernetes/Swarm-style readiness probe returning {"status":"ok"} when DB is reachable."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok"}, 200
    except Exception as e:
        return {"status": "error", "error": str(e)}, 500

@app.get("/api/health")
def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"ok": True}, 200
    except Exception as e:
        return {"ok": False, "error": str(e)}, 500

@app.post("/api/names")
def add_name():
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()

    # Validation
    if not name:
        return jsonify({"error": "Name cannot be empty."}), 400
    if len(name) > 50:
        return jsonify({"error": "Name must be at most 50 characters."}), 400

    with engine.begin() as conn:
        row = conn.execute(
            text("INSERT INTO names (name) VALUES (:name) RETURNING id, name, created_at"),
            {"name": name},
        ).mappings().first()
    return jsonify(dict(row)), 201

@app.get("/api/names")
def list_names():
    with engine.connect() as conn:
        rows = conn.execute(
            text("SELECT id, name, created_at FROM names ORDER BY id ASC")
        ).mappings().all()
    return jsonify([dict(r) for r in rows]), 200

@app.delete("/api/names/<int:name_id>")
def delete_name(name_id: int):
    with engine.begin() as conn:
        deleted = conn.execute(
            text("DELETE FROM names WHERE id = :id RETURNING id"),
            {"id": name_id}
        ).first()
        if not deleted:
            return jsonify({"error": f"id {name_id} not found"}), 404
    return "", 204

if __name__ == "__main__":
    # When running with the development server, ensure schema before serving.
    ensure_schema()
    app.run(host="0.0.0.0", port=8000)

# For production (gunicorn) we run ensure_schema once per worker on first request.
# Register startup hook in a way that works across Flask versions (2.x and 3.x).
if hasattr(app, "before_first_request"):
    @app.before_first_request
    def _init_on_first_request():
        ensure_schema()
elif hasattr(app, "before_serving"):
    # Flask 3 uses before_serving; it may expect a sync or async callable.
    try:
        @app.before_serving
        def _init_on_before_serving():
            ensure_schema()
    except TypeError:
        @app.before_serving
        async def _init_on_before_serving():
            ensure_schema()
else:
    # Fallback: call directly (best-effort) so schema exists for tests/dev.
    ensure_schema()
