# Backend Reference Implementation

This document contains the Python (Flask) and Microsoft SQL Server 2022 code requested for the backend implementation. The running application is a React prototype, but this code serves as the blueprint for the production backend.

## 1. SQL Server 2022 Database Schema

```sql
-- Create Database
CREATE DATABASE HR_Grievance_System;
GO

USE HR_Grievance_System;
GO

-- Employee Table
CREATE TABLE EMPLOYEE (
    employee_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('Employee', 'HR Admin'))
);
GO

-- Grievance Table
CREATE TABLE GRIEVANCE (
    grievance_id INT IDENTITY(1,1) PRIMARY KEY,
    employee_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description VARCHAR(MAX) NOT NULL,
    status VARCHAR(255) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Review', 'Resolved')),
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Employee_Grievance FOREIGN KEY (employee_id) REFERENCES EMPLOYEE(employee_id)
);
GO

-- Index for performance on searches
CREATE INDEX IDX_Grievance_Employee ON GRIEVANCE(employee_id);
GO
```

## 2. Flask Application Structure

```python
# app.py
from flask import Flask, render_template, request, redirect, url_for, session, flash, g
import pyodbc
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps

app = Flask(__name__)
app.secret_key = 'super_secret_key_change_in_production'

# Microsoft SQL Server Configuration
DB_CONFIG = {
    'DRIVER': '{ODBC Driver 17 for SQL Server}',
    'SERVER': 'localhost',
    'DATABASE': 'HR_Grievance_System',
    'Trusted_Connection': 'yes' # Use Windows Authentication
}

def get_db_connection():
    conn_str = f"DRIVER={DB_CONFIG['DRIVER']};SERVER={DB_CONFIG['SERVER']};DATABASE={DB_CONFIG['DATABASE']};Trusted_Connection={DB_CONFIG['Trusted_Connection']}"
    conn = pyodbc.connect(conn_str)
    return conn

# --- Authentication Decorators ---

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'HR Admin':
            flash('Access denied. HR Admin only.', 'danger')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# --- Routes ---

@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT employee_id, name, role, password_hash FROM EMPLOYEE WHERE email = ?", (email,))
        user = cursor.fetchone()
        conn.close()
        
        if user and check_password_hash(user.password_hash, password):
            session['user_id'] = user.employee_id
            session['name'] = user.name
            session['role'] = user.role
            
            if user.role == 'HR Admin':
                return redirect(url_for('admin_dashboard'))
            return redirect(url_for('employee_dashboard'))
        else:
            flash('Invalid credentials', 'danger')
            
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

# --- Employee Workflow ---

@app.route('/dashboard')
@login_required
def employee_dashboard():
    if session['role'] == 'HR Admin':
        return redirect(url_for('admin_dashboard'))
        
    conn = get_db_connection()
    cursor = conn.cursor()
    # Workflow 3: View Own Grievances
    cursor.execute("SELECT grievance_id, title, status, created_at FROM GRIEVANCE WHERE employee_id = ? ORDER BY created_at DESC", (session['user_id'],))
    grievances = cursor.fetchall()
    conn.close()
    
    return render_template('employee_dashboard.html', grievances=grievances, name=session['name'])

@app.route('/submit_grievance', methods=['POST'])
@login_required
def submit_grievance():
    # Workflow 2: Submit Grievance
    if session['role'] != 'Employee':
        return redirect(url_for('admin_dashboard'))

    title = request.form['title']
    description = request.form['description']
    terms = request.form.get('terms')

    # Input Validation
    if not title or not description:
        flash('Title and Description are required.', 'warning')
        return redirect(url_for('employee_dashboard'))
        
    if not terms:
        flash('You must agree to the terms before submitting.', 'warning')
        return redirect(url_for('employee_dashboard'))

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO GRIEVANCE (employee_id, title, description) VALUES (?, ?, ?)",
        (session['user_id'], title, description)
    )
    conn.commit()
    conn.close()
    
    flash('Grievance submitted successfully.', 'success')
    return redirect(url_for('employee_dashboard'))

# --- HR Admin Workflow ---

@app.route('/admin')
@login_required
@admin_required
def admin_dashboard():
    conn = get_db_connection()
    cursor = conn.cursor()
    # Workflow 4: View All Grievances
    cursor.execute("""
        SELECT g.grievance_id, e.name, g.title, g.description, g.status, g.created_at 
        FROM GRIEVANCE g
        JOIN EMPLOYEE e ON g.employee_id = e.employee_id
        ORDER BY g.created_at DESC
    """)
    grievances = cursor.fetchall()
    conn.close()
    
    return render_template('admin_dashboard.html', grievances=grievances, name=session['name'])

@app.route('/update_status/<int:id>', methods=['POST'])
@login_required
@admin_required
def update_status(id):
    new_status = request.form['status']
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE GRIEVANCE SET status = ? WHERE grievance_id = ?", (new_status, id))
    conn.commit()
    conn.close()
    
    flash('Status updated.', 'success')
    return redirect(url_for('admin_dashboard'))

@app.route('/delete_grievance/<int:id>', methods=['POST'])
@login_required
@admin_required
def delete_grievance(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM GRIEVANCE WHERE grievance_id = ?", (id,))
    conn.commit()
    conn.close()
    
    flash('Grievance deleted.', 'success')
    return redirect(url_for('admin_dashboard'))

if __name__ == '__main__':
    app.run(debug=True)
```
