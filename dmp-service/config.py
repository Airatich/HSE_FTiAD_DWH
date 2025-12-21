"""
Конфигурация DMP-сервиса
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Kafka настройки
KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
# Подписываемся на все топики от всех коннекторов
KAFKA_TOPIC_PREFIX = os.getenv('KAFKA_TOPIC_PREFIX', 'postgres-master')
KAFKA_CONSUMER_GROUP = os.getenv('KAFKA_CONSUMER_GROUP', 'dmp-service-group')

# PostgreSQL DWH настройки
DWH_HOST = os.getenv('DWH_HOST', 'localhost')
DWH_PORT = os.getenv('DWH_PORT', '5434')
DWH_DATABASE = os.getenv('DWH_DATABASE', 'postgres')
DWH_USER = os.getenv('DWH_USER', 'postgres')
DWH_PASSWORD = os.getenv('DWH_PASSWORD', 'postgres')
DWH_SCHEMA = 'dwh_detailed'

# Маппинг систем-источников
SOURCE_SYSTEM_MAPPING = {
    'user_service_db': 'user_service',
    'order_service_db': 'order_service',
    'logistics_service_db': 'logistics_service'
}

# Маппинг таблиц к хабам
TABLE_TO_HUB = {
    'users': 'hub_user',
    'user_addresses': 'hub_address',
    'orders': 'hub_order',
    'products': 'hub_product',
    'shipments': 'hub_shipment',
    'warehouses': 'hub_warehouse',
    'pickup_points': 'hub_pickup_point'
}

# Маппинг бизнес-ключей
BUSINESS_KEY_MAPPING = {
    'users': 'user_external_id',
    'user_addresses': 'address_external_id',
    'orders': 'order_external_id',
    'products': 'product_sku',
    'shipments': 'shipment_external_id',
    'warehouses': 'warehouse_code',
    'pickup_points': 'pickup_point_code'
}

