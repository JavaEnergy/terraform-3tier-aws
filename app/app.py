import os
import psycopg2
import psycopg2.extras
from flask import Flask, request, jsonify

app = Flask(__name__)


def get_db_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", 5432)),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
    )


def init_db():
    """Create the items table if it doesn't exist."""
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS items (
            id         SERIAL PRIMARY KEY,
            name       VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )
    conn.commit()
    cur.close()
    conn.close()


# ─── ROUTES ──────────────────────────────────────────────────────────────────

@app.route("/")
def hello():
    return jsonify({
        "message": "Hello World!",
        "region": os.environ.get("AWS_REGION", "unknown"),
        "environment": os.environ.get("FLASK_ENV", "unknown"),
    })


@app.route("/health")
def health():
    """ALB health check endpoint."""
    try:
        conn = get_db_connection()
        conn.close()
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    return jsonify({"status": "healthy", "db": db_status}), 200


@app.route("/items", methods=["GET"])
def get_items():
    """Return all items from the database."""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT id, name, created_at::text FROM items ORDER BY id;")
    items = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(list(items))


@app.route("/items", methods=["POST"])
def create_item():
    """Create a new item. Body: { "name": "my item" }"""
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "Field 'name' is required"}), 400

    name = data["name"].strip()
    if not name:
        return jsonify({"error": "Name cannot be empty"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO items (name) VALUES (%s) RETURNING id, name, created_at::text;",
        (name,),
    )
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"id": row[0], "name": row[1], "created_at": row[2]}), 201


@app.route("/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    """Delete an item by ID."""
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM items WHERE id = %s RETURNING id;", (item_id,))
    deleted = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if deleted:
        return jsonify({"message": f"Item {item_id} deleted successfully"})
    return jsonify({"error": f"Item {item_id} not found"}), 404


# ─── STARTUP ─────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=False)
