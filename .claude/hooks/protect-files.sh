#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

deny() {
  jq -n --arg file "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("protect-files.sh: refusing to write/edit " + $file + " — this path holds credentials or secrets.")
    }
  }'
  exit 0
}

[[ -z "$FILE" ]] && exit 0

case "$FILE" in
  */config/master.key|config/master.key) deny "$FILE" ;;
  */config/credentials.yml.enc|config/credentials.yml.enc) deny "$FILE" ;;
  */config/credentials/*|config/credentials/*) deny "$FILE" ;;
  */.env|.env) deny "$FILE" ;;
  */.env.*|.env.*) deny "$FILE" ;;
  *.pem) deny "$FILE" ;;
esac

exit 0
