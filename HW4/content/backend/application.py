import os
from flask import Flask, request, jsonify
from sqlalchemy import create_engine, text
from sqlalchemy.pool import QueuePool

DATABASE_URL = "sqlite:///./names.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
    future=True,
)

app = Flask(__name__)

def init_db():
    with engine.begin() as conn:
        conn.execute(text("""
        CREATE TABLE IF NOT EXISTS names (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """))
init_db()

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
