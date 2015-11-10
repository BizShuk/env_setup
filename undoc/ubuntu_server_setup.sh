#!/bin/bash



### language setup and libraries

##### go lang

```
mkdir -p $HOME/lib
wget https://storage.googleapis.com/golang/go1.5.linux-amd64.tar.gz
tar -C /home/$USER/lib/ -xvf go1.5.linux-amd64.tar.gz
rm go1.5.linux-amd64.tar.gz
```


##### libraries

sudo apt-get install liblua5.1-0-dev -y
sudo apt-get install libperl-dev -y
sudo apt-get install libssl-dev -y




# for Parse
echo "\n\n ########## setup Parse db..."
curl -s https://www.parse.com/downloads/cloud_code/installer.sh | sudo /bin/bash
git clone https://github.com/BizShuk/ParseDB.git



echo "\n\n ########## setup web dir..."
cd; mkdir ~/web;cd web;
git clone https://github.com/BizShuk/bizshuk.github.io.git




cd ~/lib;
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.36.tar.bz2
tar xvf pcre-8.36.tar.bz2
rm pcre-8.36.tar.bz2

wget http://luajit.org/download/LuaJIT-2.0.4.tar.gz
tar xvf LuaJIT-2.0.4.tar.gz
rm LuaJIT-2.0.4.tar.gz




echo "\n\n ########## setup tenginx... (should be move to server/nginx/nginx_setup.sh)"


cd;cd lib;
git clone https://github.com/alibaba/tengine.git
cd tengine

./configure --prefix=$HOME/nginx \
			--with-pcre=$HOME/lib/pcre-8.36
#			--with-pcre-jit \
#			--with-debug \
#			--with-http_lua_module \
#     --with-http_stub_status_module

make -j8;
make install;

cd ~/sbin;
ln -sf ~/nginx/sbin/nginx s_nginx;
cd;
rm ~/nginx/conf/nginx.conf;
ln -sf ~/note/server/nginx/nginx.conf ~/nginx/conf/nginx.conf;
ln -sf ~/note/server/nginx/nginx.conf ~/sbin/tenginx.conf;

sudo apt-get install nginx-extras php5 php5-fpm -y













# md5 sha1 openssl zlib gzip luajit









# apache site-avalible
sudo ln -sf ~/note/files/apache/apache2.conf /etc/apache2/
sudo ln -sf ~/note/files/apache/conf.d/charset /etc/apache2/conf.d/
sudo ln -sf ~/note/files/apache/sites-available/shuk /etc/apache2/sites-available/
sudo ln -sf ~/note/files/apache/sites-available/test /etc/apache2/sites-available/
sudo ln -sf ~/note/files/apache/sites-available/static /etc/apache2/sites-available/
sudo ln -sf ~/note/files/apache/sites-available/phpmyadmin /etc/apache2/sites-available/
sudo ln -sf ~/note/files/apache/sites-available/survey /etc/apache2/sites-available/

# php5
sudo ln -sf ~/note/files/php/php.ini /etc/php5/apache2/

sudo a2dissite default
sudo a2ensite shuk phpmyadmin static test
sudo a2enmod header rewrite
s_apache reload

# for rpi
sudo cp ~/note/files/hosts /etc/hosts
sudo /etc/init.d/hostname.sh start




# git clone https://github.com/BizShuk/django.git




sudo apt-get install apache2 -y



#sudo apt-get install mysql-server
# 會詢問 root 密碼 與?(待補)
#sudo apt-get install phpmyadmin


# php
sudo apt-get install php5 php-pear -y
sudo apt-get install php5-mysql	-y# 先確認裝好php

#mysql phpmyadmin 可能需要打密碼 how?
#sudo apt-get install mysql-server libapache2-mod-auth-mysql -y
#sudo apt-get install phpmyadmin -y #

#sudo apt-get install python-django -y
#wget https://bootstrap.pypa.io/ez_setup.py -O - | sudo python
#git clone https://github.com/django/django.git django_installer
#cd django_installer | sudo python setup.py


# install django 1.7+ , and in app do the following:
# python manager.py migrate
#python manager.py runserver 0.0.0.0:8000

exit 0





# wine 1.7
#sudo add-apt-repository ppa:ubuntu-wine/ppa
#Then update APT package information by running 'sudo apt-get update'. You can now install Wine by typing 'sudo apt-get install wine1.7'.

