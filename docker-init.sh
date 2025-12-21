echo "Stopping containers..."
docker compose down


# Удаляем папки полностью, чтобы PostgreSQL выполнил инициализацию заново
echo "Removing data directories..."
# Удаляем полностью директории, включая все содержимое
rm -rf ./data
rm -rf ./replica_data
rm -rf ./dwh_data
rm -rf ./airflow_data

# Убеждаемся, что директории полностью удалены
sleep 1

# Создаем пустые директории (нужно для монтирования volumes)
echo "Creating empty data directories..."
mkdir -p ./data
mkdir -p ./replica_data
mkdir -p ./dwh_data
mkdir -p ./airflow_data
mkdir -p ./grafana_data



docker compose up -d postgres-master

echo "Starting postgres_master node..."
sleep 10  # Waits for master note start complete

echo "Prepare replica config..."
docker exec hw1-postgres-master sh /etc/postgresql/init-script/init.sh > /dev/null 2>&1

echo "Copying pg_hba.conf to data directory..."
# Копируем pg_hba.conf в data директорию, чтобы PostgreSQL его использовал
docker exec hw1-postgres-master cp /etc/postgresql/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf

echo "Reloading PostgreSQL configuration..."
# Перезагружаем конфигурацию PostgreSQL, чтобы применить pg_hba.conf
docker exec hw1-postgres-master psql -U postgres -c "SELECT pg_reload_conf();" > /dev/null 2>&1

echo "Restart master node"
docker compose restart postgres-master
sleep 10

echo "Creating replica backup..."
# Создаем backup master'а для реплики
docker exec hw1-postgres-master pg_basebackup -D /var/lib/postgresql/data-replica -S replication_slot_1 -X stream -P -U replicator -Fp -R
# Копируем backup в volume реплики
docker cp hw1-postgres-master:/var/lib/postgresql/data-replica/. ./replica_data/
# Исправляем primary_conninfo для Docker сети
cat > ./replica_data/postgresql.auto.conf << 'EOF'
primary_conninfo = 'host=postgres-master port=5432 user=replicator password=my_replicator_password'
primary_slot_name = 'replication_slot_1'
EOF

echo "Starting replica node..."
docker compose up -d postgres-replica
sleep 10  # Waits for note start complete

echo "Starting DWH node..."
docker compose up -d postgres-dwh
sleep 10  # Waits for DWH node start complete

echo "Initializing source systems in DWH..."
sleep 5
docker exec hw1-postgres-dwh psql -U postgres -c "SELECT * FROM dwh_detailed.hub_source_system;" || echo "DWH initialization in progress..."

echo "Setting up Debezium..."
# Создаем publications во всех базах данных
echo "Creating publication in user_service_db..."
docker exec hw1-postgres-master psql -U postgres -d user_service_db -c "
DROP PUBLICATION IF EXISTS debezium_publication;
CREATE PUBLICATION debezium_publication FOR ALL TABLES;
" 2>/dev/null || echo "Publication setup in progress..."

echo "Creating publication in order_service_db..."
docker exec hw1-postgres-master psql -U postgres -d order_service_db -c "
DROP PUBLICATION IF EXISTS debezium_publication_order;
CREATE PUBLICATION debezium_publication_order FOR ALL TABLES;
" 2>/dev/null || echo "Publication setup in progress..."

echo "Creating publication in logistics_service_db..."
docker exec hw1-postgres-master psql -U postgres -d logistics_service_db -c "
DROP PUBLICATION IF EXISTS debezium_publication_logistics;
CREATE PUBLICATION debezium_publication_logistics FOR ALL TABLES;
" 2>/dev/null || echo "Publication setup in progress..."

echo "Starting Kafka and Debezium..."
docker compose up -d zookeeper kafka debezium-connect

echo "Waiting for Kafka and Debezium to be ready..."
# Ждем, пока Kafka будет готов
for i in {1..30}; do
    if docker exec hw1-kafka kafka-broker-api-versions --bootstrap-server localhost:9092 >/dev/null 2>&1; then
        echo "Kafka is ready"
        break
    fi
    echo "Waiting for Kafka... ($i/30)"
    sleep 2
done

# Ждем, пока Debezium Connect будет готов
echo "Waiting for Debezium Connect to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:8083/connectors >/dev/null 2>&1; then
        echo "Debezium Connect is ready"
        break
    fi
    echo "Waiting for Debezium Connect... ($i/60)"
    sleep 2
done

echo "Registering Debezium connectors..."
# Удаляем существующие коннекторы, чтобы snapshot выполнился заново
echo "Removing existing connectors (if any)..."
curl -X DELETE http://localhost:8083/connectors/postgres-connector 2>/dev/null || true
curl -X DELETE http://localhost:8083/connectors/postgres-connector-order-service 2>/dev/null || true
curl -X DELETE http://localhost:8083/connectors/postgres-connector-logistics-service 2>/dev/null || true
sleep 3

echo "Registering user_service connector (with initial snapshot)..."
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @debezium/connectors/postgres-connector.json || echo "User service connector registration failed"

sleep 2

echo "Registering order_service connector (with initial snapshot)..."
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @debezium/connectors/postgres-connector-order-service.json || echo "Order service connector registration failed"

sleep 2

echo "Registering logistics_service connector (with initial snapshot)..."
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @debezium/connectors/postgres-connector-logistics-service.json || echo "Logistics service connector registration failed"

echo "Waiting for initial snapshots to complete (this may take a while)..."
sleep 30  # Увеличиваем время ожидания для завершения snapshot

echo "Starting DMP Service..."
docker compose up -d dmp-service
sleep 10  # Даем время DMP Service запуститься

echo "Waiting for DMP Service to process initial data..."
sleep 20  # Даем время обработать initial snapshot

echo "Starting Airflow..."
echo "Starting postgres-airflow..."
docker compose up -d postgres-airflow
sleep 5

echo "Waiting for postgres-airflow to be ready..."
for i in {1..30}; do
    if docker exec hw1-postgres-airflow pg_isready -U airflow >/dev/null 2>&1; then
        echo "postgres-airflow is ready"
        break
    fi
    echo "Waiting for postgres-airflow... ($i/30)"
    sleep 2
done

echo "Initializing Airflow database..."
docker compose up airflow-init
sleep 5

echo "Starting Airflow webserver and scheduler..."
docker compose up -d airflow-webserver airflow-scheduler

echo "Waiting for Airflow webserver to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        echo "Airflow webserver is ready"
        break
    fi
    echo "Waiting for Airflow webserver... ($i/60)"
    sleep 2
done

echo "Starting Grafana..."
docker compose up -d grafana
sleep 5

echo "Waiting for Grafana to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
        echo "Grafana is ready"
        break
    fi
    echo "Waiting for Grafana... ($i/30)"
    sleep 2
done

echo "Done"
echo ""
echo "All services are up and running!"
echo "Airflow UI: http://localhost:8080 (admin/admin)"
echo "Grafana UI: http://localhost:3000 (admin/admin)"