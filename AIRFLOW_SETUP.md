# Apache Airflow - Инструкция по запуску

## Быстрый старт

Все сервисы, включая Apache Airflow, запускаются одной командой:

```bash
docker-compose up -d
```

## Доступ к Airflow

После запуска (подождите ~30-60 секунд для инициализации):

- **Web UI**: http://localhost:8080
- **Логин**: `admin`
- **Пароль**: `admin`

## Структура Airflow

```
airflow/
├── dags/          # Ваши DAG файлы
├── logs/          # Логи выполнения
├── plugins/       # Плагины
└── config/        # Конфигурация
```

## Добавление DAG

Просто добавьте Python файл в `airflow/dags/` и он автоматически появится в UI.

Пример DAG уже есть в `airflow/dags/example_dag.py`.

## Порты

- **Airflow Web UI**: 8080
- **PostgreSQL Airflow**: 5435
- **PostgreSQL Master**: 2222
- **PostgreSQL Replica**: 5433
- **PostgreSQL DWH**: 5434
- **Kafka**: 9092
- **Debezium Connect**: 8083
- **Zookeeper**: 2181

## Остановка

```bash
docker-compose down
```

## Полная очистка (включая данные Airflow)

```bash
docker-compose down -v
rm -rf airflow_data airflow/logs
```

## Troubleshooting

Если Airflow не запускается:

1. Проверьте логи: `docker logs hw1-airflow-webserver`
2. Убедитесь, что `airflow-init` завершился успешно: `docker logs hw1-airflow-init`
3. Проверьте, что PostgreSQL для Airflow запущен: `docker ps | grep postgres-airflow`

