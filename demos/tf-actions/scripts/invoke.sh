#!/bin/bash

aws lambda invoke   --function-name send-a-message   --cli-binary-format raw-in-base64-out   --payload '{"message":"Hello from Terraform"}'   response.json
cat response.json
echo
rm -rf response.json
