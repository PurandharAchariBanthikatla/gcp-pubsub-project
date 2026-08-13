"""
Sample publisher for the Pub/Sub end-to-end project.

Usage:
    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/publisher-key.json
    python publisher.py --project your-project-id --topic pubsub-e2e-events --count 5

Auth: run as the "publisher" service account created by Terraform
(roles/pubsub.publisher on the topic only).
"""
import argparse
import json
import time
import uuid
from datetime import datetime, timezone

from google.cloud import pubsub_v1


def build_message(seq: int) -> dict:
    return {
        "id": str(uuid.uuid4()),
        "sequence": seq,
        "event_type": "sample.event",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "payload": {"message": f"hello from publisher #{seq}"},
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, help="GCP project ID")
    parser.add_argument("--topic", default="pubsub-e2e-events", help="Pub/Sub topic name")
    parser.add_argument("--count", type=int, default=5, help="Number of messages to publish")
    parser.add_argument("--interval", type=float, default=0.5, help="Seconds between publishes")
    args = parser.parse_args()

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(args.project, args.topic)

    futures = []
    for seq in range(1, args.count + 1):
        message = build_message(seq)
        data = json.dumps(message).encode("utf-8")
        future = publisher.publish(
            topic_path,
            data=data,
            event_type=message["event_type"],  # example message attribute
        )
        futures.append(future)
        print(f"queued message {message['id']} (seq={seq})")
        time.sleep(args.interval)

    for future in futures:
        message_id = future.result()  # blocks until publish confirmed
        print(f"published, server message_id={message_id}")


if __name__ == "__main__":
    main()
