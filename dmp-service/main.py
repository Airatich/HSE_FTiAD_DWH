"""
DMP Service - Data Management Platform Service
Загружает данные из Kafka (от Debezium) в Data Vault 2.0 DWH
"""
from loguru import logger
from kafka_consumer import KafkaEventConsumer

if __name__ == '__main__':
    logger.info("Starting DMP Service...")
    consumer = KafkaEventConsumer()
    consumer.start()

