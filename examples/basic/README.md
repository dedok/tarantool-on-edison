## Content
----------
* [Russian documentation](#Russian-documentation)
* [English documentation](#English-documentation)

## English documentation
------------------------
[In progress]

## Russian documentation
------------------------
Примеры и проекты демонстрирующие возможности Tarantool на embedded устройствах

### tarantool.lua
-----------------
Набор примеров которые призваны научить созданию: space, index, fiber.

``` bash
$ sudo apt-get install taranool # или yum, brew ...
$ ./tarantool.lua # или tarantool tarantool.lua
```
После запуска появятся файлы *.{xlog,snap} - xlog - WAL tarantool'а, snap - переодический снапшот.
Эти файлы отвечают за персистентность, их можно удалять, перемещать, ... .
К примеру, мы не хотим делать space.alter чтобы обновить index (актуально во время разработки):
``` bash
$ rm *.{xlog,snap}
```
Полная документация: http://tarantool.org/doc/reference/box.html

-----------------
About Tarantool: http://tarantool.org

About yocto: https://www.yoctoproject.org

About Intel mraa: https://github.com/intel-iot-devkit/mraa
