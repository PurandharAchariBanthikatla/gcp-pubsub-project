"""
Optional HTTPS push receiver, meant to be deployed on Cloud Run and wired
up as the Pub/Sub push subscription's endpoint (var.push_endpoint in
Terraform). Pub/Sub calls this with a signed OIDC token as the
"pubsub-push-invoker" service account; Cloud Run validates it automatically
when the service is configured to require authentication.

Deploy (example):
    gcloud run deploy pubsub-e2e-push-receiver \
        --source app/ \
        --region asia-south1 \
        --no-allow-unauthenticated

Then grant roles/run.invoker to the pubsub_invoker service account (see
the commented block in terraform/iam.tf) and set push_endpoint in
terraform.tfvars to the resulting Cloud Run URL + "/pubsub/push".
"""
import base64
import json
import logging

from flask import Flask, request

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)


@app.route("/pubsub/push", methods=["POST"])
def pubsub_push():
    envelope = request.get_json(silent=True)
    if not envelope or "message" not in envelope:
        return "Bad Request: invalid Pub/Sub message format", 400

    pubsub_message = envelope["message"]
    data = pubsub_message.get("data", "")
    decoded = base64.b64decode(data).decode("utf-8") if data else ""

    try:
        payload = json.loads(decoded) if decoded else {}
    except json.JSONDecodeError:
        payload = {"raw": decoded}

    logging.info("push message_id=%s payload=%s", pubsub_message.get("messageId"), payload)

    # TODO: real processing goes here

    return "", 204


@app.route("/healthz", methods=["GET"])
def healthz():
    return "ok", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
