import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function: send-a-message

    Expected event example:
    {
        "message": "Hello from Lambda"
    }
    """
    message = event.get("message")

    if not message:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing 'message' in request"})
        }

    logger.info("send-a-message received: %s", message)

    return {
        "statusCode": 200,
        "body": json.dumps({"status": "logged", "message": message})
    }
