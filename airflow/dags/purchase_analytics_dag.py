"""
DAG для обновления витрины "Аналитика закупок"
Обновляется полностью 1 раз в день
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

def refresh_purchase_analytics(**context):
    """
    Обновление витрины "Аналитика закупок"
    Витрина полностью пересчитывается каждый день
    """
    # Подключение к DWH PostgreSQL
    conn = psycopg2.connect(
        host='postgres-dwh',
        port=5432,
        database='postgres',
        user='postgres',
        password='postgres'
    )
    
    sql = """
    -- Очистка витрины перед полным обновлением
    TRUNCATE TABLE presentation.purchase_analytics;
    
    -- Заполнение витрины данными из детального слоя DWH
    -- Используем link_order_item, sat_order_item_details, sat_order_details, hub_product, sat_product_details
    INSERT INTO presentation.purchase_analytics (
        purchase_date,
        product_id,
        product_name,
        category,
        supplier_id,
        supplier_name,
        purchase_qty,
        total_purchase_amount,
        avg_unit_price
    )
    SELECT 
        DATE(COALESCE(od.order_date, soid.created_at, soid.load_date)) AS purchase_date,
        ABS(('x' || substr(md5(COALESCE(hp.product_sku, 'UNKNOWN')), 1, 8))::bit(32)::int) AS product_id,
        MAX(COALESCE(spd.product_name, soid.product_name_snapshot, hp.product_sku)) AS product_name,
        MAX(COALESCE(spd.category, soid.product_category_snapshot, 'Unknown')) AS category,
        ABS(('x' || substr(md5(COALESCE(MAX(spd.brand), MAX(soid.product_brand_snapshot), 'UNKNOWN')), 1, 8))::bit(32)::int) AS supplier_id,
        MAX(COALESCE(spd.brand, soid.product_brand_snapshot, 'Unknown')) AS supplier_name,
        SUM(COALESCE(soid.quantity, 0)) AS purchase_qty,
        SUM(COALESCE(soid.total_price, 0)) AS total_purchase_amount,
        AVG(COALESCE(soid.unit_price, 0)) AS avg_unit_price
    FROM dwh_detailed.link_order_item loi
    INNER JOIN dwh_detailed.sat_order_item_details soid 
        ON loi.link_order_item_key = soid.link_order_item_key 
        AND soid.load_end_date IS NULL
    INNER JOIN dwh_detailed.hub_product hp 
        ON loi.hub_product_key = hp.hub_product_key
    LEFT JOIN dwh_detailed.sat_product_details spd 
        ON hp.hub_product_key = spd.hub_product_key 
        AND spd.load_end_date IS NULL
    LEFT JOIN dwh_detailed.hub_order ho 
        ON loi.hub_order_key = ho.hub_order_key
    LEFT JOIN dwh_detailed.sat_order_details od 
        ON ho.hub_order_key = od.hub_order_key 
        AND od.load_end_date IS NULL
    WHERE COALESCE(od.order_date, soid.created_at, soid.load_date) IS NOT NULL
    GROUP BY 
        DATE(COALESCE(od.order_date, soid.created_at, soid.load_date)),
        hp.product_sku;
    """
    
    try:
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
        print("Витрина 'Аналитика закупок' успешно обновлена")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

with DAG(
    'purchase_analytics_refresh',
    default_args=default_args,
    description='Обновление витрины "Аналитика закупок" - полное обновление 1 раз в день',
    schedule_interval='0 2 * * *',  # Каждый день в 2:00
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['presentation', 'purchase_analytics'],
) as dag:

    refresh_task = PythonOperator(
        task_id='refresh_purchase_analytics',
        python_callable=refresh_purchase_analytics,
    )

    refresh_task

