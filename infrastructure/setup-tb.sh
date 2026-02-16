#!/bin/sh

# Εγκατάσταση απαραίτητων εργαλείων
apk add --no-cache curl jq
echo "Waiting 90 seconds for ThingsBoard to initialize..."
sleep 90

# 1. Login για λήψη Token
RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"username":"tenant@thingsboard.org", "password":"tenant"}' \
  http://mytb:9090/api/auth/login)

TOKEN=$(echo $RESPONSE | jq -r .token)

if [ "$TOKEN" != "null" ] && [ "$TOKEN" != "" ]; then
  echo "Login Successful."

  # 2. Create Device
  DEVICE_RESPONSE=$(curl -s -X POST http://mytb:9090/api/device \
    -H "X-Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "Camera", "type": "camera-device", "label": "Security Camera"}')
  
  DEVICE_ID=$(echo $DEVICE_RESPONSE | jq -r .id.id)
  echo "Device ID found: $DEVICE_ID"

  # Διαγραφή παλιών credentials αν υπάρχουν
curl -s -X DELETE http://mytb:9090/api/device-credentials/$DEVICE_ID \
  -H "X-Authorization: Bearer $TOKEN"

# Επαναφορά του σωστού Token
curl -s -X POST http://mytb:9090/api/device-credentials \
  -H "X-Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"deviceId\": {\"id\": \"$DEVICE_ID\", \"entityType\": \"DEVICE\"}, \"credentialsId\": \"my_camera_token\", \"credentialsType\": \"ACCESS_TOKEN\"}"
  
  echo "Access Token: my_camera_token set."

  # 4. Import Dashboard
  curl -s -X POST http://mytb:9090/api/dashboard \
    -H "X-Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @/dashboard.json
    
  echo "Dashboard Import Completed!"
else
  echo "Login Failed! Check ThingsBoard logs."
fi