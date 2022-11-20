<h3>### PROCESS CONTROL ###</h3>

<p>работаем с процессами</p>

<h4>Описание домашнего задания</h4>

<p>Задания на выбор:</p>
<ol>
<li>написать свою реализацию ps ax используя анализ /proc<ul><li>Результат ДЗ - рабочий скрипт который можно запустить</li></ul></li>
<li>написать свою реализацию lsof<ul><li>Результат ДЗ - рабочий скрипт который можно запустить</li></ul></li>
<li>дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию<ul><li>Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли</li></ul></li>
<li>реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice<ul><li>Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли</li></ul></li>
<li>реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice<ul><li>Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли</li></ul></li>
</ol>



<h4>Создание стенда "Process control"</h4>

<p>Содержимое Vagrantfile:</p>

<pre>[user@localhost process_control]$ <b>vi ./Vagrantfile</b></pre>

<pre># -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :procs => {
    :box_name => "centos/7",
    :vm_name => "procs",
#    :ip => '192.168.50.10',
    :mem => '256',
    :cpus => '1'
  }
}
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s
#      box.vm.network "private_network", ip: boxconfig[:ip]
      box.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", boxconfig[:mem]]
        vb.customize ["modifyvm", :id, "--cpus", boxconfig[:cpus]]
      end
      box.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
      SHELL
    end
  end
end</pre>

<p>Запустим виртуальную машину:</p>

<pre>[user@localhost process_control]$ <b>vagrant up</b></pre>

<pre>[user@localhost process_control]$ <b>vagrant status</b>
Current machine states:

procs                     running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
[user@localhost process_control]$</pre>

<pre>[user@localhost process_control]$ <b>vagrant ssh bash</b>
[vagrant@procs ~]$ <b>sudo -i</b>
[root@procs ~]#</pre>

<p></p>


















