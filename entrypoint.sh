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
echo "GITHUB_EVENT_PATH:  "
cat $GITHUB_EVENT_PATH
reviewers=$(jq --raw-output '[.requested_reviewers[].login]|join("\", \"")' "$GITHUB_EVENT_PATH")

update_review_request() {
  echo $reviewers
  body="{\"assignees\":[\"${reviewers}\"]}"
  endpoint="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${number}/requested_reviewers"

  curl -sSL \
    -H "Content-Type: application/json" \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X $1 \
    -d $body \
    $endpoint
}

echo "PR #$number"
if [[ "$action" == "review_requested" ]]; then
  echo "Change Assignee"
  echo "Reviewers: $reviewers"
  update_review_request 'PATCH'
#elif [[ "$action" == "review_request_removed" ]]; then
#  update_review_request 'DELETE'
else
  echo "Ignoring action ${action}"
  exit 0
fi
