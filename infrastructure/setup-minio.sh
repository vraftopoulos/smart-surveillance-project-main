#!/bin/sh

# Περιμένουμε να σηκωθούν οι υπηρεσίες
echo "Waiting for MinIO and RabbitMQ..."
sleep 30

# 1. Σύνδεση με τον MinIO server
mc alias set myminio http://minio:9000 minioadmin minioadmin

# Δημιουργία Exchange, Queue και Binding στο RabbitMQ μέσω API
echo "Creating RabbitMQ Queue and Binding..."
apk add --no-cache curl # Υπάρχει το curl

# Δημιουργία του Exchange
curl -i -u user:password -H "content-type:application/json" \
  -X PUT -d '{"type":"topic","durable":true}' \
  http://rabbitmq:15672/api/exchanges/%2f/security-exchange

# Δημιουργία της Ουράς (Queue)
curl -i -u user:password -H "content-type:application/json" \
  -X PUT -d '{"durable":true}' \
  http://rabbitmq:15672/api/queues/%2f/security-queue

# Σύνδεση (Binding) της ουράς με τον exchange
curl -i -u user:password -H "content-type:application/json" \
  -X POST -d '{"routing_key":"security-event","arguments":{}}' \
  http://rabbitmq:15672/api/bindings/%2f/e/security-exchange/q/security-queue

# 2. Ρύθμιση του RabbitMQ ως endpoint
mc admin config set myminio notify_rabbitmq:primary \
  url='amqp://user:password@rabbitmq:5672' \
  exchange='security-exchange' \
  exchange_type='topic' \
  routing_key='security-event' \
  durable='on'

# 3. Επανεκκίνηση για να ενεργοποιηθεί το config
mc admin service restart myminio
sleep 5

# 4. Δημιουργία του Bucket
mc mb --ignore-existing myminio/security-photos

# 5. Ανέβασμα του ήχου
echo "Uploading alarm sound..."
# Ανεβάζουμε το αρχείο στο bucket security-photos
mc cp /project_files/alarm-sound.mp3 myminio/security-photos/
# Κάνουμε το αρχείο δημόσια προσβάσιμο για να μπορεί να το παίξει το ThingsBoard
mc anonymous set download myminio/security-photos/alarm-sound.mp3

# 6. Ενεργοποίηση των Notifications για εικόνες
mc event add myminio/security-photos arn:minio:sqs::primary:rabbitmq --event put --suffix .jpg
mc event add myminio/security-photos arn:minio:sqs::primary:rabbitmq --event put --suffix .png

echo "MinIO-RabbitMQ automation completed!"