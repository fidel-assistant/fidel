from pathlib import Path

# backend/ (parent of app/)
BACKEND_ROOT = Path(__file__).resolve().parents[2]
TEMPLATES_DIR = BACKEND_ROOT / "templates"
STATIC_DIR = BACKEND_ROOT / "static"
