from flask import Flask, request, jsonify
from flask_cors import CORS
import pyodbc
import os
from dotenv import load_dotenv

# 1. Load the secret variables from .env
load_dotenv()

app = Flask(__name__)
CORS(app)

# 2. Setup the connection string safely
# Ensure your .env file has: DB_SERVER, DB_DATABASE, DB_USERNAME, DB_PASSWORD
def get_conn():
    server = os.getenv('DB_SERVER')
    database = os.getenv('DB_DATABASE')
    username = os.getenv('DB_USERNAME')
    password = os.getenv('DB_PASSWORD')
    
    # This connection string matches your "TrustServerCertificate" requirement
    conn_str = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password};TrustServerCertificate=yes;'
    return pyodbc.connect(conn_str, autocommit=True)

@app.route("/api/ping")
def ping():
    try:
        conn = get_conn()
        conn.close()
        return jsonify({"status":"ok"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/grievances", methods=["GET"])
def list_grievances():
    try:
        conn = get_conn()
        cur = conn.cursor()
        # This line will fail if the table 'grievances' doesn't exist in SQL Server!
        cur.execute("SELECT grievance_id, employee_id, title, description, status, created_at FROM grievances")
        rows = cur.fetchall()
        conn.close()
        result = [dict(grievance_id=r[0], employee_id=r[1], title=r[2], description=r[3], status=r[4], created_at=r[5].isoformat()) for r in rows]
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/grievances", methods=["POST"])
def create_grievance():
    try:
        data = request.json
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO grievances (employee_id, title, description, status) VALUES (?, ?, ?, ?)",
                    data.get("employee_id"), data.get("title"), data.get("description"), data.get("status", "PENDING"))
        conn.commit()
        conn.close()
        return jsonify({"ok": True}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)