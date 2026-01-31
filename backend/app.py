from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import pyodbc
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

def get_conn():
    server = os.getenv('DB_SERVER')
    database = os.getenv('DB_DATABASE')
    username = os.getenv('DB_USERNAME')
    password = os.getenv('DB_PASSWORD')
    conn_str = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password};TrustServerCertificate=yes;'
    return pyodbc.connect(conn_str, autocommit=True)

@app.route('/')
def health_check():
    return "OK", 200

@app.route("/api/ping")
def ping():
    try:
        conn = get_conn()
        conn.close()
        return jsonify({"status":"ok"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Login with password validation
@app.route("/api/auth/login", methods=["POST"])
def login():
    try:
        data = request.json
        email = data.get("email")
        password = data.get("password")
        
        if not email or not password:
            return jsonify({"error": "Email and password required"}), 400
        
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT employee_id, name, email, password_hash, role FROM users WHERE email = ?", email)
        row = cur.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"error": "Invalid credentials"}), 401
        
        # Check password hash
        stored_hash = row[3]
        if not check_password_hash(stored_hash, password):
            return jsonify({"error": "Invalid credentials"}), 401
        
        # Convert database role to frontend enum
        db_role = row[4]
        frontend_role = "HR Admin" if db_role == "ADMIN" else "Employee"
        
        return jsonify({
            "employee_id": row[0],
            "name": row[1],
            "email": row[2],
            "role": frontend_role
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/grievances", methods=["GET"])
def list_grievances():
    try:
        employee_id = request.args.get("employee_id")
        role = request.args.get("role")
        
        conn = get_conn()
        cur = conn.cursor()
        
        if role == "HR Admin":
            cur.execute("SELECT grievance_id, employee_id, title, description, status, created_at FROM grievances ORDER BY created_at DESC")
        else:
            cur.execute("SELECT grievance_id, employee_id, title, description, status, created_at FROM grievances WHERE employee_id = ? ORDER BY created_at DESC", employee_id)
        
        rows = cur.fetchall()
        conn.close()
        
        result = [{"grievance_id": r[0], "employee_id": r[1], "title": r[2], "description": r[3], "status": r[4], "created_at": r[5].isoformat()} for r in rows]
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/grievances", methods=["POST"])
def create_grievance():
    try:
        data = request.json
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO grievances (employee_id, title, description, status, created_at) VALUES (?, ?, ?, ?, GETDATE())",
                    data.get("employee_id"), data.get("title"), data.get("description"), "PENDING")
        conn.commit()
        conn.close()
        return jsonify({"ok": True}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/grievances/<int:grievance_id>", methods=["PUT"])
def update_grievance(grievance_id):
    try:
        data = request.json
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("UPDATE grievances SET status = ? WHERE grievance_id = ?", data.get("status"), grievance_id)
        conn.commit()
        conn.close()
        return jsonify({"ok": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/grievances/<int:grievance_id>", methods=["DELETE"])
def delete_grievance(grievance_id):
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("DELETE FROM grievances WHERE grievance_id = ?", grievance_id)
        conn.commit()
        conn.close()
        return jsonify({"ok": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)