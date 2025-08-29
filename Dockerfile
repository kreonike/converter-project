# 1. Используем официальный образ Python 3.11 в качестве основы
FROM python:3.11-slim

# 2. Создаем пользователя без прав администратора для безопасности
RUN useradd --create-home --shell /bin/bash appuser

# 3. Устанавливаем рабочую директорию в контейнере
WORKDIR /home/appuser/app

# 4. Копируем файл с зависимостями и устанавливаем их
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir gunicorn

# 5. Копируем остальной код приложения
COPY --chown=appuser:appuser . .

# 6. Создаем директорию для скачиваемых файлов
RUN mkdir /home/appuser/app/downloads

# 7. Переключаемся на пользователя без прав администратора
USER appuser

# 8. Указываем команду для запуска приложения при старте контейнера
CMD ["gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]
