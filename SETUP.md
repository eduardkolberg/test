# Инструкция по настройке и деплою

## Шаг 1: Настройка сервера

### 1.1 Подключитесь к серверу по SSH:
```bash
ssh your_username@your_server_ip
```

### 1.2 Обновите систему:
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.3 Установите Node.js и npm:
```bash
# Установка Node.js 18.x (LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Проверка установки
node --version
npm --version
```

### 1.4 Установите PM2 (менеджер процессов):
```bash
sudo npm install -g pm2

# Настройка PM2 для автозапуска при перезагрузке
pm2 startup
# Выполните команду, которую PM2 выведет после предыдущей команды
```

### 1.5 Установите Git:
```bash
sudo apt install -y git

# Настройте Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 1.6 Создайте директорию для приложения:
```bash
sudo mkdir -p /var/www/hello-world
sudo chown -R $USER:$USER /var/www/hello-world
cd /var/www/hello-world
```

### 1.7 Клонируйте репозиторий:
```bash
# Замените URL на ваш репозиторий
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .

# Или используйте SSH (если настроен SSH ключ)
# git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git .
```

### 1.8 Установите зависимости:
```bash
npm install --production
```

### 1.9 Запустите приложение с PM2:
```bash
pm2 start server.js --name hello-world-app
pm2 save
```

### 1.10 (Опционально) Настройте Nginx как reverse proxy:
```bash
# Установка Nginx
sudo apt install -y nginx

# Создайте конфигурацию
sudo nano /etc/nginx/sites-available/hello-world
```

Добавьте следующую конфигурацию:
```nginx
server {
    listen 80;
    server_name your_domain.com;  # или IP адрес

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Активируйте конфигурацию:
```bash
sudo ln -s /etc/nginx/sites-available/hello-world /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 1.11 Настройте firewall:
```bash
# Разрешите SSH, HTTP и HTTPS
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

## Шаг 2: Настройка GitHub Secrets

Перейдите в настройки вашего GitHub репозитория:
`Settings → Secrets and variables → Actions → New repository secret`

Добавьте следующие секреты:

1. **SSH_HOST**
   - Value: IP адрес или домен вашего сервера (например: `123.45.67.89`)

2. **SSH_USERNAME**
   - Value: имя пользователя для SSH (например: `ubuntu` или `root`)

3. **SSH_PASSWORD**
   - Value: пароль для SSH подключения

4. **SSH_PORT** (опционально, по умолчанию 22)
   - Value: порт SSH (обычно `22`)

5. **DEPLOY_PATH** (опционально, по умолчанию `/var/www/hello-world`)
   - Value: путь к директории приложения на сервере

### Скриншот примера:
```
Name: SSH_HOST
Value: 123.45.67.89

Name: SSH_USERNAME
Value: ubuntu

Name: SSH_PASSWORD
Value: your_secure_password

Name: DEPLOY_PATH
Value: /var/www/hello-world
```

## Шаг 3: Тестирование

### 3.1 Проверьте работу приложения на сервере:
```bash
# Проверьте статус PM2
pm2 status

# Посмотрите логи
pm2 logs hello-world-app

# Проверьте через curl
curl http://localhost:3000
```

### 3.2 Проверьте через браузер:
- Если используете Nginx: `http://your_domain.com` или `http://your_server_ip`
- Без Nginx: `http://your_server_ip:3000`

### 3.3 Протестируйте автоматический деплой:
1. Сделайте любое изменение в коде
2. Закоммитьте и запушьте в ветку `main` или `master`
3. Откройте `Actions` в GitHub и проследите за процессом деплоя
4. Проверьте обновления на сервере

## Полезные команды PM2:

```bash
# Просмотр статуса всех процессов
pm2 status

# Просмотр логов
pm2 logs hello-world-app

# Перезапуск приложения
pm2 restart hello-world-app

# Остановка приложения
pm2 stop hello-world-app

# Удаление из списка PM2
pm2 delete hello-world-app

# Мониторинг ресурсов
pm2 monit
```

## Устранение неполадок:

### Проблема: GitHub Actions не может подключиться по SSH
- Проверьте правильность SSH_HOST, SSH_USERNAME, SSH_PASSWORD
- Убедитесь, что SSH порт открыт в firewall
- Проверьте, что пользователь может подключаться по паролю (PasswordAuthentication yes в /etc/ssh/sshd_config)

### Проблема: Приложение не запускается
```bash
# Проверьте логи
pm2 logs hello-world-app

# Попробуйте запустить вручную
cd /var/www/hello-world
node server.js
```

### Проблема: Порт 3000 уже занят
```bash
# Найдите процесс на порту 3000
sudo lsof -i :3000

# Убейте процесс
sudo kill -9 PID
```

## Безопасность:

⚠️ **ВАЖНО**: Использование пароля для SSH менее безопасно, чем SSH ключи. Рекомендации:

1. Используйте сильный пароль
2. Рассмотрите возможность смены на SSH ключи в будущем
3. Ограничьте SSH доступ определенными IP адресами
4. Включите fail2ban для защиты от брутфорса
5. Регулярно обновляйте систему

## Переход на SSH ключи (рекомендуется):

Если захотите перейти на более безопасный метод с SSH ключами:

```bash
# На локальной машине:
ssh-keygen -t ed25519 -C "github-actions"

# Скопируйте публичный ключ на сервер:
ssh-copy-id -i ~/.ssh/id_ed25519.pub username@server_ip

# В GitHub Secrets замените SSH_PASSWORD на SSH_PRIVATE_KEY
# (содержимое ~/.ssh/id_ed25519)
```

Затем обновите `.github/workflows/deploy.yml`, заменив `password` на `key`.
