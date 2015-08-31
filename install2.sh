#!/bin/bash
################################################################################
# Script for Installation: ODOO Saas4/Trunk server on Ubuntu 14.04 LTS
# Author: André Schenkels, ICTSTUDIO 2014
# Forked & Modified by: Luke Branch
# LibreOffice-Python 2.7 Compatibility Script Author: Holger Brunn (https://gist.github.com/hbrunn/6f4a007a6ff7f75c0f8b)
#-------------------------------------------------------------------------------
#  
# This script will install ODOO Server on
# clean Ubuntu 14.04 Server
#-------------------------------------------------------------------------------
# USAGE:
#
# odoo-install
#
# EXAMPLE:
# ./odoo-install 
#
################################################################################
 
##fixed parameters
#openerp
OE_USER="odoo"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="/opt/$OE_USER/$OE_USER-server"
# Replace for openerp-gevent for enabling gevent mode for chat
OE_SERVERTYPE="openerp-server"

#Enter version for checkout "7.0" for version 7.0, "saas-4, saas-5 (opendays version) and "master" for trunk
OE_VERSION="8.0"

#set the superadmin password
OE_SUPERADMIN="superadminpassword"
OE_CONFIG="$OE_USER-server"

#--------------------------------------------------
# Set Locale en_US.UTF-8
#--------------------------------------------------
echo -e "\n---- Set en_US.UTF-8 Locale ----"
sudo cp /etc/default/locale /etc/default/locale.BACKUP
sudo rm -rf /etc/default/locale
echo -e "* Change server config file"
sudo su root -c "echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale"
sudo su root -c "echo 'LANG="en_US.UTF-8"' >> /etc/default/locale"
sudo su root -c "echo 'LANGUAGE="en_US:en"' >> /etc/default/locale"


#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y  

echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.3/main/postgresql.conf

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get upgrade -y
sudo apt-get update -y

#--------------------------------------------------
# Install SSH
#--------------------------------------------------
echo -e "\n---- Install SSH Server ----"
sudo apt-get install ssh -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget subversion git bzr bzrtools python-pip -y

echo -e "\n---- Install and Upgrade pip and virtualenv ----"
sudo apt-get install python-dev build-essential -y
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv
echo -e "\n---- Install pyserial and qrcode for compatibility with hw_ modules for peripheral support in Odoo ---"
sudo pip install pyserial qrcode pytz jcconv
sudo apt-get -f install -y

echo -e "\n---- Install pyusb 1.0+ not stable for compatibility with hw_escpos for receipt printer and cash drawer support in Odoo ---"
sudo pip install --pre pyusb
	
echo -e "\n---- Install python packages ----"
sudo apt-get install -y --force-yes --no-install-recommends python-gevent python-dateutil python-feedparser python-gdata python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-pdftools python-setuptools python-pybabel python-imaging python-matplotlib python-reportlab-accel python-openssl python-egenix-mxdatetime python-paramiko antiword python-decorator poppler-utils python-requests libpq-dev python-geoip python-markupsafe postgresql-client python-passlib vim libreoffice curl openssh-server npm python-cairo python-genshi libreoffice-script-provider-python

# Install NodeJS and Less compiler needed by Odoo 8 Website - added from https://gist.github.com/rm-jamotion/d61bc6525f5b76245b50
curl -L https://npmjs.org/install.sh | sh
npm install less -y

echo -e "\n---- Install python libraries ----"
sudo pip install gdata
sudo pip install passlib

echo -e "\n---- Install Other Dependencies ----"
sudo pip install graphviz ghostscript gcc mc bzr lptools make
sudo pip install gevent gevent_psycopg2 psycogreen

echo -e "\n---- Install Wkhtmltopdf 0.12.1 ----"
sudo wget http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin
	
echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

### install Arabic support modules
cd  $OE_HOME/custom/addons/
sudo git clone https://github.com/barsi/odoo-rtl $OE_HOME/custom/addons
sudo rm $OE_HOME/custom/addons/LICENSE
sudo rm $OE_HOME/custom/addons/README.md
sudo git clone https://github.com/ZamilTec/OdooHideBar $OE_HOME/custom/addons/OdooHideBar

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"
sudo touch /etc/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf

echo -e "* Change server config file"
sudo su root -c "echo '[options]' >> /etc/$OE_CONFIG.conf"
sudo sed -i s/"db_host = .*"/"db_user = False"/g /etc/$OE_CONFIG.conf
sudo sed -i s/"db_host = .*"/"db_port = False"/g /etc/$OE_CONFIG.conf
sudo sed -i s/"db_user = .*"/"db_user = $OE_USER"/g /etc/$OE_CONFIG.conf
sudo sed -i s/"db_password = .*"/"db_user = False"/g /etc/$OE_CONFIG.conf
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $OE_SUPERADMIN"/g /etc/$OE_CONFIG.conf
sudo su root -c "echo 'addons_path = $OE_HOME_EXT/addons,$OE_HOME/custom/addons' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Server startup config - Common options' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Admin password for creating, restoring and backing up databases admin_passwd = admin' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify additional addons paths (separated by commas)' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## XML-RPC / HTTP - XML-RPC Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpc = True' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Specify the TCP IP address for the XML-RPC protocol. The empty string binds to all interfaces.' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpc_interface = ' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the TCP port for the XML-RPC protocol' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpc_port = 8069' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Enable correct behavior when behind a reverse proxy' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'proxy_mode = True' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## XML-RPC / HTTPS - XML-RPC Secure Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# disable the XML-RPC Secure protocol' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpcs = True' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Specify the TCP IP address for the XML-RPC Secure protocol. The empty string binds to all interfaces.' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpcs_interface = ' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the TCP port for the XML-RPC Secure protocol' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'xmlrpcs_port = 8071' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the certificate file for the SSL connection' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'secure_cert_file = server.cert' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the private key file for the SSL connection' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'secure_pkey_file = server.pkey' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## NET-RPC - NET-RPC Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# enable the NETRPC protocol' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'netrpc = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the TCP IP address for the NETRPC protocol' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'netrpc_interface = 127.0.0.1' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the TCP port for the NETRPC protocol' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'netrpc_port = 8070' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## WEB - Web interface Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Filter listed database REGEXP' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'dbfilter = .*' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Static HTTP - Static HTTP service' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# enable static HTTP service for serving plain HTML files' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'static_http_enable = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the directory containing your static HTML files (e.g '/var/www/')' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'static_http_document_root = None' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the URL root prefix where you want web browsers to access your static HTML files (e.g '/')' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'static_http_url_prefix = None' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Testing Group - Testing Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Launch a YML test file.' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'test_file = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# If set, will save sample of all reports in this directory.' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'test_report_directory = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Enable YAML and unit tests.' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Server startup config - Common options' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'test_disable = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Commit database changes performed by YAML or XML tests.' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'test_commit = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '## Logging Group - Logging Configuration' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# file where the server log will be stored (default = None)' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# do not rotate the logfile' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'logrotate = True' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# Send the log to the syslog server' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'syslog = False' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# setup a handler at LEVEL for a given PREFIX. An empty PREFIX indicates the root logger. This option can be repeated. Example: "openerp.orm:DEBUG" or "werkzeug:CRITICAL" (default: ":INFO")' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'log_handler = ["[':INFO']"]' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '# specify the level of the logging. Accepted values: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo '#log_level = debug' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'log_level = info' >> /etc/$OE_CONFIG.conf"


echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/$OE_SERVERTYPE --config=/etc/$OE_CONFIG.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
echo '#!/bin/sh' >> ~/$OE_CONFIG
echo '### BEGIN INIT INFO' >> ~/$OE_CONFIG
echo '# Provides: $OE_CONFIG' >> ~/$OE_CONFIG
echo '# Required-Start: $remote_fs $syslog' >> ~/$OE_CONFIG
echo '# Required-Stop: $remote_fs $syslog' >> ~/$OE_CONFIG
echo '# Should-Start: $network' >> ~/$OE_CONFIG
echo '# Should-Stop: $network' >> ~/$OE_CONFIG
echo '# Default-Start: 2 3 4 5' >> ~/$OE_CONFIG
echo '# Default-Stop: 0 1 6' >> ~/$OE_CONFIG
echo '# Short-Description: Enterprise Business Applications' >> ~/$OE_CONFIG
echo '# Description: ODOO Business Applications' >> ~/$OE_CONFIG
echo '### END INIT INFO' >> ~/$OE_CONFIG
echo 'PATH=/bin:/sbin:/usr/bin' >> ~/$OE_CONFIG
echo "DAEMON=$OE_HOME_EXT/$OE_SERVERTYPE" >> ~/$OE_CONFIG
echo "NAME=$OE_CONFIG" >> ~/$OE_CONFIG
echo "DESC=$OE_CONFIG" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify the user name (Default: odoo).' >> ~/$OE_CONFIG
echo "USER=$OE_USER" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/$OE_CONFIG
echo "CONFIGFILE=\"/etc/$OE_CONFIG.conf\"" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# pidfile' >> ~/$OE_CONFIG
echo 'PIDFILE=/var/run/$NAME.pid' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Additional options that are passed to the Daemon.' >> ~/$OE_CONFIG
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> ~/$OE_CONFIG
echo '[ -x $DAEMON ] || exit 0' >> ~/$OE_CONFIG
echo '[ -f $CONFIGFILE ] || exit 0' >> ~/$OE_CONFIG
echo 'checkpid() {' >> ~/$OE_CONFIG
echo '[ -f $PIDFILE ] || return 1' >> ~/$OE_CONFIG
echo 'pid=`cat $PIDFILE`' >> ~/$OE_CONFIG
echo '[ -d /proc/$pid ] && return 0' >> ~/$OE_CONFIG
echo 'return 1' >> ~/$OE_CONFIG
echo '}' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'case "${1}" in' >> ~/$OE_CONFIG
echo 'start)' >> ~/$OE_CONFIG
echo 'echo -n "Starting ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo 'stop)' >> ~/$OE_CONFIG
echo 'echo -n "Stopping ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'restart|force-reload)' >> ~/$OE_CONFIG
echo 'echo -n "Restarting ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'sleep 1' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '*)' >> ~/$OE_CONFIG
echo 'N=/etc/init.d/${NAME}' >> ~/$OE_CONFIG
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> ~/$OE_CONFIG
echo 'exit 1' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'esac' >> ~/$OE_CONFIG
echo 'exit 0' >> ~/$OE_CONFIG

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Create service   sudo service $OE_SERVERTYPE start"
sudo update-rc.d $OE_SERVERTYPE defaults

echo -e "* Open ports in UFW for openerp-gevent"
sudo ufw allow 8072
echo -e "* Open ports in UFW for openerp-server"
sudo ufw allow 8069

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo "Done! The ODOO server can be started with /etc/init.d/$OE_CONFIG"
echo "Please reboot the server now so that Wkhtmltopdf is working with your install."
echo "Once you've rebooted you'll be able to access your Odoo instance by going to http://[your server's IP address]:8069"
echo "For example, if your server's IP address is 192.168.1.123 you'll be able to access it on http://192.168.1.123:8069"
