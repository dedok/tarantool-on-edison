## Content
----------
* [Russian documentation](#Russian-documentation)
* [English documentation](#English-documentation)

## English documentation
------------------------
[In progress]

## Russian documentation
------------------------
Репликация и fiber

###
Внимание! Перед запуском необходимо с конфигурировать replication_source, с.м. файлы: master_1.lua, master_2.lua

Запускаем 1-го master
``` bash
$ ./master_1.lua
```

Создаем доп. директорию для 2-го мастера и запускаем его
``` bash
$ mkdir master-2
$ cd master-2
$ ../master_2.lua
```

Полная документация: http://tarantool.org/doc/book/replication/index.html?highlight=replication

------------------------

About Tarantool: http://tarantool.org

About yocto: https://www.yoctoproject.org

About Intel mraa: https://github.com/intel-iot-devkit/mraa
