#!/bin/sh
apk add --no-cache curl

echo "Waiting for RabbitMQ API..."
until curl -s -u user:password http://rabbitmq:15672/api/overview > /dev/null; do
  sleep 5
done

echo "Creating RabbitMQ Infrastructure..."
# Exchange
curl -s -u user:password -X PUT http://rabbitmq:15672/api/exchanges/%2f/security-exchange -H "content-type:application/json" -d '{"type":"topic","durable":true}'
# Queue
curl -s -u user:password -X PUT http://rabbitmq:15672/api/queues/%2f/security-queue -H "content-type:application/json" -d '{"durable":true,"auto_delete":false}'
# Binding
curl -s -u user:password -X POST http://rabbitmq:15672/api/bindings/%2f/e/security-exchange/q/security-queue -H "content-type:application/json" -d '{"routing_key":"security-event"}'

echo "RabbitMQ Setup Complete!"

exit 0