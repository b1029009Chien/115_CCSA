import os
from flask import Flask, request, jsonify
from sqlalchemy import create_engine, text
from sqlalchemy.pool import QueuePool

DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "postgres")
DB_HOST = os.getenv("POSTGRES_HOST", "db")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "postgres")

DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    future=True,
)

app = Flask(__name__)

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
    app.run(host="0.0.0.0", port=8000)
