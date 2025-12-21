"""
DWH Loader для загрузки данных в Data Vault 2.0
"""
import hashlib
import psycopg2
from datetime import datetime
from loguru import logger
from config import DWH_HOST, DWH_PORT, DWH_DATABASE, DWH_USER, DWH_PASSWORD, DWH_SCHEMA, TABLE_TO_HUB, BUSINESS_KEY_MAPPING

class DWHLoader:
    """Класс для загрузки данных в Data Vault 2.0 DWH"""
    
    def __init__(self):
        self.conn = None
        self.cursor = None
        self._connect()
    
    def _connect(self):
        """Подключение к DWH"""
        try:
            self.conn = psycopg2.connect(
                host=DWH_HOST,
                port=DWH_PORT,
                database=DWH_DATABASE,
                user=DWH_USER,
                password=DWH_PASSWORD
            )
            self.cursor = self.conn.cursor()
            logger.info(f"Connected to DWH at {DWH_HOST}:{DWH_PORT}")
        except Exception as e:
            logger.error(f"Failed to connect to DWH: {e}")
            raise
    
    def _generate_hash_key(self, *args):
        """Генерация MD5 хеша для ключа"""
        key_string = '|'.join(str(arg) for arg in args if arg is not None)
        return hashlib.md5(key_string.encode('utf-8')).hexdigest()
    
    def load_hub(self, table_name: str, business_key: str, source_system_id: str, record_source: str):
        """Загрузка в хаб"""
        hub_name = self._get_hub_name(table_name)
        if not hub_name:
            return None
        
        hub_key = self._generate_hash_key(business_key, source_system_id)
        
        # Получаем hub_source_system_key
        source_system_key = self._get_source_system_key(source_system_id)
        if not source_system_key:
            logger.warning(f"Source system {source_system_id} not found")
            return None
        
        try:
            business_key_field = BUSINESS_KEY_MAPPING.get(table_name, f"{table_name}_external_id")
            self.cursor.execute(
                f"""
                INSERT INTO {DWH_SCHEMA}.{hub_name} 
                (hub_{hub_name.replace('hub_', '')}_key, {business_key_field}, source_system_id, hub_source_system_key, load_date, record_source)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT DO NOTHING
                """,
                (hub_key, business_key, source_system_id, source_system_key, datetime.now(), record_source)
            )
            self.conn.commit()
            logger.info(f"Loaded hub {hub_name} for {business_key}")
            return hub_key
        except Exception as e:
            logger.error(f"Error loading hub {hub_name}: {e}")
            self.conn.rollback()
            return None
    
    def _get_hub_name(self, table_name: str) -> str:
        """Получение имени хаба по имени таблицы"""
        return TABLE_TO_HUB.get(table_name, None)
    
    def _get_source_system_key(self, source_system_id: str) -> str:
        """Получение ключа системы-источника"""
        try:
            self.cursor.execute(
                f"SELECT hub_source_system_key FROM {DWH_SCHEMA}.hub_source_system WHERE source_system_id = %s",
                (source_system_id,)
            )
            result = self.cursor.fetchone()
            return result[0] if result else None
        except Exception as e:
            logger.error(f"Error getting source system key: {e}")
            return None
    
    def load_satellite(self, hub_name: str, hub_key: str, data: dict, load_date: datetime, record_source: str, is_update: bool = False):
        """Загрузка в саттелит"""
        # Определяем имя саттелита по имени хаба
        sat_mapping = {
            'hub_user': 'sat_user_details',
            'hub_address': 'sat_user_address_details',
            'hub_order': 'sat_order_details',
            'hub_product': 'sat_product_details',
            'hub_shipment': 'sat_shipment_details',
            'hub_warehouse': 'sat_warehouse_details',
            'hub_pickup_point': 'sat_pickup_point_details'
        }
        
        sat_name = sat_mapping.get(hub_name)
        if not sat_name:
            logger.warning(f"No satellite mapping for hub {hub_name}")
            return
        
        # Определяем поля для саттелита
        sat_fields_map = {
            'sat_user_details': {
                'email', 'first_name', 'last_name', 'phone', 'date_of_birth',
                'registration_date', 'status', 'effective_from', 'effective_to',
                'is_current', 'created_at', 'updated_at', 'created_by', 'updated_by'
            },
            'sat_user_address_details': {
                'address_line1', 'address_line2', 'city', 'region', 'postal_code',
                'country', 'address_type', 'is_default', 'effective_from', 'effective_to',
                'is_current', 'created_at', 'updated_at', 'created_by', 'updated_by'
            },
            'sat_order_details': {
                'order_number', 'order_date', 'status', 'delivery_type',
                'expected_delivery_date', 'actual_delivery_date', 'payment_method',
                'payment_status', 'effective_from', 'effective_to', 'is_current',
                'created_at', 'updated_at', 'created_by', 'updated_by'
            },
            'sat_product_details': {
                'product_name', 'category', 'brand', 'weight_grams',
                'dimensions_length_cm', 'dimensions_width_cm', 'dimensions_height_cm',
                'is_active', 'effective_from', 'effective_to', 'is_current',
                'created_at', 'updated_at', 'created_by', 'updated_by'
            },
            'sat_shipment_details': {
                'tracking_number', 'status', 'weight_grams', 'volume_cubic_cm',
                'package_count', 'destination_type', 'created_date', 'dispatched_date',
                'estimated_delivery_date', 'actual_delivery_date', 'delivery_notes',
                'recipient_name', 'delivery_signature', 'effective_from', 'effective_to',
                'is_current', 'created_at', 'updated_at', 'created_by', 'updated_by'
            },
            'sat_warehouse_details': {
                'warehouse_name', 'warehouse_type', 'address', 'city', 'region',
                'postal_code', 'country', 'latitude', 'longitude', 'capacity_cubic_meters',
                'is_active', 'effective_from', 'effective_to', 'is_current',
                'created_at', 'updated_at', 'created_by', 'updated_by'
            },
            'sat_pickup_point_details': {
                'pickup_point_name', 'pickup_point_type', 'country', 'region', 'city',
                'street_address', 'postal_code', 'is_active', 'max_capacity_packages',
                'operating_hours', 'contact_phone', 'partner_name', 'effective_from',
                'effective_to', 'is_current', 'created_at', 'updated_at', 'created_by', 'updated_by'
            }
        }
        
        # Если маппинга нет, используем все поля из data (кроме служебных)
        fields = sat_fields_map.get(sat_name, set())
        if not fields:
            # Используем все поля, кроме служебных
            exclude_fields = {'id', 'hub_key', 'load_date', 'record_source', 'load_end_date', 
                            'shipment_id', 'order_id', 'product_id', 'user_id', 'warehouse_id',
                            'pickup_point_id', 'address_id', 'shipment_external_id', 'order_external_id',
                            'user_external_id', 'product_sku', 'warehouse_code', 'pickup_point_code',
                            'address_external_id'}
            fields = set(data.keys()) - exclude_fields
            logger.debug(f"No explicit field mapping for {sat_name}, using all fields except: {exclude_fields}")
        sat_fields = {}
        
        # Извлекаем поля из данных
        for field in fields:
            if field in data and data[field] is not None:
                value = data[field]
                # Преобразуем даты и timestamp
                date_fields = ['date_of_birth', 'registration_date', 'effective_from', 'effective_to', 
                              'created_at', 'updated_at', 'order_date', 'created_date', 'dispatched_date',
                              'estimated_delivery_date', 'actual_delivery_date', 'expected_delivery_date']
                if field in date_fields:
                    original_value = value
                    if isinstance(value, (int, float)):
                        # Специальная обработка для date_of_birth (может быть в формате дней с 2000-01-01)
                        if field == 'date_of_birth' and 0 < value < 100000:  # Вероятно, это дни
                            try:
                                from datetime import date, timedelta
                                base_date = date(2000, 1, 1)
                                value = base_date + timedelta(days=int(value))
                                logger.debug(f"Converted {field} from {original_value} (days since 2000-01-01) to {value}")
                            except Exception as e:
                                logger.warning(f"Failed to convert {field} from {original_value} (days): {e}")
                        # Проверяем диапазон для timestamp
                        # Текущий timestamp в секундах: ~1.7e9 (2024 год)
                        # Текущий timestamp в миллисекундах: ~1.7e12
                        # Текущий timestamp в микросекундах: ~1.7e15
                        elif 1e9 <= value < 1e12:  # Секунды (примерно 2001-2286 год)
                            try:
                                value = datetime.fromtimestamp(float(value))
                                logger.debug(f"Converted {field} from {original_value} (seconds) to {value}")
                            except (ValueError, OSError) as e:
                                logger.warning(f"Failed to convert {field} from {original_value} (seconds): {e}")
                        elif 1e12 <= value < 1e15:  # Миллисекунды (примерно 2001-2286 год)
                            try:
                                value = datetime.fromtimestamp(float(value) / 1000)
                                logger.debug(f"Converted {field} from {original_value} (milliseconds) to {value}")
                            except (ValueError, OSError) as e:
                                logger.warning(f"Failed to convert {field} from {original_value} (milliseconds): {e}")
                        elif 1e15 <= value < 1e18:  # Микросекунды (примерно 2001-2286 год)
                            try:
                                value = datetime.fromtimestamp(float(value) / 1000000)
                                logger.debug(f"Converted {field} from {original_value} (microseconds) to {value}")
                            except (ValueError, OSError) as e:
                                logger.warning(f"Failed to convert {field} from {original_value} (microseconds): {e}")
                        else:
                            # Если значение вне диапазона, оставляем как есть (может быть другой формат)
                            logger.warning(f"Field {field} value {original_value} is outside expected timestamp range")
                    elif isinstance(value, str):
                        try:
                            # Пробуем разные форматы
                            for fmt in ['%Y-%m-%d', '%Y-%m-%d %H:%M:%S', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%dT%H:%M:%S.%f', '%Y-%m-%d %H:%M:%S.%f', '%Y-%m-%dT%H:%M:%S.%fZ']:
                                try:
                                    value = datetime.strptime(value, fmt)
                                    logger.debug(f"Converted {field} from string '{original_value}' to {value}")
                                    break
                                except ValueError:
                                    continue
                        except Exception as e:
                            logger.debug(f"Failed to parse {field} string value: {e}")
                sat_fields[field] = value
        
        if not sat_fields:
            logger.warning(f"No satellite fields extracted for {sat_name}")
            return
        
        try:
            hub_key_field = f"{hub_name.replace('hub_', 'hub_')}_key"
            
            # Если это UPDATE, закрываем предыдущую версию
            if is_update:
                self.cursor.execute(
                    f"""
                    UPDATE {DWH_SCHEMA}.{sat_name}
                    SET load_end_date = %s
                    WHERE {hub_key_field} = %s 
                      AND load_end_date IS NULL
                    """,
                    (load_date, hub_key)
                )
                logger.info(f"Closed previous version in {sat_name} for hub {hub_name}")
            
            # Формируем INSERT для новой версии
            fields_list = [hub_key_field, 'load_date', 'record_source'] + list(sat_fields.keys())
            values_list = [hub_key, load_date, record_source] + list(sat_fields.values())
            
            placeholders = ', '.join(['%s'] * len(fields_list))
            field_names = ', '.join(fields_list)
            
            self.cursor.execute(
                f"""
                INSERT INTO {DWH_SCHEMA}.{sat_name} ({field_names})
                VALUES ({placeholders})
                ON CONFLICT ({hub_key_field}, load_date) DO NOTHING
                """,
                values_list
            )
            self.conn.commit()
            logger.info(f"Loaded satellite {sat_name} for hub {hub_name}")
        except Exception as e:
            logger.error(f"Error loading satellite {sat_name}: {e}")
            logger.exception(e)
            self.conn.rollback()
    
    def _find_hub_key(self, table_name: str, business_key_field: str, business_key: str, source_system_id: str) -> str:
        """Поиск существующего hub_key"""
        hub_name = self._get_hub_name(table_name)
        if not hub_name:
            return None
        
        try:
            self.cursor.execute(
                f"SELECT hub_{hub_name.replace('hub_', '')}_key FROM {DWH_SCHEMA}.{hub_name} WHERE {business_key_field} = %s AND source_system_id = %s",
                (business_key, source_system_id)
            )
            result = self.cursor.fetchone()
            return result[0] if result else None
        except Exception as e:
            logger.error(f"Error finding hub key: {e}")
            return None
    
    def close(self):
        """Закрытие соединения"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("DWH connection closed")
