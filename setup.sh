#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

echo "Updating package lists..."
apt-get update

echo "Upgrading installed packages..."
apt-get upgrade -y

echo "Installing basic applications..."
apt install -y net-tools openssh-server vim unzip git openvpn meld apache2

echo "Updating /etc/hosts file..."
cat <<EOF >> /etc/hosts
192.168.0.29	vtiger.blr
192.168.0.17	share.vtiger.blr
192.168.0.75	staging.vtiger.ind
192.168.0.236   vtiger.local
192.168.0.46	cudb.vtiger.in
192.168.0.30	git.vtiger.blr
192.168.0.70	ops-git.vtiger.blr
EOF

echo "Setting timestamp in bash history..."
echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /root/.bash_profile
source /root/.bash_profile

echo "Configuring Apache default site..."
APACHE_CONF="/etc/apache2/sites-enabled/000-default.conf"
if grep -q "DocumentRoot /var/www" "$APACHE_CONF"; then
  echo "Apache config already updated."
else
  sed -i 's#DocumentRoot .*#DocumentRoot /var/www#' "$APACHE_CONF"
  sed -i '/<VirtualHost \*:80>/a <Directory /var/www>\nAllowOverride All\n</Directory>' "$APACHE_CONF"
fi

echo "Enabling Apache mod_rewrite..."
a2enmod rewrite

echo "Restarting Apache..."
systemctl restart apache2

echo "Setup completed successfully."

# ------------------------------------------------------------------------------

wget https://files.vtiger.com/dev-files/RAVI/php_mysql_configs.zip

#!/bin/bash

hostPath=$(pwd)
GREEN="\033[0;32m"
NC="\033[0m"
NL="\033[0m"

clear

echo -e "${GREEN}Starting Installation.${NC}"
echo -e "${GREEN}Adding ppa:ondrej/php...${NC}"
sudo apt update && apt upgrade
sudo add-apt-repository ppa:ondrej/php
sudo apt update
echo -e "${GREEN}Added ppa:ondrej/php to apt-repository.${NC}"

echo -e "${GREEN}PHP8.2 Installation started...${NC}"
sudo apt install php8.2 php8.2-common
sudo apt install php8.2-cli php8.2-fpm libapache2-mod-php8.2 php8.2-memcache php8.2-memcached php-msgpack php-pear php-pgsql php8.2-bcmath php8.2-cgi php8.2-curl php8.2-gd php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-pgsql php8.2-readline php8.2-soap php8.2-sqlite3 php8.2-xml php8.2-xsl php8.2-imap php8.2-intl php8.2-apcu php8.2-zip php8.2-mcrypt
echo -e "${GREEN}PHP8.2 Installation completed.${NC}"

echo -e "${GREEN}Enabling PHP8.2...${NC}"
sudo a2dismod php7.2
sudo a2enmod php8.2
sudo update-alternatives --set php /usr/bin/php8.2
sudo service apache2 restart
echo -e "${GREEN}PHP8.2 Enabled successfully.${NC}"

echo -e "${GREEN}mcrypt installation started...${NC}"
sudo apt install php-dev
sudo apt install libmcrypt-dev
sudo pecl install mcrypt-1.0.6
echo -e "${GREEN}mcrypt installation completed..${NC}"

echo -e "${GREEN}Upgrading composer...${NC}"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
echo -e "${GREEN}Composer upgraded.${NC}"

echo -e "${GREEN}Upgrading MySQL...${NC}"
sudo apt update && apt upgrade
sudo apt install mysql-server
echo -e "${GREEN}MySQL Upgraded.${NC}"

echo -e "${GREEN}Setting up MySQL8 and PHP8 configs...${NC}"
cd /etc/
wget https://files.vtiger.com/dev-files/RAVI/php_mysql_configs.zip
unzip -o php_mysql_configs.zip
rm php_mysql_configs.zip
sudo service apache2 restart
sudo service mysql restart
cd -
echo -e "${GREEN}MySQL8 and PHP8 configs updated.${NC}"

echo -e "${GREEN}Restaring apache${NC}"
sudo service apache2 restart
echo -e "${GREEN}Done.${NC}"

echo -e "${GREEN}Restaring MySQL${NC}"
sudo service mysql restart
echo -e "${GREEN}Done.${NC}"

echo -e "${GREEN}Setup Completed.${NC}"

# ------------------------------------------------------------------------------

#!/bin/bash

set -e

GREEN="\033[0;32m"
NC="\033[0m"

echo -e "${GREEN}Starting configuration...${NC}"

echo -e "${GREEN}Configuring MySQL authentication...${NC}"
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'V#Carem9';
FLUSH PRIVILEGES;
EOF
echo -e "${GREEN}MySQL root password authentication configured.${NC}"

echo -e "${GREEN}Setting sql-mode in mysqld.cnf...${NC}"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
if grep -q "sql-mode" "$MYSQL_CONF"; then
  sed -i 's/^sql-mode.*/sql-mode=""/' "$MYSQL_CONF"
else
  echo 'sql-mode=""' >> "$MYSQL_CONF"
fi

echo -e "${GREEN}Restarting MySQL service...${NC}"
systemctl restart mysql

echo -e "${GREEN}Installing Memcached...${NC}"
apt-get install -y memcached

echo -e "${GREEN}Configuring multiple Memcached instances...${NC}"
service memcached stop

mkdir -p /var/log
cp /etc/memcached.conf /etc/memcached_crmdata.conf
cp /etc/memcached.conf /etc/memcached_session.conf

sed -i 's/^-p .*/-p 11212/' /etc/memcached_crmdata.conf
sed -i 's#^-P .*#-P /var/run/memcached/memcached_crmdata.pid#' /etc/memcached_crmdata.conf
sed -i 's#^-l .*#-l 127.0.0.1#' /etc/memcached_crmdata.conf
echo "-vv -m 64 -u memcache -c 1024 -f 1.25 -L -v -vv -d -t 4 -l 127.0.0.1 -p 11212 -P /var/run/memcached/memcached_crmdata.pid -vv" >> /etc/memcached_crmdata.conf

sed -i 's/^-p .*/-p 11211/' /etc/memcached_session.conf
sed -i 's#^-P .*#-P /var/run/memcached/memcached_session.pid#' /etc/memcached_session.conf
sed -i 's#^-l .*#-l 127.0.0.1#' /etc/memcached_session.conf
echo "-vv -m 64 -u memcache -c 1024 -f 1.25 -L -v -vv -d -t 4 -l 127.0.0.1 -p 11211 -P /var/run/memcached/memcached_session.pid -vv" >> /etc/memcached_session.conf

cp /lib/systemd/system/memcached.service /lib/systemd/system/memcached_crmdata.service
cp /lib/systemd/system/memcached.service /lib/systemd/system/memcached_session.service

sed -i 's#ExecStart=.*#ExecStart=/usr/share/memcached/scripts/systemd-memcached-wrapper /etc/memcached_crmdata.conf#' /lib/systemd/system/memcached_crmdata.service
sed -i 's#PIDFile=.*#PIDFile=/var/run/memcached/memcached_crmdata.pid#' /lib/systemd/system/memcached_crmdata.service

sed -i 's#ExecStart=.*#ExecStart=/usr/share/memcached/scripts/systemd-memcached-wrapper /etc/memcached_session.conf#' /lib/systemd/system/memcached_session.service
sed -i 's#PIDFile=.*#PIDFile=/var/run/memcached/memcached_session.pid#' /lib/systemd/system/memcached_session.service

mkdir -p /home/sateam/backup/app-archives/memcached
mv /etc/memcached.conf /home/sateam/backup/app-archives/memcached/.
mv /lib/systemd/system/memcached.service /home/sateam/backup/app-archives/memcached/.

echo -e "${GREEN}Reloading daemon and starting all Memcached instances...${NC}"
systemctl daemon-reexec
systemctl daemon-reload
systemctl start memcached_crmdata
systemctl start memcached_session

ps aux | grep memcached

echo -e "${GREEN}Installing Composer...${NC}"
apt install -y php-cli unzip curl
cd ~
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=$(curl -sS https://composer.github.io/installer.sig)

php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

echo -e "${GREEN}Composer installed.${NC}"

echo -e "${GREEN}Installing Java (OpenJDK 8) and Apache Ant...${NC}"
add-apt-repository -y ppa:openjdk-r/ppa
apt-get update
apt-get install -y openjdk-8-jdk ant

echo -e "${GREEN}Configuring Java alternatives (manual step may be needed)...${NC}"
update-alternatives --config java
update-alternatives --config javac

echo -e "${GREEN}Installing NetBeans IDE...${NC}"
snap install netbeans --classic

echo -e "${GREEN}Installing Eclipse IDE...${NC}"
snap install --classic eclipse

echo -e "${GREEN}Setup completed successfully.${NC}"

# ------------------------------------------------------------------------------

#!/bin/bash
#
# full_desktop_setup.sh
# Usage: sudo ./full_desktop_setup.sh
#

set -e
GREEN="\033[0;32m"
NC="\033[0m"

echo -e "${GREEN}== Starting full desktop & dev stack setup ==${NC}"

# 1. Install Visual Studio Code (latest .deb)
echo -e "${GREEN}1) Installing Visual Studio Code...${NC}"
VSCODE_URL="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
TMP_DEB="/tmp/vscode_latest_amd64.deb"
wget -O "$TMP_DEB" "$VSCODE_URL"
apt install -y "$TMP_DEB"
rm -f "$TMP_DEB"
echo -e "${GREEN}-> VS Code installed.${NC}"

# 2. Turn OFF barrier on root volume in /etc/fstab
echo -e "${GREEN}2) Disabling barrier on / in /etc/fstab...${NC}"
FSTAB="/etc/fstab"
sed -i -E 's|(UUID=[^[:space:]]+\s+/\s+ext4\s+[^[:space:]]*)|\1,barrier=0|' "$FSTAB"
echo -e "${GREEN}-> barrier=0 added to root entry.${NC}"

# 3. Install Shutter
echo -e "${GREEN}3) Installing Shutter screenshot tool...${NC}"
add-apt-repository universe -y
apt update
apt install -y shutter
echo -e "${GREEN}-> Shutter installed.${NC}"

# 4. Install Postman via snap
echo -e "${GREEN}4) Installing Postman (snap)...${NC}"
snap install postman
echo -e "${GREEN}-> Postman installed.${NC}"

# 5. Install Google Chrome (.deb)
echo -e "${GREEN}5) Installing Google Chrome...${NC}"
CHROME_DEB="/tmp/google-chrome-stable_current_amd64.deb"
wget -O "$CHROME_DEB" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
apt install -y "$CHROME_DEB"
rm -f "$CHROME_DEB"
echo -e "${GREEN}-> Google Chrome installed.${NC}"

# 6. Install Sublime Text
echo -e "${GREEN}6) Installing Sublime Text...${NC}"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
  | gpg --dearmor \
  | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" \
  | tee /etc/apt/sources.list.d/sublime-text.list
apt update
apt install -y sublime-text
echo -e "${GREEN}-> Sublime Text installed.${NC}"

# 7. Install KeePass2
echo -e "${GREEN}7) Installing KeePass2...${NC}"
add-apt-repository universe -y
apt update
apt install -y keepass2
echo -e "${GREEN}-> KeePass2 installed.${NC}"

# 8. Install ClamAV and configure cron
echo -e "${GREEN}8) Installing ClamAV...${NC}"
apt install -y clamav clamav-daemon
mkdir -p /var/log/clamav
# Cron entries
CRON_FILE="/etc/crontab"
grep -q "clamscan -r --remove=yes" "$CRON_FILE" || cat >> "$CRON_FILE" <<EOF

# Vtiger ITOps - ClamAV Scan and auto removal
0 */8 * * * root clamscan -r --remove=yes /home > /var/log/clamav/clamscan.log 2>&1

# Vtiger ITOps - Update the ClamAV signatures
0 */12 * * * root freshclam --quiet
EOF
service clamav-freshclam restart
echo -e "${GREEN}-> ClamAV installed & cron jobs configured.${NC}"

# 9. Install Elastic Agent
echo -e "${GREEN}9) Installing Elastic Agent 8.7.0...${NC}"
cd /tmp
ELASTIC_TAR="elastic-agent-8.7.0-linux-x86_64.tar.gz"
wget -O "$ELASTIC_TAR" "https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.7.0-linux-x86_64.tar.gz"
tar xzvf "$ELASTIC_TAR"
cd elastic-agent-8.7.0-linux-x86_64
# Replace URL & TOKEN with your actual values if needed
./elastic-agent install \
  --url=https://192.168.1.176:8220 \
  --enrollment-token=dXlZdWVZY0JneV9jbWlCemlEVmE6VkNUS3hwLUdUbnlnNzF1bDNtaHZZQQ== \
  --insecure
cd /
rm -rf /tmp/elastic-agent-8.7.0-linux-x86_64*
echo -e "${GREEN}-> Elastic Agent installed.${NC}"

# 10. Remove invalid KeePass PPA if present
echo -e "${GREEN}10) Removing deprecated KeePass PPA if exists...${NC}"
add-apt-repository --remove ppa:jtaylor/keepass -y || true
apt update
echo -e "${GREEN}-> Old KeePass PPA removed and sources updated.${NC}"

echo -e "${GREEN}== All tasks completed successfully! ==${NC}"
