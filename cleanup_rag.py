"""Clean up stale file records, vector DB collections from previous broken sessions.
Run this once before restarting after changing RAG config.
"""
import sqlite3, json, os, shutil

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
WEBUI_DB = os.path.join(
    os.environ.get("APPDATA", ""),
    r"..\Local\Programs\Python\Python311\Lib\site-packages\open_webui\data\webui.db",
)
# Resolve the AppData path
WEBUI_DB = os.path.abspath(os.path.expandvars(WEBUI_DB))

if not os.path.exists(WEBUI_DB):
    # Try the pip package data dir directly
    WEBUI_DB = r"C:\Users\Angriliset\AppData\Local\Programs\Python\Python311\Lib\site-packages\open_webui\data\webui.db"

print(f"Database: {WEBUI_DB}")

conn = sqlite3.connect(WEBUI_DB)
cursor = conn.cursor()

# Delete files with failed or pending status
cursor.execute("SELECT id, filename, data FROM file")
all_files = cursor.fetchall()

failed_files = []
pending_files = []
for f in all_files:
    try:
        data = json.loads(f[2]) if f[2] else {}
        status = data.get("status", "")
        if status == "failed":
            failed_files.append(f)
        elif status == "pending":
            pending_files.append(f)
    except:
        pass

print(f"Failed files: {len(failed_files)}, Pending files: {len(pending_files)}")

# Delete failed files
for f in failed_files:
    cursor.execute("DELETE FROM file WHERE id = ?", (f[0],))
    cursor.execute("DELETE FROM chat_file WHERE file_id = ?", (f[0],))
    print(f"  Deleted failed: {f[1][:40]}")

# Delete pending files
for f in pending_files:
    cursor.execute("DELETE FROM file WHERE id = ?", (f[0],))
    cursor.execute("DELETE FROM chat_file WHERE file_id = ?", (f[0],))
    print(f"  Deleted pending: {f[1][:40]}")

conn.commit()
conn.close()
print("Database cleaned.")

# Delete vector DB to force clean rebuild
vector_db_dir = os.path.join(
    os.environ.get("APPDATA", ""),
    r"..\Local\Programs\Python\Python311\Lib\site-packages\open_webui\data\vector_db",
)
vector_db_dir = os.path.abspath(os.path.expandvars(vector_db_dir))

if os.path.exists(vector_db_dir):
    shutil.rmtree(vector_db_dir)
    print(f"Deleted vector DB: {vector_db_dir}")
else:
    print("No vector DB to clean.")

print("\nDone. Now restart with .\\start.bat")
