"""
DAG для обновления витрины "Доставка по складам"
Обновляет данные за вчерашний день каждый день
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import psycopg2

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def refresh_warehouse_delivery(**context):
    """
    Обновление витрины "Доставка по складам"
    Обновляет данные за вчерашний день (execution_date - 1 день)
    При перезапуске удаляет предыдущие данные за этот день
    """
    # Подключение к DWH PostgreSQL
    conn = psycopg2.connect(
        host='postgres-dwh',
        port=5432,
        database='postgres',
        user='postgres',
        password='postgres'
    )
    
    # execution_date - это дата выполнения DAG
    # Для ежедневного обновления за вчера используем execution_date.date()
    execution_date = context.get('execution_date')
    # business_date = execution_date.date() if execution_date else (datetime.now() - timedelta(days=1)).date()
    # date_from = business_date - timedelta(days=7)
    
    print(f"Обновление витрины 'Доставка по складам'")
    
    sql = f"""
    -- Удаление данных за указанный период (избегаем дублей при перезапуске)
    DELETE FROM presentation.warehouse_delivery;
    
    -- Заполнение витрины данными за указанную дату
    -- Используем link_shipment_warehouse, hub_warehouse, sat_warehouse_details, link_shipment_order, link_order_user, sat_order_item_details
    INSERT INTO presentation.warehouse_delivery (
        shipment_date,
        warehouse_id,
        warehouse_name,
        order_count,
        total_shipment_qty,
        avg_processing_time_min,
        delayed_orders_count,
        unique_customers_count
    )
    SELECT 
        DATE(sd.created_date) AS shipment_date,
        ABS(('x' || substr(md5(COALESCE(hw.warehouse_code, 'UNKNOWN')), 1, 8))::bit(32)::int) AS warehouse_id,
        COALESCE(swd.warehouse_name, hw.warehouse_code, 'Unknown Warehouse') AS warehouse_name,
        COUNT(DISTINCT lso.hub_order_key) AS order_count,
        COALESCE(SUM(soid.quantity), 0) AS total_shipment_qty,
        AVG(
            CASE 
                WHEN sd.dispatched_date IS NOT NULL AND sd.created_date IS NOT NULL
                THEN EXTRACT(EPOCH FROM (sd.dispatched_date - sd.created_date)) / 60.0
                ELSE NULL
            END
        ) AS avg_processing_time_min,
        COUNT(DISTINCT CASE 
            WHEN sd.actual_delivery_date IS NOT NULL 
                AND sd.estimated_delivery_date IS NOT NULL
                AND sd.actual_delivery_date > sd.estimated_delivery_date 
            THEN hs.hub_shipment_key 
        END) AS delayed_orders_count,
        COUNT(DISTINCT lou.hub_user_key) AS unique_customers_count
    FROM dwh_detailed.hub_shipment hs
    INNER JOIN dwh_detailed.sat_shipment_details sd 
        ON hs.hub_shipment_key = sd.hub_shipment_key 
        AND sd.load_end_date IS NULL
    LEFT JOIN dwh_detailed.link_shipment_warehouse lsw
        ON hs.hub_shipment_key = lsw.hub_shipment_key
    LEFT JOIN dwh_detailed.hub_warehouse hw
        ON lsw.hub_warehouse_key = hw.hub_warehouse_key
    LEFT JOIN dwh_detailed.sat_warehouse_details swd
        ON hw.hub_warehouse_key = swd.hub_warehouse_key
        AND swd.load_end_date IS NULL
    LEFT JOIN dwh_detailed.link_shipment_order lso
        ON hs.hub_shipment_key = lso.hub_shipment_key
    LEFT JOIN dwh_detailed.link_order_item loi
        ON lso.hub_order_key = loi.hub_order_key
    LEFT JOIN dwh_detailed.sat_order_item_details soid
        ON loi.link_order_item_key = soid.link_order_item_key
        AND soid.load_end_date IS NULL
    LEFT JOIN dwh_detailed.link_order_user lou
        ON lso.hub_order_key = lou.hub_order_key
    GROUP BY 
        DATE(sd.created_date),
        hw.warehouse_code,
        swd.warehouse_name;
    """
    
    try:
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
        print(f"Витрина 'Доставка по складам' успешно обновлена")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

with DAG(
    'warehouse_delivery_refresh',
    default_args=default_args,
    description='Обновление витрины "Доставка по складам"',
    schedule_interval='0 3 * * *',  # Каждый день в 3:00 (обновляем за вчера)
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['presentation', 'warehouse_delivery'],
) as dag:

    refresh_task = PythonOperator(
        task_id='refresh_warehouse_delivery',
        python_callable=refresh_warehouse_delivery,
    )

    refresh_task

