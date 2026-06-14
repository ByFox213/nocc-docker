#!/bin/bash

# Get all running nocc-server pod names
PODS=($(kubectl get pods -l app=nocc-server -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'))

if [ ${#PODS[@]} -eq 0 ]; then
  echo "Error: No running nocc-server pods found!"
  exit 1
fi

echo "Found ${#PODS[@]} pods. Starting port-forwards..."

# Port base starts at 43211
PORT=43211
SERVERS_ENV=""

for POD in "${PODS[@]}"; do
  echo "Forwarding local port $PORT to $POD:43210..."
  # Run port-forward in the background
  kubectl port-forward pod/"$POD" "$PORT":43210 > /dev/null 2>&1 &
  
  if [ -z "$SERVERS_ENV" ]; then
    SERVERS_ENV="127.0.0.1:$PORT"
  else
    SERVERS_ENV="$SERVERS_ENV;127.0.0.1:$PORT"
  fi
  
  PORT=$((PORT + 1))
done

echo "----------------------------------------"
echo "Port-forwards started in background."
echo "To stop them, run: killall kubectl"
echo "----------------------------------------"
echo "Export the following env variables to use them:"
echo "export NOCC_SERVERS=\"$SERVERS_ENV\""
echo "export NOCC_GO_EXECUTABLE=\"/usr/bin/nocc-daemon\""
