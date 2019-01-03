#!/usr/bin/env bash

#
# JWT Encoder Bash Script
# @See https://stackoverflow.com/questions/46657001/how-do-you-create-an-rs256-jwt-assertion-with-bash-shell-scripting/46672439#46672439
#

secret=$1
scopes=''

set -o pipefail

# Static header fields.
header='{
	"typ": "JWT",
	"alg": "HS256"
}'

payload='{
  "user": {
    "type": "user",
    "id": -2
  }
}'

# Use jq to set the dynamic `iat` and `exp`
# fields on the header using the current time.
# `iat` is set to now, and `exp` is now + 1 second.
payload=$(
	echo "${payload}" | jq --arg time_str "$(date +%s)" --arg scope1 ${2} --arg scope2 "${3}" \
	'
	($time_str | tonumber) as $time_num
	| .iat=$time_num
	| .exp=($time_num + 1209600)
	| .scopes=[$scope1, $scope2]-[""]
	'
)

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
json() { jq -c . | LC_CTYPE=C tr -d '\n'; }

sign() {
        local sig
        signed_content="$(json <<<"$header" | b64enc).$(json <<<"$payload" | b64enc)"
        sig=$(printf %s "$signed_content" | openssl dgst -binary -sha256 -hmac "${secret}" | b64enc)
        printf '%s.%s\n' "${signed_content}" "${sig}"
}

(( $# )) && sign "$@"

