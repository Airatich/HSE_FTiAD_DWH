# DMP Service

Data Management Platform Service - сервис для загрузки данных из Kafka (от Debezium) в Data Vault 2.0 DWH.

## Описание

DMP-сервис читает события изменений из Kafka (которые отправляет Debezium) и загружает их в Data Vault 2.0 структуру DWH.

## Запуск

Сервис запускается автоматически через docker-compose:

```bash
docker compose up -d dmp-service
```

## Логи

```bash
docker logs hw1-dmp-service -f
```

