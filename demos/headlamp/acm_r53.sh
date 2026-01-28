#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage:

  List ACM certificates:
    ${SCRIPT_NAME} -l [-r eu-west-1] [--contains <string>] [--dry-run]

  Request/validate a new certificate:
    ${SCRIPT_NAME} -d example.com [-s "*.example.com" ...] [-r eu-west-1]
                   [-t 1800] [--no-wait] [--dry-run]

  Delete an existing certificate (optionally clean up Route53 validation CNAMEs):
    ${SCRIPT_NAME} -D <CERT_ARN> [-r eu-west-1] [-c] [--dry-run]

Options:
  -l, --list               List ACM certs (Domain + ARN) and exit
      --contains <string>  Filter list output by substring match against Domain or ARN

  -d, --domain <name>      Domain for new cert request (required for request flow)
  -s, --san <name>         Subject Alternative Name (repeatable)
  -r, --region <region>    Default: eu-west-1
  -t, --timeout <secs>     Default: 1800
      --no-wait            Do not wait for ISSUED; exit after creating DNS validation records

  -D, --delete <cert-arn>  Delete an ACM certificate instead of requesting one
  -c, --cleanup-dns        With --delete: delete Route53 validation records for that cert (if present)

      --dry-run            Print actions but do not change Route53 or delete cert
  -h, --help               Show help

Examples:
  ${SCRIPT_NAME} -l
  ${SCRIPT_NAME} -l --contains example.com
  ${SCRIPT_NAME} -d example.com -s "*.example.com"
  ${SCRIPT_NAME} -d example.com --no-wait
  ${SCRIPT_NAME} -D arn:aws:acm:eu-west-1:123:certificate/abc -c
EOF
}

DOMAIN=""
REGION="eu-west-1"
WAIT_TIMEOUT_SECS=1800
NO_WAIT="false"
DRY_RUN="false"

DELETE_ARN=""
CLEANUP_DNS="false"

LIST="false"
CONTAINS=""

SANS=()

# ---- parse args ----
while [ "${#@}" -gt 0 ]; do
  case "$1" in
    -l|--list)
      LIST="true"
      shift 1
      ;;
    --contains)
      CONTAINS="${2:-}"
      shift 2
      ;;

    -d|--domain)
      DOMAIN="${2:-}"
      shift 2
      ;;
    -s|--san)
      SANS+=("${2:-}")
      shift 2
      ;;
    -r|--region)
      REGION="${2:-}"
      shift 2
      ;;
    -t|--timeout)
      WAIT_TIMEOUT_SECS="${2:-}"
      shift 2
      ;;
    --no-wait)
      NO_WAIT="true"
      shift 1
      ;;

    --dry-run)
      DRY_RUN="true"
      shift 1
      ;;
    -D|--delete)
      DELETE_ARN="${2:-}"
      shift 2
      ;;
    -c|--cleanup-dns)
      CLEANUP_DNS="true"
      shift 1
      ;;

    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

find_hosted_zone_id() {
  local domain="$1"
  python3 - <<'PY' "$domain"
import json, subprocess, sys
domain = sys.argv[1].rstrip(".").lower()

data = subprocess.check_output(["aws", "route53", "list-hosted-zones", "--output", "json"])
zones = json.loads(data)["HostedZones"]

best = None
for z in zones:
  name = z["Name"].rstrip(".").lower()
  if domain == name or domain.endswith("." + name):
    if best is None or len(name) > len(best[0]):
      best = (name, z["Id"])

if not best:
  print("", end="")
  sys.exit(0)

print(best[1].split("/")[-1], end="")
PY
}

get_validation_records_for_cert() {
  local cert_arn="$1"
  aws acm describe-certificate \
    --certificate-arn "$cert_arn" \
    --region "$REGION" \
    --query "Certificate.DomainValidationOptions[].ResourceRecord" \
    --output json
}

apply_r53_changes_from_records() {
  local records_json="$1"
  local hosted_zone_id="$2"
  local action="$3" # UPSERT or DELETE

  python3 - <<'PY' "$records_json" "$hosted_zone_id" "$action" "$DRY_RUN"
import json, subprocess, sys

records = json.loads(sys.argv[1])
hz_id = sys.argv[2]
action = sys.argv[3]
dry_run = (sys.argv[4].lower() == "true")

seen = set()
changes = []

for r in records:
  if not r:
    continue
  name = r["Name"]
  rtype = r["Type"]
  value = r["Value"]
  key = (name, rtype, value)
  if key in seen:
    continue
  seen.add(key)

  changes.append({
    "Action": action,
    "ResourceRecordSet": {
      "Name": name,
      "Type": rtype,
      "TTL": 300,
      "ResourceRecords": [{"Value": value}]
    }
  })

batch = {"Comment": f"ACM DNS validation records ({action})", "Changes": changes}

if not changes:
  print("No Route53 changes to apply.")
  sys.exit(0)

cmd = [
  "aws", "route53", "change-resource-record-sets",
  "--hosted-zone-id", hz_id,
  "--change-batch", json.dumps(batch)
]

print("Applying Route53 change batch with", len(changes), "record(s):", action)
print("Command:", " ".join(cmd))

if dry_run:
  sys.exit(0)

subprocess.check_call(cmd)
PY
}

wait_for_issued() {
  local cert_arn="$1"
  local start now status
  start="$(date +%s)"

  echo "Waiting for certificate to be ISSUED (timeout: ${WAIT_TIMEOUT_SECS}s)..."
  while true; do
    status="$(
      aws acm describe-certificate \
        --certificate-arn "$cert_arn" \
        --region "$REGION" \
        --query "Certificate.Status" \
        --output text
    )"
    echo "Status: ${status}"

    if [ "$status" = "ISSUED" ]; then
      echo "Done. Certificate issued:"
      echo "$cert_arn"
      return 0
    fi

    now="$(date +%s)"
    if [ $((now - start)) -ge "$WAIT_TIMEOUT_SECS" ]; then
      echo "ERROR: Timed out waiting for issuance."
      echo "Check:"
      echo "aws acm describe-certificate --certificate-arn $cert_arn --region $REGION"
      return 2
    fi

    sleep 15
  done
}

# ---------------------------
# List flow
# ---------------------------
if [ "$LIST" = "true" ]; then
  echo "Listing ACM certificates (region: ${REGION})"

  if [ -n "$CONTAINS" ]; then
    aws acm list-certificates --region "$REGION" --output json \
    | python3 - <<'PY' "$CONTAINS"
import json, sys
contains = sys.argv[1].lower()
data = json.load(sys.stdin)

for c in data.get("CertificateSummaryList", []):
  domain = c.get("DomainName", "")
  arn = c.get("CertificateArn", "")
  if contains in domain.lower() or contains in arn.lower():
    print(f"{domain}\t{arn}")
PY
  else
    aws acm list-certificates \
      --region "$REGION" \
      --query "CertificateSummaryList[].{Domain:DomainName, ARN:CertificateArn}" \
      --output text
  fi
  exit 0
fi

# ---------------------------
# Delete flow
# ---------------------------
if [ -n "$DELETE_ARN" ]; then
  echo "Delete flow"
  echo "  CertificateArn: ${DELETE_ARN}"
  echo "  Region        : ${REGION}"
  echo "  Cleanup DNS   : ${CLEANUP_DNS}"
  echo "  Dry run       : ${DRY_RUN}"

  if [ "$CLEANUP_DNS" = "true" ]; then
    CERT_DOMAIN="$(
      aws acm describe-certificate \
        --certificate-arn "$DELETE_ARN" \
        --region "$REGION" \
        --query "Certificate.DomainName" \
        --output text
    )"

    if [ -z "$CERT_DOMAIN" ] || [ "$CERT_DOMAIN" = "None" ]; then
      echo "ERROR: Could not determine certificate domain name for hosted zone lookup."
      exit 1
    fi

    HZ_ID="$(find_hosted_zone_id "$CERT_DOMAIN")"
    if [ -z "$HZ_ID" ]; then
      echo "ERROR: Could not find a Route53 hosted zone matching ${CERT_DOMAIN}"
      exit 1
    fi
    echo "Using Route53 Hosted Zone: ${HZ_ID}"

    RECORDS_JSON="$(get_validation_records_for_cert "$DELETE_ARN")"
    if [ "$RECORDS_JSON" = "null" ] || [ "$RECORDS_JSON" = "[]" ]; then
      echo "No validation records found on the cert; skipping DNS cleanup."
    else
      apply_r53_changes_from_records "$RECORDS_JSON" "$HZ_ID" "DELETE"
    fi
  fi

  echo "Deleting ACM certificate..."
  if [ "$DRY_RUN" = "true" ]; then
    echo "[dry-run] aws acm delete-certificate --certificate-arn \"$DELETE_ARN\" --region \"$REGION\""
  else
    aws acm delete-certificate --certificate-arn "$DELETE_ARN" --region "$REGION"
  fi

  echo "Done."
  exit 0
fi

# ---------------------------
# Request flow
# ---------------------------
if [ -z "$DOMAIN" ]; then
  echo "ERROR: Either --list, --domain (request flow), or --delete (delete flow) is required."
  usage
  exit 1
fi

echo "Requesting ACM certificate"
echo "  Domain : ${DOMAIN}"
echo "  Region : ${REGION}"
if [ "${#SANS[@]}" -gt 0 ]; then
  echo "  SANs   : ${SANS[*]}"
else
  echo "  SANs   : (none)"
fi
echo "  No wait: ${NO_WAIT}"
echo "  Dry run: ${DRY_RUN}"

if [ "$DRY_RUN" = "true" ]; then
  echo "[dry-run] aws acm request-certificate ... (not requesting in dry-run)"
  echo "[dry-run] Exiting because request flow cannot proceed without an ARN."
  exit 0
fi

if [ "${#SANS[@]}" -gt 0 ]; then
  CERT_ARN="$(
    aws acm request-certificate \
      --domain-name "$DOMAIN" \
      --subject-alternative-names "${SANS[@]}" \
      --validation-method DNS \
      --region "$REGION" \
      --query CertificateArn \
      --output text
  )"
else
  CERT_ARN="$(
    aws acm request-certificate \
      --domain-name "$DOMAIN" \
      --validation-method DNS \
      --region "$REGION" \
      --query CertificateArn \
      --output text
  )"
fi

echo "CertificateArn: ${CERT_ARN}"

HZ_ID="$(find_hosted_zone_id "$DOMAIN")"
if [ -z "$HZ_ID" ]; then
  echo "ERROR: Could not find a Route53 hosted zone matching ${DOMAIN}"
  exit 1
fi
echo "Using Route53 Hosted Zone: ${HZ_ID}"

echo "Waiting for ACM to publish DNS validation records..."
RECORDS_JSON="[]"
for _ in $(seq 1 30); do
  RECORDS_JSON="$(get_validation_records_for_cert "$CERT_ARN")"
  if [ "$RECORDS_JSON" != "null" ] && [ "$RECORDS_JSON" != "[]" ]; then
    break
  fi
  sleep 2
done

if [ "$RECORDS_JSON" = "null" ] || [ "$RECORDS_JSON" = "[]" ]; then
  echo "ERROR: No validation records found yet. Try again in ~30-60 seconds."
  exit 1
fi

echo "Creating/Updating validation records in Route53 (deduped)..."
apply_r53_changes_from_records "$RECORDS_JSON" "$HZ_ID" "UPSERT"

if [ "$NO_WAIT" = "true" ]; then
  echo "No-wait selected. Exiting after DNS changes."
  echo "$CERT_ARN"
  exit 0
fi

wait_for_issued "$CERT_ARN"
