<h3>### PROCESS CONTROL ###</h3>

<p>работаем с процессами</p>

<h4>Описание домашнего задания</h4>

<p>Задания на выбор:</p>
<ol>
<li>написать свою реализацию ps ax используя анализ /proc<ul type="disc"><li>Результат ДЗ - рабочий скрипт который можно запустить</li></ul></li>
<li>написать свою реализацию lsof<ul type="disc"><li>Результат ДЗ - рабочий скрипт который можно запустить</li></ul></li>
<li>дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию<ul type="disc"><li>Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли</li></ul></li>
<li>реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice<ul type="disc"><li>Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли</li></ul></li>
<li>реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice<ul type="disc"><li>Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли</li></ul></li>
</ol>



<h4>Создание скрипта lsof</h4>

<p>Выбираем задание "написать свою реализацию lsof".</p>

<p>Вывод команды lsof:</p>

<pre>[root@localhost ~]# lsof
COMMAND     PID   TID           USER   FD      TYPE             DEVICE  SIZE/OFF       NODE NAME
systemd       1                 root  cwd       DIR              253,0       242         64 /
systemd       1                 root  rtd       DIR              253,0       242         64 /
systemd       1                 root  txt       REG              253,0   1632960   34114346 /usr/lib/systemd/systemd
systemd       1                 root  mem       REG              253,0     20064     835013 /usr/lib64/libuuid.so.1.3.0
systemd       1                 root  mem       REG              253,0    265576     923571 /usr/lib64/libblkid.so.1.1.0
systemd       1                 root  mem       REG              253,0     90160     834989 /usr/lib64/libz.so.1.2.7
systemd       1                 root  mem       REG              253,0    157440      41066 /usr/lib64/liblzma.so.5.2.2
...
[root@localhost ~]#</pre>

<p>Аналогично такому выводу будем создавать скрипт <i>lsof.sh</i>:</p>

<pre>[root@localhost ~]# vi ./lsof.sh</pre>

<p>Создаём шапку:</p>

<pre>echo -e "COMMAND\tPID\tUSER\tSIZE/OFF\tNODE\tNAME"</pre>

<p>Отбираем в каталоге /proc все директории с числовым именем &lt;pid&gt;, что являются id процессора:</p>

<pre>find /proc -maxdepth 1 -type d | cut -f3 -d '/' | grep -E [0-9]+ | sort -n | grep -v $$</pre>

<p>С помощью цикла будем извлекать содержимое этих директорий:</p>

<pre>find /proc -maxdepth 1 -type d | cut -f3 -d '/' | grep -E [0-9]+ | sort -n | grep -v $$ | while read pid; do</pre>

<p>Находим значения для колонок COMMAND и USER:</p>

<pre>if [[ -f /proc/$pid/comm ]]; then
  command=$(cat /proc/$pid/comm)               # COMMAND
  user=$(ls -ld /proc/$pid | awk '{print $3}') # USER
else 
  command=' '
  user=' '
fi</pre>

<p>Для колонки PID будет значение <i>pid</i>.</p>

<p>Теперь находим значения для колонок SIZE/OFF, NODE и NAME:</p>

<p>Находим рабочий каталог по символической ссылке /proc/&lt;pid&gt;/cwd и присвоим переменной <i>file</i> для колонки NAME:</p>

<pre>file=$(readlink -f /proc/$pid/cwd)        # NAME</pre>

<p>Для данных файлов находим размер <i>size</i> и inode <i>node</i> для колонок SIZE/OFF и NODE соответственно:</p>

<pre>size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')  # SIZE/OFF
node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}') # NODE</pre>

<p>Находим значения <i>file</i>, <i>size</i>, <i>node</i> в списке файлов /proc/&lt;pid&gt;/maps:</p>

<pre>awk '$NF ~ "^/" {print $NF}' /proc/$pid/maps | sort -r | uniq | while read file; do # NAME
  size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')                 # SIZE/OFF
  node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')                # NODE</pre>

<p>Аналогичным образом находим значения <i>file</i>, <i>size</i>, <i>node</i> по символическим ссылкам в директории /proc/&lt;pid&gt;/fd:</p>

<pre>ls /proc/$pid/fd/ | while read fd; do
  file=$(readlink -f /proc/$pid/fd/$fd)                              # NAME
  size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')  # SIZE/OFF
  node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}') # NODE</pre>

<p>Для вывода всех полученных значений добавим следующую строку:</p>

<pre>echo -e "$command\t$pid\t$user\t$size\t$node\t$file"</pre>

<p>Для того чтобы скрипт запускался только от имени root, в начале добавим следующий блок:</p>

<pre># Run as root?
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root!"
  exit 1
fi</pre>

<p>В итоге получим скрипт со следующим содержимым:</p>

<pre>#!/bin/bash

# Run as root?
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root!"
  exit 1
fi

# header
echo -e "COMMAND\tPID\tUSER\tSIZE\tNODE\tNAME"

# PID:
find /proc -maxdepth 1 -type d | cut -f3 -d '/' | grep -E [0-9]+ | sort -n | grep -v $$ | while read pid; do
  # COMMAND, USER:
  if [[ -f /proc/$pid/comm ]]; then
    command=$(cat /proc/$pid/comm)
    user=$(ls -ld /proc/$pid | awk '{print $3}')
  else 
    command=' '
    user=' '
  fi

  # cwd, SIZE, NODE:
  if [[ -e /proc/$pid/cwd ]]; then
    file=$(readlink -f /proc/$pid/cwd)
    size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')
    node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')
    echo -e "$command\t$pid\t$user\t$size\t$node\t$file"
  fi

  # list files in maps
  if [[ -f /proc/$pid/maps ]]; then
    awk '$NF ~ "^/" {print $NF}' /proc/$pid/maps | sort -r | uniq | while read file; do
      size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')
      node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')
      echo -e "$command\t$pid\t$user\t$size\t$node\t$file"
    done
  fi

  # list files in fd
  if [[ -d /proc/$pid/fd ]]; then
    ls /proc/$pid/fd/ | while read fd; do
      file=$(readlink -f /proc/$pid/fd/$fd)
      size=$(stat $file 2> /dev/null | grep 'Size:' | awk '{print $2}')
      node=$(stat $file 2> /dev/null | grep 'Inode:' | awk '{print $4}')
      echo -e "$command\t$pid\t$user\t$size\t$node\t$file"
    done
  fi
done</pre>

<p>Результат выполнения скрипта <i>lsof.sh</i> выглядит следующим образом:</p>

<pre>[root@localhost ~]# . ./lsof.sh
COMMAND	PID	USER	SIZE	NODE	NAME
systemd	1	root	242	64	/
systemd	1	root	1632960	34114346	/usr/lib/systemd/systemd
systemd	1	root	90160	834989	/usr/lib64/libz.so.1.2.7
systemd	1	root	20064	835013	/usr/lib64/libuuid.so.1.3.0
systemd	1	root	155744	390928	/usr/lib64/libselinux.so.1
systemd	1	root	43712	84762	/usr/lib64/librt-2.17.so
systemd	1	root	142144	84757	/usr/lib64/libpthread-2.17.so
systemd	1	root	402384	390917	/usr/lib64/libpcre.so.1.2.0
systemd	1	root	61680	906220	/usr/lib64/libpam.so.0.83.1
systemd	1	root	277808	923573	/usr/lib64/libmount.so.1.1.0
systemd	1	root	157440	41066	/usr/lib64/liblzma.so.5.2.2
systemd	1	root	91800	172027	/usr/lib64/libkmod.so.2.2.10
systemd	1	root	88720	85	/usr/lib64/libgcc_s-4.8.5-20150702.so.1
systemd	1	root	19248	84740	/usr/lib64/libdl-2.17.so
systemd	1	root	20048	172131	/usr/lib64/libcap.so.2.22
systemd	1	root	23968	391001	/usr/lib64/libcap-ng.so.0.0.0
systemd	1	root	2156592	84734	/usr/lib64/libc-2.17.so
systemd	1	root	265576	923571	/usr/lib64/libblkid.so.1.1.0
systemd	1	root	127184	391002	/usr/lib64/libaudit.so.1.0.0
systemd	1	root	19896	172127	/usr/lib64/libattr.so.1.1.0
systemd	1	root	163312	390902	/usr/lib64/ld-2.17.so
systemd	1	root	296	899634	/etc/selinux/targeted/contexts/files/file_contexts.local.bin
systemd	1	root	45577	899632	/etc/selinux/targeted/contexts/files/file_contexts.homedirs.bin
systemd	1	root	1432853	899630	/etc/selinux/targeted/contexts/files/file_contexts.bin
systemd	1	root	0	2051	/dev/null
systemd	1	root	0	2051	/dev/null
systemd	1	root			/proc/1/fd/anon_inode:inotify
systemd	1	root			/proc/1/fd/socket:[53536]
systemd	1	root			/proc/1/fd/socket:[53537]
systemd	1	root			/proc/1/fd/socket:[53567]
systemd	1	root			/proc/1/fd/socket:[53568]
...
[root@localhost ~]#</pre>

<h4>Запуск скрипта lsof.sh</h4>

<p>Запустить следующую команду, которая скачает скрипт <i>lsof.sh</i> с гитхаба:</p>

<pre>$ git clone https://github.com/SergSha/process_control.git && cd ./process_control</pre>

<p>Для запуска скрипта запустите (с правами root) следующую команду:</p>

<pre>$ sudo bash ./lsof.sh</pre>

<p>Выполнения скрипта <i>lsof.sh</i> занимает довольно продолжительное время.</p>

