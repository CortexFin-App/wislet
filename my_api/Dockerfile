# Використовуємо офіційний, повний образ Dart як єдине середовище
FROM dart:stable

WORKDIR /app

# Встановлюємо інструменти Dart Frog
RUN dart pub global activate dart_frog_cli

# Копіюємо всі файли нашого проекту
COPY . .

# Завантажуємо залежності
RUN dart pub get

# Генеруємо виробничу збірку
RUN dart_frog build

# Компілюємо виконуваний файл
RUN dart compile exe build/bin/server.dart -o build/server

# Відкриваємо порт
EXPOSE 8080

# Запускаємо скомпільований сервер
CMD ["./build/server"]