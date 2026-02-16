#!/bin/sh
echo "Waiting for MinIO..."
until mc alias set myminio http://minio:9000 minioadmin minioadmin; do
  sleep 5
done

# Ρύθμιση Notification - Χρησιμοποιούμε απλή σύνταξη χωρίς πολλά εισαγωγικά
echo "Configuring MinIO RabbitMQ..."
mc admin config set myminio notify_rabbitmq:primary \
  url=amqp://user:password@rabbitmq:5672 \
  exchange=security-exchange \
  exchange_type=topic \
  routing_key=security-event \
  mandatory=off \
  durable=on

# Restart MinIO - Χρησιμοποιούμε το flag --quiet για να μην ζητάει TTY
echo "Restarting MinIO..."
mc admin service restart myminio --quiet
sleep 25

# Επανέλεγχος Alias μετά το restart
mc alias set myminio http://minio:9000 minioadmin minioadmin

# Δημιουργία Bucket
mc mb --ignore-existing myminio/security-photos

# Ενεργοποίηση Event
echo "Setting up bucket event..."
mc event add myminio/security-photos arn:minio:sqs::primary:rabbitmq --event put --suffix .jpg

# Ανέβασμα ήχου
mc cp /project_files/alarm-sound.mp3 myminio/security-photos/
mc anonymous set download myminio/security-photos/alarm-sound.mp3

echo "MINIO SETUP COMPLETE!"