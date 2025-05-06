#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
BASE_URL="http://127.0.0.1:3070"
# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq (e.g., 'sudo apt-get install jq' or 'brew install jq')."
    exit 1
fi
# Ensure curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl."
    exit 1
fi

echo "--- Starting Todo App API Tests ---"
echo "Targeting Base URL: $BASE_URL"

# --- Test 1: POST /todos (Create) ---
echo
echo "1. Testing POST /todos (Create)"
# Perform the POST request, capturing the response body and HTTP status code
# -s: silent mode
# -X POST: Specify POST method
# -H 'Content-Type: application/json': Set header
# -d '{"task": "bash test todo"}': Set request body
# -w "\n%{http_code}": Append newline and HTTP status code to the output
response_and_code=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"task": "bash test todo"}' \
    -w "\n%{http_code}" \
    "${BASE_URL}/todos")

# Extract the response body (everything except the last line)
response_body=$(echo "$response_and_code" | head -n -1)
# Extract the status code (the last line)
status_code=$(echo "$response_and_code" | tail -n 1)

# Check if the status code is 201
if [ "$status_code" -ne 201 ]; then
  echo "Error: POST /todos failed! Expected status 201, got $status_code"
  echo "Response body: $response_body"
  exit 1
fi
echo "  Status code 201 OK"

# Extract the _id from the JSON response using jq
# -e: exits with non-zero status if the filter returns null or false
# -r: raw string output (no quotes)
TODO_ID=$(echo "$response_body" | jq -e -r '._id')
if [ -z "$TODO_ID" ] || [ "$TODO_ID" == "null" ]; then
    echo "Error: Could not extract _id from POST response."
    echo "Response body: $response_body"
    exit 1
fi
echo "  Created Todo ID: $TODO_ID"

# --- Test 2: GET /todos (Read All) ---
echo
echo "2. Testing GET /todos (Read All)"
response_and_code=$(curl -s -X GET -w "\n%{http_code}" "${BASE_URL}/todos")
response_body=$(echo "$response_and_code" | head -n -1)
status_code=$(echo "$response_and_code" | tail -n 1)

if [ "$status_code" -ne 200 ]; then
  echo "Error: GET /todos failed! Expected status 200, got $status_code"
  echo "Response body: $response_body"
  exit 1
fi
echo "  Status code 200 OK"

# Check if the created TODO_ID exists in the response array using jq
# Select the object with the matching _id. If found, jq exits 0. If not found, jq exits non-zero (because of -e).
echo "$response_body" | jq -e --arg id "$TODO_ID" '.[] | select(._id == $id)' > /dev/null
if [ $? -ne 0 ]; then
   echo "Error: Newly created todo with ID $TODO_ID not found in GET /todos response."
   echo "Response body: $response_body"
   exit 1
fi
echo "  Found Todo ID $TODO_ID in list"

# --- Test 3: PUT /todos/{id} (Update) ---
echo
echo "3. Testing PUT /todos/{id} (Update)"
response_and_code=$(curl -s -X PUT \
    -H "Content-Type: application/json" \
    -d '{"done": true}' \
    -w "\n%{http_code}" \
    "${BASE_URL}/todos/${TODO_ID}")
response_body=$(echo "$response_and_code" | head -n -1)
status_code=$(echo "$response_and_code" | tail -n 1)

if [ "$status_code" -ne 200 ]; then
  echo "Error: PUT /todos/${TODO_ID} failed! Expected status 200, got $status_code"
  echo "Response body: $response_body"
  exit 1
fi
echo "  Status code 200 OK"

# Check if 'done' is true in the response using jq
echo "$response_body" | jq -e '.done == true' > /dev/null
if [ $? -ne 0 ]; then
   echo "Error: PUT /todos/${TODO_ID} response did not contain '\"done\": true'."
   echo "Response body: $response_body"
   exit 1
fi
echo "  Todo ID $TODO_ID updated successfully (done: true)"

# --- Test 4: DELETE /todos/{id} (Delete) ---
echo
echo "4. Testing DELETE /todos/{id} (Delete)"
# For DELETE 204, there's usually no response body, so just capture the status code
# -o /dev/null: discard the response body
status_code=$(curl -s -X DELETE -o /dev/null -w "%{http_code}" "${BASE_URL}/todos/${TODO_ID}")

if [ "$status_code" -ne 204 ]; then
  echo "Error: DELETE /todos/${TODO_ID} failed! Expected status 204, got $status_code"
  exit 1
fi
echo "  Status code 204 OK - Todo ID $TODO_ID deleted"

echo
echo "--- All Todo App API Tests Passed! ---"
exit 0