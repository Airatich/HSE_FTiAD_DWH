"""
Kafka Consumer для чтения событий от Debezium
"""
import json
from kafka import KafkaConsumer
from loguru import logger
from datetime import datetime
from config import KAFKA_BOOTSTRAP_SERVERS, KAFKA_TOPIC_PREFIX, KAFKA_CONSUMER_GROUP
from dwh_loader import DWHLoader


class KafkaEventConsumer:
    """Consumer для обработки событий из Kafka"""
    
    def __init__(self):
        self.consumer = None
        self.dwh_loader = DWHLoader()
        self._init_consumer()
    
    def _init_consumer(self):
        """Инициализация Kafka consumer"""
        try:
            self.consumer = KafkaConsumer(
                bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                group_id=KAFKA_CONSUMER_GROUP,
                value_deserializer=lambda m: json.loads(m.decode('utf-8')) if m else None,
                auto_offset_reset='earliest',
                enable_auto_commit=True
                # Убрали consumer_timeout_ms, чтобы consumer работал постоянно
            )
            
            import re
            # Подписываемся на все топики от всех коннекторов (postgres-master, postgres-master-order, postgres-master-logistics)
            # Паттерн: postgres-master.* (включает все варианты)
            escaped_prefix = KAFKA_TOPIC_PREFIX.replace('.', r'\.')
            pattern = re.compile(f"^{escaped_prefix}.*")
            self.consumer.subscribe(pattern=pattern)
            
            logger.info(f"Kafka consumer initialized, subscribed to pattern: {KAFKA_TOPIC_PREFIX}.*")
            logger.info("Will consume from topics: postgres-master.*, postgres-master-order.*, postgres-master-logistics.*")
        except Exception as e:
            logger.error(f"Failed to initialize Kafka consumer: {e}")
            raise
    
    def process_event(self, message):
        """Обработка события от Debezium"""
        try:
            value = message.value
            if not value:
                return
            
            # Unwrap трансформация добавляет __op вместо op
            op = value.get('__op') or value.get('op')
            source = value.get('source', {})
            table = source.get('table')
            
            if not table:
                topic_parts = message.topic.split('.')
                if len(topic_parts) >= 3:
                    table = topic_parts[2]
            
            if not table:
                logger.warning(f"No table information in event. Topic: {message.topic}")
                return
            
            # Логируем операцию для отладки
            logger.debug(f"Event operation: {op}, table: {table}, topic: {message.topic}")
            
            # Если op все еще отсутствует, пытаемся определить по наличию before/after
            if op is None:
                if 'before' in value and 'after' in value:
                    op = 'u'  # Update
                    logger.debug(f"Detected UPDATE by presence of before/after")
                elif 'after' in value and 'before' not in value:
                    op = 'c'  # Create
                    logger.debug(f"Detected INSERT by presence of after only")
                elif 'before' in value and 'after' not in value:
                    op = 'd'  # Delete
                    logger.debug(f"Detected DELETE by presence of before only")
                else:
                    # По умолчанию считаем INSERT
                    op = 'c'
                    logger.debug(f"Defaulting to INSERT")
            
            # Определяем source_system_id по имени базы данных
            db = source.get('db', '')
            from config import SOURCE_SYSTEM_MAPPING
            
            # Сначала пытаемся определить по имени базы данных
            if db in SOURCE_SYSTEM_MAPPING:
                source_system_id = SOURCE_SYSTEM_MAPPING[db]
            # Если не получилось, определяем по имени таблицы (fallback)
            elif table in ['users', 'user_addresses', 'user_status_history']:
                source_system_id = 'user_service'
            elif table in ['orders', 'products', 'order_items', 'order_status_history']:
                source_system_id = 'order_service'
            elif table in ['shipments', 'warehouses', 'pickup_points', 'shipment_movements', 'shipment_status_history']:
                source_system_id = 'logistics_service'
            else:
                source_system_id = 'user_service'  # default
                logger.warning(f"Could not determine source_system_id for db={db}, table={table}, using default: user_service")
            
            logger.debug(f"Determined source_system_id: {source_system_id} for db={db}, table={table}")
            
            # Обрабатываем в зависимости от операции
            if op == 'c' or op is None:  # Create (INSERT)
                data = value.get('after', value)
                self._handle_insert(table, data, source_system_id, source)
            elif op == 'u':  # Update
                logger.info(f"Detected UPDATE operation for table {table}")
                # При unwrap трансформации before/after могут отсутствовать, используем value напрямую
                before = value.get('before', {})
                after = value.get('after', value)  # Если after нет, используем value
                self._handle_update(table, before, after, source_system_id, source)
            elif op == 'd':  # Delete
                logger.info(f"Processing DELETE for table {table} - data preserved in DWH")
            elif op == 'r':  # Read (snapshot)
                data = value.get('after', value)
                self._handle_insert(table, data, source_system_id, source)
            else:
                logger.warning(f"Unknown operation: {op} for table {table}, treating as INSERT")
                data = value.get('after', value)
                self._handle_insert(table, data, source_system_id, source)
        
        except Exception as e:
            logger.error(f"Error processing event: {e}")
            logger.exception(e)
    
    def _handle_insert(self, table: str, data: dict, source_system_id: str, source: dict):
        """Обработка INSERT"""
        logger.info(f"Processing INSERT for table {table}")
        
        from config import BUSINESS_KEY_MAPPING, TABLE_TO_HUB
        business_key_field = BUSINESS_KEY_MAPPING.get(table)
        if not business_key_field:
            logger.warning(f"No business key field for table {table}")
            return
        
        business_key = data.get(business_key_field)
        if not business_key:
            logger.warning(f"No business key value in data for table {table}")
            return
        
        hub_key = self.dwh_loader.load_hub(table, business_key, source_system_id, 'dmp-service')
        if hub_key:
            # Загружаем в саттелит
            hub_name = TABLE_TO_HUB.get(table)
            if hub_name:
                load_date = datetime.fromtimestamp(source.get('ts_ms', 0) / 1000) if source.get('ts_ms') else datetime.now()
                self.dwh_loader.load_satellite(hub_name, hub_key, data, load_date, 'dmp-service')
            logger.info(f"Loaded hub and satellite for {table}: {business_key}")
    
    def _handle_update(self, table: str, before: dict, after: dict, source_system_id: str, source: dict):
        """Обработка UPDATE"""
        logger.info(f"Processing UPDATE for table {table}")
        
        from config import BUSINESS_KEY_MAPPING, TABLE_TO_HUB
        business_key_field = BUSINESS_KEY_MAPPING.get(table)
        if not business_key_field:
            return
        
        business_key = after.get(business_key_field) or before.get(business_key_field)
        if not business_key:
            return
        
        # Находим существующий hub_key
        hub_key = self.dwh_loader._find_hub_key(table, business_key_field, business_key, source_system_id)
        if not hub_key:
            # Если хаб не существует, создаем его
            hub_key = self.dwh_loader.load_hub(table, business_key, source_system_id, 'dmp-service')
        
        if hub_key:
            # Создаем новую версию в саттелите (при UPDATE закрываем старую версию)
            hub_name = TABLE_TO_HUB.get(table)
            if hub_name:
                # Используем __source_ts_ms из unwrap трансформации или source.ts_ms
                ts_ms = after.get('__source_ts_ms') or source.get('ts_ms')
                if ts_ms:
                    load_date = datetime.fromtimestamp(float(ts_ms) / 1000)
                else:
                    load_date = datetime.now()
                self.dwh_loader.load_satellite(hub_name, hub_key, after, load_date, 'dmp-service', is_update=True)
                logger.info(f"Updated satellite for {table}: {business_key}")
    
    def start(self):
        """Запуск consumer"""
        logger.info("Starting Kafka consumer...")
        logger.info(f"Waiting for messages from topics matching pattern: {KAFKA_TOPIC_PREFIX}.*")
        try:
            for message in self.consumer:
                if message.value:
                    logger.debug(f"Received message from topic {message.topic}, partition {message.partition}")
                    self.process_event(message)
        except KeyboardInterrupt:
            logger.info("Stopping consumer...")
        except Exception as e:
            logger.error(f"Error in consumer loop: {e}")
            logger.exception(e)
        finally:
            self.close()
    
    def close(self):
        """Закрытие consumer"""
        if self.consumer:
            self.consumer.close()
        if self.dwh_loader:
            self.dwh_loader.close()
        logger.info("Consumer closed")


if __name__ == '__main__':
    consumer = KafkaEventConsumer()
    consumer.start()

