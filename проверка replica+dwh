-- смотрим кто у нас в юзерах (при запуске docker-init.sh прогоняется скрипт 10_test_debezium_inserts.sql который инициализирует одного юзера)
select *
from public.users

-- добавляю еще одного юзера
INSERT INTO public.users (
    user_external_id, email, first_name, last_name, phone,
    date_of_birth, registration_date, status,
    effective_from, is_current, created_at, updated_at,
    created_by, updated_by
) VALUES (
    'VERSION-TEST-USER-001',
    'version.test@example.com',
    'Тест',           -- Начальное имя
    'Версионирования',
    '+7-999-000-00-01',
    '1990-01-01'::date,
    NOW(),
    'active',         -- Начальный статус
    NOW(), TRUE, NOW(), NOW(),
    'version_test', 'version_test'
);


-- проверяем что их теперь два
select *
from public.users;

-- меняю второму имя (логирование этого изменения хочу видеть в двх)
UPDATE public.users
SET status = 'suspended',
    first_name = 'Обновленный',  -- Новое имя
    updated_at = NOW(),
    updated_by = 'version_test'
WHERE user_external_id = 'VERSION-TEST-USER-001';


-- еще раз меняю второму имя (логирование этого изменения хочу видеть в двх)
UPDATE public.users
SET status = 'active',
    first_name = 'Финальный',   -- Финальное имя
    last_name = 'Результат',
    updated_at = NOW(),
    updated_by = 'version_test'
WHERE user_external_id = 'VERSION-TEST-USER-001';


-- вот два юзера где у второго дважды меняли имя

select *
from users


---- НА РЕПЛИКЕ
-- после изменений на мастере хотим чтобы на реплике были всего две записи финальные--DONE
select *
from public.users;



-- на ДВХ
-- для второго юзера вижу все три состояния , одно из которых активно



SELECT 
    ROW_NUMBER() OVER (ORDER BY s.load_date) as версия,
    s.first_name as имя,
    s.last_name as фамилия,
    s.status as статус,
    s.load_date::timestamp(0) as начало_версии,
    COALESCE(s.load_end_date::timestamp(0)::text, '→ ТЕКУЩАЯ') as конец_версии,
    CASE 
        WHEN s.load_end_date IS NULL THEN '✅ АКТИВНА'
        ELSE '📦 ЗАКРЫТА'
    END as статус_версии
FROM dwh_detailed.hub_user h
JOIN dwh_detailed.sat_user_details s ON s.hub_user_key = h.hub_user_key
WHERE h.user_external_id = 'VERSION-TEST-USER-001'
ORDER BY s.load_date;