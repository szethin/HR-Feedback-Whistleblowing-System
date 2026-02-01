import pyodbc
import os
from werkzeug.security import generate_password_hash
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def seed_database():
    # 1. Connect to Database
    server = os.getenv('DB_SERVER')
    database = os.getenv('DB_DATABASE')
    username = os.getenv('DB_USERNAME')
    password = os.getenv('DB_PASSWORD')
    
    if not server:
        print("Error: DB_SERVER not found. Are you running this on the server?")
        return

    print(f"Connecting to {server}...")
    conn_str = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password};TrustServerCertificate=yes;'
    
    try:
        conn = pyodbc.connect(conn_str, autocommit=True)
        cur = conn.cursor()
        print("Connected successfully.")
    except Exception as e:
        print(f"Connection Failed: {e}")
        return

    # 2. Create 'users' Table
    print("Creating tables...")
    cur.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' and xtype='U')
    CREATE TABLE users (
        employee_id INT PRIMARY KEY IDENTITY(1,1),
        name NVARCHAR(255) NOT NULL,
        email NVARCHAR(255) UNIQUE NOT NULL,
        password_hash NVARCHAR(255),
        role NVARCHAR(50) DEFAULT 'EMPLOYEE'
    )
    """)

    # 3. Create 'grievances' Table
    cur.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='grievances' and xtype='U')
    CREATE TABLE grievances (
        grievance_id INT PRIMARY KEY IDENTITY(1,1),
        employee_id INT NOT NULL,
        title NVARCHAR(255) NOT NULL,
        description NVARCHAR(MAX),
        status NVARCHAR(50) DEFAULT 'PENDING',
        created_at DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (employee_id) REFERENCES users(employee_id)
    )
    """)

    # 4. Create Users (Generating FRESH hashes to ensure login works)
    print("Inserting users...")
    
    # We generate the hash right here so it matches the server's python version
    common_password = "password123"
    hashed_pw = generate_password_hash(common_password)
    
    users_data = [
        ('John Doe', 'employee@test.com', hashed_pw, 'EMPLOYEE'),
        ('Jane Smith', 'jane@test.com', hashed_pw, 'EMPLOYEE'),
        ('Admin User', 'admin@test.com', hashed_pw, 'ADMIN')
    ]

    for name, email, p_hash, role in users_data:
        cur.execute("SELECT email FROM users WHERE email = ?", email)
        if not cur.fetchone():
            cur.execute("INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)", 
                        (name, email, p_hash, role))
            print(f" - Created: {name}")
        else:
            # If user exists, update their password to the fresh hash
            cur.execute("UPDATE users SET password_hash = ? WHERE email = ?", (p_hash, email))
            print(f" - Updated password for: {name}")

    # 5. Create Grievances
    print("Inserting grievances...")
    cur.execute("SELECT COUNT(*) FROM grievances")
    if cur.fetchone()[0] == 0:
        # Get IDs for the users we just created
        cur.execute("SELECT employee_id FROM users WHERE email='employee@test.com'")
        emp_id = cur.fetchone()[0]
        
        cur.execute("INSERT INTO grievances (employee_id, title, description, status, created_at) VALUES (?, 'Office Temperature', 'The AC is too cold in the north wing.', 'PENDING', GETDATE())", emp_id)
        cur.execute("INSERT INTO grievances (employee_id, title, description, status, created_at) VALUES (?, 'Safety Hazard', 'Loose cables in the hallway.', 'RESOLVED', GETDATE())", emp_id)
        print(" - Grievances added.")
    else:
        print(" - Grievances already exist.")

    conn.close()
    print("\nSUCCESS! Database seeded.")
    print(f"You can now log in as 'admin@test.com' with password '{common_password}'")

if __name__ == "__main__":
    seed_database()