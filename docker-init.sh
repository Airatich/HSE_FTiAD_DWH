echo "Clearing data"
rm -rf ./data/*
rm -rf ./replica_data/*
docker compose down

docker compose up -d postgres-master

echo "Starting postgres_master node..."
sleep 10  # Waits for master note start complete

echo "Prepare replica config..."
docker exec hw1-postgres-master sh /etc/postgresql/init-script/init.sh
echo "Restart master node"
docker compose restart postgres-master
sleep 10

echo "Starting replica node..."
docker compose up -d postgres-replica
sleep 10  # Waits for note start complete

echo "Done"