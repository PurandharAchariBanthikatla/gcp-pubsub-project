"""
Sample pull subscriber for the Pub/Sub end-to-end project.

Usage:
    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/subscriber-key.json
    python subscriber.py --project your-project-id --subscription pubsub-e2e-events-pull-sub

Auth: run as the "subscriber" service account created by Terraform
(roles/pubsub.subscriber on the subscription, roles/storage.objectViewer
on the archive bucket).

Ctrl+C to stop.
"""
import argparse
import json
from concurrent.futures import TimeoutError as FuturesTimeoutError

from google.cloud import pubsub_v1


def make_callback(project: str):
    def callback(message: pubsub_v1.subscriber.message.Message) -> None:
        try:
            payload = json.loads(message.data.decode("utf-8"))
        except json.JSONDecodeError:
            payload = {"raw": message.data.decode("utf-8", errors="replace")}

        print("--- message received ---")
        print(f"  id:         {message.message_id}")
        print(f"  attributes: {dict(message.attributes)}")
        print(f"  payload:    {payload}")

        # TODO: real processing goes here (write to a DB, trigger a workflow, etc.)

        message.ack()

    return callback


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, help="GCP project ID")
    parser.add_argument(
        "--subscription",
        default="pubsub-e2e-events-pull-sub",
        help="Pub/Sub subscription name",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=None,
        help="Seconds to listen before exiting (default: run forever)",
    )
    args = parser.parse_args()

    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(args.project, args.subscription)

    streaming_pull_future = subscriber.subscribe(
        subscription_path, callback=make_callback(args.project)
    )
    print(f"listening on {subscription_path} ...")

    with subscriber:
        try:
            streaming_pull_future.result(timeout=args.timeout)
        except (FuturesTimeoutError, KeyboardInterrupt):
            streaming_pull_future.cancel()
            streaming_pull_future.result()
            print("subscriber stopped")


if __name__ == "__main__":
    main()
