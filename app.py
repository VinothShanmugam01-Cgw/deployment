from flask import Flask, jsonify
import os

app = Flask(__name__)

APP_ENV  = os.getenv("APP_ENV", "development")
APP_NAME = os.getenv("APP_NAME", "your-app")

@app.route("/")
def home():
    return jsonify({
        "app":     APP_NAME,
        "env":     APP_ENV,
        "status":  "running"
    })

@app.route("/health")          # ← liveness probe endpoint
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/ready")           # ← readiness probe endpoint
def ready():
    return jsonify({"status": "ready"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)