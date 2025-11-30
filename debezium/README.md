# Debezium Configuration

## Описание

Debezium настроен для отслеживания изменений в PostgreSQL и отправки их в Kafka.

## Компоненты

- **Zookeeper** (порт 2181) - координация Kafka
- **Kafka** (порт 9092) - брокер сообщений
- **Debezium Connect** (порт 8083) - коннектор для PostgreSQL

## Регистрация connector

```bash
curl -X POST -H "Content-Type: application/json" -d @debezium/connectors/postgres-connector.json http://localhost:8083/connectors
```

## Проверка статуса

```bash
curl http://localhost:8083/connectors/postgres-connector/status
```

