import boto3
import json
import logging
import os

from base64 import b64decode
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

SLACK_CHANNEL = os.environ['SLACK_CHANNEL']
HOOK_URL = os.environ['SLACK_WEBHOOK_URL']
SLACK_USER = os.environ['SLACK_USERNAME']
#slack_emoji = os.environ['SLACK_EMOJI']
AWS_DOC_URL = "https://docs.aws.amazon.com/console/guardduty/"
AWS_CON_URL = "https://console.aws.amazon.com/guardduty"

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def send_to_slack(severity, title, alert_type, msg_id, region):

    link_title = ''.join(e for e in alert_type if e.isalnum())
    link_url = "%s%s" % (AWS_DOC_URL, link_title)
    link_url_console = "%s/home?region=%s#/findings?macros=current&fId=%s" % (AWS_CON_URL, region, msg_id)

    sev_high = ['danger', 'High']
    sev_medium = ['warning', 'Medium']
    sev_low = ['#ff970f', 'Low']

    sinfo = ( (0.1<=severity<3.9) and sev_low ) or \
            ( (4.0<=severity<6.9) and sev_medium ) or \
            ( (7.0<=severity<8.9) and sev_high )

    color = str(sinfo[0])
    score = str(sinfo[1])

    slack_message = {
        "channel": SLACK_CHANNEL,
        "username": SLACK_USER,
        #"icon_emoji": ":warning:",
        "icon_url": "https://raw.githubusercontent.com/aws-samples/amazon-guardduty-to-slack/master/images/gd_logo.png",
        "attachments": [{
            "color": color,
            "text": title,
            "title": alert_type,
            "title_link": link_url,
            "fallback": title,
            "fields": [
                {
                    "title": "Severity",
                    "value": score,
                    "short": "true"
                }
            ],
            "actions": [
                {
                    "type": "button",
                    "text": "Console",
                    "url": link_url_console
                },
                {
                    "type": "button",
                    "text": "Reference",
                    "url": link_url
                }
            ]
        }]
    }

    req = Request(HOOK_URL, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)


def lambda_handler(event, context):

    #logger.info("Event payload: %s", event)
    timestamp = event['time']
    title = event['detail']['title']
    severity = event['detail']['severity']
    alert_type = event['detail']['type']
    msg_id = event['detail']['id']
    region = event['region']

    send_to_slack(severity, title, alert_type, msg_id, region)

    return str(event)
