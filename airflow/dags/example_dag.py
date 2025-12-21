"""
Пример DAG для Apache Airflow
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def print_hello():
    """Простая Python функция"""
    print("Hello from Airflow!")
    return "Hello World!"

with DAG(
    'example_dag',
    default_args=default_args,
    description='Пример DAG для тестирования Airflow',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['example'],
) as dag:

    t1 = BashOperator(
        task_id='print_date',
        bash_command='date',
    )

    t2 = PythonOperator(
        task_id='print_hello',
        python_callable=print_hello,
    )

    t3 = BashOperator(
        task_id='echo_info',
        bash_command='echo "Airflow is running!"',
    )

    t1 >> t2 >> t3

