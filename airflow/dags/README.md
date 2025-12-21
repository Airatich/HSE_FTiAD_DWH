# DAGs для обновления витрин данных

## Витрина 1: Аналитика закупок

**DAG**: `purchase_analytics_refresh`

**Расписание**: Каждый день в 2:00

**Описание**: Полное обновление витрины с данными о закупках товаров. Витрина полностью пересчитывается каждый день.

**Источники данных**:
- `dwh_detailed.hub_order` - заказы
- `dwh_detailed.sat_order_details` - детали заказов (дата заказа)
- `dwh_detailed.link_order_item` - связь заказов и товаров
- `dwh_detailed.sat_order_item_details` - детали позиций заказов (количество, цена)
- `dwh_detailed.hub_product` - товары
- `dwh_detailed.sat_product_details` - детали товаров (название, категория, бренд)

**Примечание**: В качестве поставщика используется поле `brand` из `sat_product_details`, так как в текущей структуре DWH нет отдельной таблицы поставщиков.

## Витрина 2: Доставка по складам

**DAG**: `warehouse_delivery_refresh`

**Расписание**: Каждый день в 3:00

**Описание**: Обновление витрины с данными о работе складов за вчерашний день. При перезапуске удаляет предыдущие данные за этот день, чтобы избежать дублей.

**Источники данных**:
- `dwh_detailed.hub_shipment` - отгрузки
- `dwh_detailed.sat_shipment_details` - детали отгрузок (даты создания, отправки)
- `dwh_detailed.link_shipment_warehouse` - связь отгрузок и складов
- `dwh_detailed.hub_warehouse` - склады
- `dwh_detailed.sat_warehouse_details` - детали складов
- `dwh_detailed.link_shipment_order` - связь отгрузок и заказов
- `dwh_detailed.sat_order_details` - детали заказов (для расчета времени обработки)
- `dwh_detailed.link_order_user` - связь заказов и пользователей (для подсчета уникальных клиентов)
- `dwh_detailed.link_order_item` - связь заказов и товаров (для подсчета количества)

**Метрики**:
- `order_count` - количество уникальных заказов
- `total_shipment_qty` - суммарное количество товаров в отгрузках
- `avg_processing_time_min` - среднее время между созданием заказа и его отгрузкой (в минутах)
- `delayed_orders_count` - количество заказов с задержкой доставки
- `unique_customers_count` - количество уникальных клиентов

## Запуск DAG

1. Откройте Airflow UI: http://localhost:8080
2. Найдите нужный DAG в списке
3. Включите DAG (переключатель слева)
4. DAG будет запускаться автоматически по расписанию
5. Для ручного запуска: нажмите Play → "Trigger DAG"

## Просмотр результатов

После выполнения DAG данные будут доступны в схемах `presentation`:

```sql
-- Витрина 1
SELECT * FROM presentation.purchase_analytics 
ORDER BY purchase_date DESC, total_purchase_amount DESC;

-- Витрина 2
SELECT * FROM presentation.warehouse_delivery 
ORDER BY shipment_date DESC, order_count DESC;
```

