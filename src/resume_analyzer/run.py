"""
Run shim for resume_analyzer when running from src/
This file adds the original resume_analyzer folder to PYTHONPATH and runs the Flask app.
"""
import os
import sys

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
ORIG = os.path.abspath(os.path.join(ROOT, 'resume_analyzer'))

# Ensure the original resume_analyzer package is importable
if ORIG not in sys.path:
    sys.path.insert(0, ORIG)

try:
    # import the Flask app from the original location
    from app import app
except Exception as e:
    print('Failed to import resume_analyzer.app:', e)
    raise

if __name__ == '__main__':
    debug = os.getenv('FLASK_DEBUG', 'false').lower() == 'true'
    port = int(os.getenv('PORT', 5001))
    app.run(debug=debug, port=port, use_reloader=False)
