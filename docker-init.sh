echo "Clearing data"
rm -rf ./data/*
rm -rf ./replica_data/*
docker compose down

docker compose up -d postgres-master

echo "Starting postgres_master node..."
sleep 10  # Waits for master note start complete

echo "Prepare replica config..."
docker exec hw1-postgres-master sh /etc/postgresql/init-script/init.sh > /dev/null 2>&1
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
rm -rf ./dwh_data/*
docker compose up -d postgres-dwh
sleep 10  # Waits for DWH node start complete

echo "Initializing source systems in DWH..."
sleep 5
docker exec hw1-postgres-dwh psql -U postgres -c "SELECT * FROM dwh_detailed.hub_source_system;" || echo "DWH initialization in progress..."

echo "Setting up Debezium..."
# Создаем publication в базе user_service_db (Debezium создаст slot автоматически)
docker exec hw1-postgres-master psql -U postgres -d user_service_db -c "
DROP PUBLICATION IF EXISTS debezium_publication;
CREATE PUBLICATION debezium_publication FOR ALL TABLES;
" 2>/dev/null || echo "Publication setup in progress..."

echo "Starting Kafka and Debezium..."
docker compose up -d zookeeper kafka debezium-connect
sleep 15  # Ждем запуска Kafka и Debezium

echo "Registering Debezium connector..."
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @debezium/connectors/postgres-connector.json || echo "Connector registration will be done manually"

echo "Starting DMP Service..."
docker compose up -d dmp-service
sleep 5

echo "Done"