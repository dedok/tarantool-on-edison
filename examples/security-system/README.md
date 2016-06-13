## Content
----------
* [Russian documentation](#Russian-documentation)
* [English documentation](#English-documentation)

## English documentation
------------------------
[In progress]

## Russian documentation
------------------------

Внимание!
Есть вопрос - задай в issues.

Прототип системы безопастности.
На основание громкости звука, кол-во света и температуры - включает тревогу как на устройстве(ах), так и на севере(далее cloud).
C помощью master-master репликации данные на устройстве(ах) и в cloud синхронизированны.
Т.е. любое изменение на устройстве моментально попадает в cloud и наоборот - по сути у вас общая память между всеми.
Для управлением устройством(ами) используется, все тот же, механизм master-master репликации.

Запуск
------
Внимание!
Предпологается что tarantool, nginx upstream, mraa(только на девайсах) установленны.
И что replication_source в in_cloud.lua(devices:init_one) и in_device.lua(replication_source) настроены на ваши хосты.

Файлы
* in_cloud.lua - cloud приложения
* in_device.lua - приложения на девайсе

Cloud
``` bash
$ nginx -c conf/nginx.conf # terminal 1
$ ./in_cloud.lua # terminal 2
```

На устройстве
``` bash
$ ./in_device.lua
```

#Api

* Данные по всем устройства, их датчиках, настройкам
``` bash
$ wget '127.0.0.1:8081/api/list' 
```
``` json
{
	"list": [{
		"data": [{
			"max": 1,
			"series": [28, 28, 27, 28, 27],
			"name": "Sound sensor AIO(2)",
			"measure": "DdB"
		}, {
			"max": 100,
			"series": [32, 34, 34, 33, 32],
			"name": "Light sensor AIO(0)",
			"measure": "lm"
		}, {
			"max": 30,
			"series": [21, 22, 21, 21, 21],
			"name": "Temperature sensor AIO(1)",
			"measure": "C"
		}],
		"device_name": "edison_1"
	}]
}
```

* Данные по одному устройтву
```bash
$ wget '127.0.0.1:8081/api/get?name=__YOUR_DEVICE_NAME__'
```
``` json
{
	"data": [{
		"max": 1,
		"series": [26, 28, 26, 27],
		"name": "Sound sensor AIO(2)",
		"measure": "DdB"
	}, {
		"max": 100,
		"series": [35, 35, 34, 36],
		"name": "Light sensor AIO(0)",
		"measure": "lm"
	}, {
		"max": 30,
		"series": [21, 21, 21, 21],
		"name": "Temperature sensor AIO(1)",
		"measure": "C"
	}],
	"device_name": "edison_1"
}
```

``` bash
# Устанавливаем уровень тревоги если звук будет больше чем max(в DdB)
$ wget '127.0.0.1:8081/api/set' --post-data='{"params":["edison_1", "sound", {"max":1}], "id":0}'
$ cat set
```
``` json
{"result": true}
```

-----------------------------

* Web GUI - [ReactJS](https://facebook.github.io/react/)
* REST api - [Tarantool NginX Upstream](https://github.com/tarantool/nginx_upstream_module)
* Синхронизация данных, управления на устройством(ами) и сloud - [tarantool](http://tarantool.org)
* Работа с сенсорами: [MRAA](https://github.com/intel-iot-devkit/mraa)

-----------------------------

About Tarantool: http://tarantool.org

About yocto: https://www.yoctoproject.org

About Intel mraa: https://github.com/intel-iot-devkit/mraa
