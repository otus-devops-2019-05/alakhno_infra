# alakhno_infra

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
