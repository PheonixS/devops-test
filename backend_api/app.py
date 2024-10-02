import time
import random
import requests
import os
from flask import Flask

app = Flask(__name__)

REQUIRED_ENV_VARS = [
    "EXTERNAL_INTEGRATION_KEY",
    "EXTERNAL_DOWNLOAD_API_URL",
]


def validate_and_parse_envs():
    for env_var in REQUIRED_ENV_VARS:
        if not os.getenv(env_var):
            raise ValueError(f"{env_var} is not set or empty")
        app.config[env_var] = os.getenv(env_var)


def generate_log():
    logs = [
        "Success",
        "Created",
        "Failed",
    ]
    return random.choice(logs)


@app.route('/api_1')
def api_call():
    log_message = generate_log()
    print(f"Operation log: {log_message}")
    time.sleep(0.5)  # Wait for half a second
    return f"completed: {log_message}"


def make_external_url():
    return app.config['EXTERNAL_DOWNLOAD_API_URL'] + "?key=" + app.config['EXTERNAL_INTEGRATION_KEY']


@app.route('/download_external_logs')
def download_external_logs_call():
    request = requests.get(make_external_url())
    if request.status_code != 200:
        return f"Error while requesting external service. Status code was: {request.status_code}\n"

    return request.text


@app.route('/health_check')
def health_check():
    return f"Backend API healthy"


if __name__ == '__main__':
    validate_and_parse_envs()
    app.run(host="0.0.0.0", debug=True)
