#!/bin/bash

copilot app delete

aws logs describe-log-groups \
    | jq '.[][]["logGroupName"] | select(contains("app1-test"))' -r \
    | xargs -I{} aws logs delete-log-group --log-group-name {}
