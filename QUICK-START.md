# Быстрый старт (2 минуты)

## Шаг 1: Запустите автоматическую установку на сервере

Подключитесь к серверу:
```bash
ssh root@91.99.120.72
```

Выполните одну команду:
```bash
curl -fsSL https://raw.githubusercontent.com/eduardkolberg/test/main/install-server.sh | bash
```

**ИЛИ** скопируйте скрипт вручную:

```bash
# Создайте файл
nano install-server.sh

# Скопируйте содержимое из файла install-server.sh в этом репозитории
# Нажмите Ctrl+X, затем Y, затем Enter для сохранения

# Сделайте исполняемым и запустите
chmod +x install-server.sh
./install-server.sh
```

Скрипт автоматически:
- ✅ Установит Node.js 18.x LTS
- ✅ Установит Git и PM2
- ✅ Клонирует репозиторий в `/var/www/hello-world`
- ✅ Установит зависимости
- ✅ Запустит приложение
- ✅ Настроит Nginx как reverse proxy
- ✅ Настроит firewall
- ✅ Настроит автозапуск при перезагрузке

## Шаг 2: Проверьте работу

После выполнения скрипта откройте в браузере:
- **http://91.99.120.72** - основная страница (через Nginx)
- **http://91.99.120.72:3000** - прямой доступ к приложению
- **http://91.99.120.72/health** - health check endpoint

Или проверьте через командную строку:
```bash
curl http://localhost:3000
pm2 status
```

## Шаг 3: Настройте автоматический деплой

Перейдите в настройки GitHub репозитория:
**Settings → Secrets and variables → Actions → New repository secret**

Добавьте следующие секреты:

| Имя | Значение |
|-----|----------|
| `SSH_HOST` | `91.99.120.72` |
| `SSH_USERNAME` | `root` |
| `SSH_PASSWORD` | `TqkfTEMhvUWrjbjiFhEX` |
| `SSH_PORT` | `22` |
| `DEPLOY_PATH` | `/var/www/hello-world` |

## Шаг 4: Протестируйте автодеплой

1. Сделайте изменение в коде (например, в `server.js`)
2. Закоммитьте и запушьте в ветку `main`:
   ```bash
   git checkout main
   git merge claude/setup-repo-actions-HaIOQ
   git push origin main
   ```
3. Откройте вкладку **Actions** в GitHub
4. Следите за процессом деплоя
5. После завершения обновите страницу в браузере

## Полезные команды на сервере

```bash
# Статус приложения
pm2 status

# Логи приложения
pm2 logs hello-world-app

# Перезапуск
pm2 restart hello-world-app

# Остановка
pm2 stop hello-world-app

# Проверка Nginx
systemctl status nginx

# Ручное обновление приложения
cd /var/www/hello-world
git pull
npm install --production
pm2 restart hello-world-app
```

## Устранение проблем

### Приложение не отвечает
```bash
pm2 logs hello-world-app  # Посмотрите логи
pm2 restart hello-world-app  # Перезапустите
```

### Nginx показывает ошибку
```bash
systemctl status nginx
nginx -t  # Проверка конфигурации
```

### Порт занят
```bash
lsof -i :3000  # Найти процесс
kill -9 PID  # Убить процесс
```

## Безопасность (важно!)

⚠️ **После настройки рекомендуется:**

1. Сменить пароль root:
   ```bash
   passwd
   ```

2. Создать отдельного пользователя для деплоя:
   ```bash
   adduser deploy
   usermod -aG sudo deploy
   ```

3. Настроить SSH ключи вместо пароля

4. Ограничить доступ по SSH в `/etc/ssh/sshd_config`:
   ```
   PermitRootLogin no
   PasswordAuthentication no
   ```

5. Установить fail2ban для защиты от брутфорса:
   ```bash
   apt-get install fail2ban
   ```

---

**Готово!** Ваше приложение работает и автоматически деплоится при пуше в GitHub! 🎉
