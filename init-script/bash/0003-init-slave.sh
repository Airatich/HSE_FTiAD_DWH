# Копируем backup из data-replica в volume реплики (выполняется на master'е)
# Файлы уже созданы pg_basebackup с флагом -R, который создал postgresql.auto.conf и standby.signal
# Нужно только скопировать данные в volume реплики
# Это делается через docker cp в docker-init.sh
