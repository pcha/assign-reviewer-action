#!/bin/bash
set -eu

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_NAME" ]]; then
  echo "Set the GITHUB_EVENT_NAME env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

API_HEADER="Accept: application/vnd.github.v3+json; application/vnd.github.antiope-preview+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
reviewer=$(jq --raw-output .requested_reviewer.login "$GITHUB_EVENT_PATH")

update_review_request() {
  body="{\"assignees\":[\"${reviewer}\"]}"
  endpoint="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${number}/requested_reviewers"
  echo $endpoint
  echo $body
  echo $AUTH_HEADER
  echo API_HEADER

  request="-sSL
    -H \"Content-Type: application/json\"
    -H \"${AUTH_HEADER}\"
    -H \"${API_HEADER}\"
    -X $1
    -d $body
    $endpoint"
  echo $request

  curl -sSL -vvv \
    -H "Content-Type: application/json" \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X $1 \
    -d "$body" \
    $endpoint
}

echo "PR #$number"
if [[ "$action" == "review_requested" ]]; then
  echo "Change Assignee"
  echo "Reviewers: $reviewer"
  update_review_request 'PATCH'
#elif [[ "$action" == "review_request_removed" ]]; then
#  update_review_request 'DELETE'
else
  echo "Ignoring action ${action}"
  exit 0
fi
