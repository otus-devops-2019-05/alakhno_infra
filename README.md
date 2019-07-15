# alakhno_infra

# ДЗ - Занятие 10

## 1. Playbook для клонирования репозитория с приложением на app сервер

```
$ ansible-playbook clone.yml

TASK [Clone repo] ******************************************************************************************************************************************************************************************
ok: [appserver]

PLAY RECAP *************************************************************************************************************************************************************************************************
appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Папка с репозиторием уже была на сервере, поэтому ansible не внёс никаких
изменений.

> Теперь выполните `ansible app -m command -a 'rm -rf ~/reddit'` и проверьте
> еще раз выполнение плейбука. Что изменилось и почему? 

Мы только что удалили папку с репозиторием, поэтому ansible заново клонировал
репозиторий на сервер.

```
$ ansible-playbook clone.yml

TASK [Clone repo] ******************************************************************************************************************************************************************************************
changed: [appserver]

PLAY RECAP *************************************************************************************************************************************************************************************************
appserver                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```


# ДЗ - Занятие 9

## 1. Переиспользование модулей при конфигурации окружений Stage и Prod

> Инфраструктура в обоих окружениях будет идентична, однако будет иметь
> небольшие различия: мы откроем SSH доступ для всех IP адресов в окружении
> Stage, а в окружении Prod откроем доступ только для своего IP

### Создание Stage окружения

```
cd terraform/stage/
terraform init
terraform get
terraform apply
```

### Создание Prod окружения

Для задания своего IP добавлена переменная `ssh_source_ip`, значение которой
надо указать в `terraform/prod/terraform.tfvars`.

```
cd terraform/prod/
terraform init
terraform get
terraform apply
```


## 2. Дополнительная параметризация модулей

Описанная в методичке параметризация модулей не позволяет одновременно создать
Stage и Prod окружения из-за конфликтов имён ресурсов. Для решения проблемы в
параметры модулей была добавлена переменная `env`.

При создании второго окружения возникла ошибка:

```
Error: Error applying plan:

1 error(s) occurred:

* module.app.google_compute_address.app_ip: 1 error(s) occurred:

* google_compute_address.app_ip: Error creating Address: googleapi: Error 403: Quota 'STATIC_ADDRESSES' exceeded. Limit: 1.0 in region europe-west1., quotaExceeded
```

Чтобы уложиться в ограничение пробного аккаунта на количество внешних IP
адресов в одном регионе, Stage и Prod окружения были разнесены по разным
регионам: `europe-west1` и `europe-west2` соответсвенно. 

## 3. Создание бакетов при помощи модуля из реестра

```
cd terraform/
terraform init
terraform get
terraform apply
```

Проверка наличия бакетов:
```
$ gsutil ls
gs://storage-bucket-cat/
gs://storage-bucket-dog/
```

Загрузка файла в бакет:
```
echo "Test" > test.txt
gsutil mv test.txt gs://storage-bucket-cat/
```

## 4. Хранение state файла в удалённом бэкенде

Прописал настройки для хранения state файла в Google Cloud Storage.

Для Stage и Prod окружений используется один и тот же бакет, но с разными
префиксами:

```
terraform {
  backend "gcs" {
    bucket = "otus-devops"
    prefix = "prod" # для prod окружения
  }
}
```

При попытке одновременного применения конфигурации срабатывает блокировка:

```
$ terraform apply
Acquiring state lock. This may take a few moments...

Error: Error locking state: Error acquiring the state lock: writing "gs://otus-devops/prod/default.tflock" failed: googleapi: Error 412: Precondition Failed, conditionNotMet
Lock Info:
  ID:        1562946612640678
  Path:      gs://otus-devops/prod/default.tflock
  Operation: OperationTypeApply
  Who:       alakhno@thinkpad-x250
  Version:   0.11.11
  Created:   2019-07-12 15:50:12.51507322 +0000 UTC
  Info:      


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
``` 

Поменял регион для Prod окружения на europe-west3, так как terraform
ругался на нехватку ресурсов в europe-west2.

## 5. Деплой приложения

### Модуль app

Значение переменной окружения DATABASE_URL, которая нужна для запуска сервиса
приложения puma.service можно задать при помощи директивы Environment 
([подробнее](https://coreos.com/os/docs/latest/using-environment-variables-in-systemd-units.html)):
```
Environment='DATABASE_URL=${var.database_url}'
```

Приложение деплоится при помощи provisioner'ов:

```
  provisioner "file" {
    content     = "${data.template_file.puma_service.rendered}"
    destination = "/tmp/puma.service"
  }

  provisioner "file" {
    source      = "${path.module}/files/deploy.sh"
    destination = "/tmp/deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "${var.app_deploy ? "sh /tmp/deploy.sh" : "echo 'App deploy disabled'"}",
    ]
  }
```

При работе с файлами из директории модуля удобно использовать `${path.module}`
([документация](https://www.terraform.io/docs/configuration-0-11/interpolation.html#path-information)). 

Для параметризации puma.service удобно использовать источник данных `template_file`
([подробнее](https://www.terraform.io/docs/providers/template/d/file.html)).

```
data "template_file" "puma_service" {
  template = "${file("${path.module}/files/puma.service.tpl")}"

  vars = {
    database_url = "${var.database_url}"
  }
}
```

### Модуль db

По умолчанию MongoDB не позволяет подключаться с внешних IP адресов:
https://docs.mongodb.com/manual/core/security-mongodb-configuration/

Поэтому добавил в модуль db конфиг mongod.conf с `net.bindIp: 0.0.0.0`.
Конфиг деплоится при помощи provisioner'ов:

```
  provisioner "file" {
    source      = "${path.module}/files/mongod.conf"
    destination = "/tmp/mongod.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo systemctl restart mongod",
    ]
  }
```

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

## 2. Добавление ssh-ключа в метаданные проекта через веб интферфейс

Terraform ничего не знает про ssh-ключ пользователя appuser_web, добавленный
в метаданные проекта через веб интерфейс.

При этом инстанс google_compute_instance.app доступен и для пользователей,
указанных в конфиге main.tf (appuser, appuser1, appuser2), и для пользователя
appuser_web. 

## 3. Создание HTTP балансировщика

Использованные ссылки на документацию Google Cloud:
1. [Балансировка нагрузки в Google Cloud](https://cloud.google.com/load-balancing/)
2. [Процесс настройки HTTP(S) балансировщика](https://cloud.google.com/load-balancing/docs/https/setting-up-https)
3. [Архитектура HTTP(S) балансировщика](https://cloud.google.com/load-balancing/docs/https/)

Составные части балансировщика в документации Terraform:
1. [google_compute_instance_group](https://www.terraform.io/docs/providers/google/r/compute_instance_group.html)
2. [google_compute_health_check](https://www.terraform.io/docs/providers/google/r/compute_health_check.html)
3. [google_compute_backend_service](https://www.terraform.io/docs/providers/google/d/datasource_google_compute_backend_service.html)
4. [google_compute_url_map](https://www.terraform.io/docs/providers/google/r/compute_url_map.html)
5. [google_compute_target_http_proxy](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html)
6. [google_compute_global_forwarding_rule](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html)

## 4. Добавление второго инстанса с приложением

Для добавления инстанса `app2` можно скопировать конфиг инстанса `app`:
 
```
resource "google_compute_instance" "app" {
  ...
}

resource "google_compute_instance" "app2" {
  ...
}
```

Но тогда при внесении изменений в конфигурацию инстанса придётся вносить
изменение в нескольких местах.

## 5. Параметризация количества инстансов с приложением

Для задания количества инстансов можно использовать параметр `count`:

```
resource "google_compute_instance" "app" {
  name         = "reddit-app-${count.index + 1}"
  count        = "${var.count}"
  ...
}
```

При этом в балансировщике и output переменных используется `*`:
```
resource "google_compute_instance_group" "app-group" {
  name        = "reddit-app-group"

  ...
  
  instances = [
    "${google_compute_instance.app.*.self_link}",
  ]
}
```

Создание конфигурации с двумя инстансами:

```
terraform apply -var 'count=2'
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
