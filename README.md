# alakhno_infra

# ДЗ - Занятие 8

## 1. Добавление ssh-ключей нескольких пользователей

Для добавления ssh-ключей нескольких пользователей можно использовать
[heredoc синтаксис](https://www.terraform.io/docs/configuration-0-11/variables.html#strings).

```
  metadata {
    ssh-keys = <<EOF
appuser:${file(var.public_key_path)}
appuser1:${file(var.public_key_path)}
appuser2:${file(var.public_key_path)}
EOF
  }
```

# ДЗ - Занятие 7

## 1. Создание образа Ubuntu 16 с Ruby и MonoDB

Проверка шаблона
```
packer validate -var-file=variables.json ubuntu16.json
```

Создание образа
```
packer build -var-file=variables.json ubuntu16.json
```

Создание инстанса из образа
```
gcloud compute instances create reddit-app \
  --image-family reddit-base \
  --machine-type=f1-micro \
  --tags=puma-server
``` 

## 2. Создание baked образа с приложением

Конфиг приложения reddit.service для systemd сделан на основе
[примера](https://github.com/puma/puma/blob/master/docs/systemd.md)
из документации Ruby/Rack веб-сервера puma.

Проверка шаблона
```
packer validate -var-file=files/variables.json immutable.json
```

Создание образа
```
packer build -var-file=files/variables.json immutable.json
```

Создание инстанса из образа (create-reddit-vm.sh)
```
gcloud compute instances create reddit-app \
  --image-family reddit-full \
  --machine-type=f1-micro \
  --tags=puma-server
``` 

# ДЗ - Занятие 6

Данные для подключения
```
testapp_IP = 34.76.204.172
testapp_port = 9292
```

## 1. Деплой тестового приложения при помощи startup script

Скрипт из локального файла:

```
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud  \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup.sh
``` 

Скрипт, доступный по ссылке:

```
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud  \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata startup-script-url=gs://otus-devops/startup.sh
``` 

## 2. Добавление правила для файервола

Добавление
```
gcloud compute firewall-rules create default-puma-server \
  --target-tags=puma-server \
  --allow=tcp:9292
```

Проверка
```
$ nc -zv 34.76.204.172 9292
Connection to 34.76.204.172 9292 port [tcp/*] succeeded!
```

# ДЗ - Занятие 5

## 1. Подключение к инстансу внутренней сети через Bastion host

Чтобы подключиться к хосту someinternalhost внутренней сети  с локального
компьютера в одну команду, можно воспользоваться следующей командой:

```
ssh -i ~/.ssh/appuser -J appuser@35.210.1.238 appuser@10.132.0.4
``` 

где

- `35.210.1.238` - внешний адрес bastion
- `10.132.0.4` - внутренний адрес someinternalhost

Ключ `-J [user@]host[:port]` позволяет задавать промежуточные хосты для
подключения:

> Connect to the target host by first making a ssh connection to the jump
> host and then establishing a TCP forwarding to the ultimate destination
> from there.  

## 2. Alias для подключения к инстансу внутренней сети

Чтобы иметь возможность подключаться к хосту someinternalhost внутренней сети
при помощи короткой команды `ssh someinternalhost`, можно в `~/.ssh/config`
прописать следующие настройки:

```
Host someinternalhost
HostName 10.132.0.4
User appuser
ProxyJump appuser@35.210.1.238
```

где

- `35.210.1.238` - внешний адрес bastion
- `10.132.0.4` - внутренний адрес someinternalhost

Подробнее про `~/.ssh/config` можно посмотреть в `man ssh_config`.

## 3. VPN сервер

Данные для подключения:
```
bastion_IP = 35.210.1.238 
someinternalhost_IP = 10.132.0.4
```

Подключение к VPN серверу:
```
sudo openvpn --config cloud-bastion.ovpn

Enter Auth Username: test
Enter Auth Password: *******************************

``` 
В качестве пароля вводим ПИН пользователя. 
 
 
Проверка возможности подключения к someinternalhost через VPN:
```
ssh -i ~/.ssh/appuser appuser@10.132.0.4
```

Панель управления VPN-сервера доступна по адресу https://35-210-1-238.sslip.io
Доменное имя предоставлено сервисом [sslip.io](https://sslip.io/), а сертификат
от [Let's Encrypt](https://letsencrypt.org/).
