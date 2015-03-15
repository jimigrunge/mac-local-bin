#Installing dev Environment On Mac OSX 10.10 Yosemite

Based on [ALAN IVEY's setup](https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew)


####Install xCode and command line tools as per Apple instructions


##Install HomeBrew

``ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"``

##Install GIT, if missing

``brew install -v git``

In OSX 10.10+, `/usr/local/bin` is now at the beginning of the $PATH so no need to change that in your `.bashrc`

##Install Dependancies for later

```shell
brew tap homebrew/dupes
brew tap homebrew/versions
brew tap homebrew/homebrew-php
brew tap homebrew/apache
brew tap danpoltawski/homebrew-mdk
brew update && brew upgrade
brew install htop
brew install freetype jpeg libpng gd zlib openssl unixodbc
brew install libssh2
brew install php-version
brew install mcrypt
brew install node
brew install sqlite
brew install pbzip2
brew install imagemagick
cd /usr/local/include
ln -s ImageMagick-6 ImageMagick
```

##Install PostgreSQL

``brew install postgresql``

``ln -sfv /usr/local/opt/postgresql/homebrew.mxcl.postgresql.plist ~/Library/LaunchAgents/``

##Install MySQL

``brew install mysql``

**MySQL Configs for performance**

``cp -v $(brew --prefix mysql)/support-files/my-default.cnf $(brew --prefix)/etc/my.cnf``

```
cat >> $(brew --prefix)/etc/my.cnf <<'EOF'
	# Echo & Co. changes
	max_allowed_packet = 1073741824
	innodb_file_per_table = 1
EOF
```	

``sed -i '' 's/^#[[:space:]]*\(innodb_buffer_pool_size\)/\1/' $(brew --prefix)/etc/my.cnf``

``ln -sfv $(brew --prefix mysql)/homebrew.mxcl.mysql.plist ~/Library/LaunchAgents/``


##Apache install

``sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null``

``brew install -v homebrew/apache/httpd22 --with-homebrew-openssl --with-mpm-event``

``brew install -v homebrew/apache/mod_fastcgi --with-homebrew-httpd22``

``sed -i '' '/fastcgi_module/d' $(brew --prefix)/etc/apache2/2.2/httpd.conf``

**This is all one command, so copy and paste the entire code block at once:**

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; export MODFASTCGIPREFIX=$(brew --prefix mod_fastcgi) ; cat >> $(brew --prefix)/etc/apache2/2.2/httpd.conf <<EOF
 
# Echo & Co. changes
 
# Load PHP-FPM via mod_fastcgi
LoadModule fastcgi_module    ${MODFASTCGIPREFIX}/libexec/mod_fastcgi.so
 
<IfModule fastcgi_module>
  FastCgiConfig -maxClassProcesses 1 -idle-timeout 1500
 
  # Prevent accessing FastCGI alias paths directly
  <LocationMatch "^/fastcgi">
    <IfModule mod_authz_core.c>
      Require env REDIRECT_STATUS
    </IfModule>
    <IfModule !mod_authz_core.c>
      Order Deny,Allow
      Deny from All
      Allow from env=REDIRECT_STATUS
    </IfModule>
  </LocationMatch>
 
  FastCgiExternalServer /php-fpm -host 127.0.0.1:9000 -pass-header Authorization -idle-timeout 1500
  ScriptAlias /fastcgiphp /php-fpm
  Action php-fastcgi /fastcgiphp
 
  # Send PHP extensions to PHP-FPM
  AddHandler php-fastcgi .php
 
  # PHP options
  AddType text/html .php
  DirectoryIndex index.php index.html
</IfModule>
 
# Include our VirtualHosts
Include ${USERHOME}/Sites/httpd-vhosts.conf
EOF
)
```

We'll be using the file `~/Sites/httpd-vhosts.conf` to configure our VirtualHosts.
The `~/Sites` folder doesn't exist by default in OSX (10.10+).
We'll also create folders for logs and SSL files:

``mkdir -pv ~/Sites/{logs,ssl}``

``touch ~/Sites/httpd-vhosts.conf``

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/httpd-vhosts.conf <<EOF
#
# Listening ports.
#
#Listen 8080  # defined in main httpd.conf
Listen 8443
 
#
# Use name-based virtual hosting.
#
NameVirtualHost *:8080
NameVirtualHost *:8443
 
#
# Set up permissions for VirtualHosts in ~/Sites
#
<Directory "${USERHOME}/Sites">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    <IfModule mod_authz_core.c>
        Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order allow,deny
        Allow from all
    </IfModule>
</Directory>
 
# For http://localhost in the users' Sites folder
<VirtualHost _default_:8080>
    ServerName localhost
    DocumentRoot "${USERHOME}/Sites"
</VirtualHost>
<VirtualHost _default_:8443>
    ServerName localhost
    Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
    DocumentRoot "${USERHOME}/Sites"
</VirtualHost>
 
#
# VirtualHosts
#
 
## Manual VirtualHost template for HTTP and HTTPS
#<VirtualHost *:8080>
#  ServerName project.dev
#  CustomLog "${USERHOME}/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Sites/project.dev"
#</VirtualHost>
#<VirtualHost *:8443>
#  ServerName project.dev
#  Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
#  CustomLog "${USERHOME}/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Sites/project.dev"
#</VirtualHost>
 
#
# Automatic VirtualHosts
#
# A directory at ${USERHOME}/Sites/webroot can be accessed at http://webroot.dev
# In Drupal, uncomment the line with: RewriteBase /
#
 
# This log format will display the per-virtual-host as the first field followed by a typical log line
LogFormat "%V %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combinedmassvhost
 
# Auto-VirtualHosts with .dev
<VirtualHost *:8080>
  ServerName dev
  ServerAlias *.dev
 
  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
</VirtualHost>
<VirtualHost *:8443>
  ServerName dev
  ServerAlias *.dev
  Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
 
  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
</VirtualHost>
EOF
)
```

```shell
export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/ssl/ssl-shared-cert.inc <<EOF
SSLEngine On
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
SSLCertificateFile "${USERHOME}/Sites/ssl/selfsigned.crt"
SSLCertificateKeyFile "${USERHOME}/Sites/ssl/private.key"
EOF
)
```

```shell
openssl req \
  -new \
  -newkey rsa:2048 \
  -days 3650 \
  -nodes \
  -x509 \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=$(whoami)/CN=*.dev" \
  -keyout ~/Sites/ssl/private.key \
  -out ~/Sites/ssl/selfsigned.crt

```

``ln -sfv $(brew --prefix httpd22)/homebrew.mxcl.httpd22.plist ~/Library/LaunchAgents``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.httpd22.plist``

httpd.conf is running Apache on ports 8080 and 8443. The next two commands will create and load a firewall rule to forward port 80 requests to 8080, and port 443 requests to 8443.

```shell
sudo bash -c 'export TAB=$'"'"'\t'"'"'
cat > /Library/LaunchDaemons/co.echo.httpdfwd.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>Label</key>
${TAB}<string>co.echo.httpdfwd</string>
${TAB}<key>ProgramArguments</key>
${TAB}<array>
${TAB}${TAB}<string>sh</string>
${TAB}${TAB}<string>-c</string>
${TAB}${TAB}<string>echo "rdr pass proto tcp from any to any port {80,8080} -> 127.0.0.1 port 8080" | pfctl -a "com.apple/260.HttpFwdFirewall" -Ef - &amp;&amp; echo "rdr pass proto tcp from any to any port {443,8443} -> 127.0.0.1 port 8443" | pfctl -a "com.apple/261.HttpFwdFirewall" -Ef - &amp;&amp; sysctl -w net.inet.ip.forwarding=1</string>
${TAB}</array>
${TAB}<key>RunAtLoad</key>
${TAB}<true/>
${TAB}<key>UserName</key>
${TAB}<string>root</string>
</dict>
</plist>
EOF'
```

**To load it manually**

``sudo launchctl load -Fw /Library/LaunchDaemons/co.echo.httpdfwd.plist``

##Install PHP versions

####Check for availability of Image Magic plugins

``brew search imagick``

####PHP 5.6

``brew install php56-imagick``

``brew reinstall -v homebrew/php/php56 --with-fpm --with-postgresql --with-imap --with-homebrew-openssl --with-apache``

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; sed -i '-default' -e 's|^;\(date\.timezone[[:space:]]*=\).*|\1 \"'$(sudo systemsetup -gettimezone|awk -F"\: " '{print $2}')'\"|; s|^\(memory_limit[[:space:]]*=\).*|\1 512M|; s|^\(post_max_size[[:space:]]*=\).*|\1 200M|; s|^\(upload_max_filesize[[:space:]]*=\).*|\1 100M|; s|^\(default_socket_timeout[[:space:]]*=\).*|\1 600|; s|^\(max_execution_time[[:space:]]*=\).*|\1 300|; s|^\(max_input_time[[:space:]]*=\).*|\1 600|; $a\'$'\n''\'$'\n''; PHP Error log\'$'\n''error_log = '$USERHOME'/Sites/logs/php-error_log'$'\n' $(brew --prefix)/etc/php/5.6/php.ini)
```

``sudo chown -R $USER $(brew --prefix php56)/lib/php``

``chmod -R ug+w $(brew --prefix php56)/lib/php``

``ln -sfv $(brew --prefix php56)/*.plist ~/Library/LaunchAgents/``

####PHP 5.5

``brew install php55-imagick``

``brew reinstall -v homebrew/php/php55 --with-fpm --with-postgresql --with-imap --with-homebrew-openssl --with-apache``

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; sed -i '-default' -e 's|^;\(date\.timezone[[:space:]]*=\).*|\1 \"'$(sudo systemsetup -gettimezone|awk -F"\: " '{print $2}')'\"|; s|^\(memory_limit[[:space:]]*=\).*|\1 512M|; s|^\(post_max_size[[:space:]]*=\).*|\1 200M|; s|^\(upload_max_filesize[[:space:]]*=\).*|\1 100M|; s|^\(default_socket_timeout[[:space:]]*=\).*|\1 600|; s|^\(max_execution_time[[:space:]]*=\).*|\1 300|; s|^\(max_input_time[[:space:]]*=\).*|\1 600|; $a\'$'\n''\'$'\n''; PHP Error log\'$'\n''error_log = '$USERHOME'/Sites/logs/php-error_log'$'\n' $(brew --prefix)/etc/php/5.5/php.ini)
```

``sudo chown -R $USER $(brew --prefix php55)/lib/php``

``chmod -R ug+w $(brew --prefix php55)/lib/php``

``ln -sfv $(brew --prefix php55)/*.plist ~/Library/LaunchAgents/``

####PHP 5.3

``brew install -v
homebrew/php/php53 --with-fpm --with-postgresql --with-imap --with-homebrew-openssl``

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; sed -i '-default' -e 's|^;\(date\.timezone[[:space:]]*=\).*|\1 \"'$(sudo systemsetup -gettimezone|awk -F"\: " '{print $2}')'\"|; s|^\(short_open_tag[[:space:]]*=\).*|\1 On|; s|^\(memory_limit[[:space:]]*=\).*|\1 512M|; s|^\(post_max_size[[:space:]]*=\).*|\1 200M|; s|^\(upload_max_filesize[[:space:]]*=\).*|\1 100M|; s|^\(default_socket_timeout[[:space:]]*=\).*|\1 600|; s|^\(max_execution_time[[:space:]]*=\).*|\1 300|; s|^\(max_input_time[[:space:]]*=\).*|\1 600|; $a\'$'\n''\'$'\n''; PHP Error log\'$'\n''error_log = '$USERHOME'/Sites/logs/php-error_log'$'\n' $(brew --prefix)/etc/php/5.3/php.ini)
```

``sudo chown -R $USER $(brew --prefix php53)/lib/php``

``chmod -R ug+w $(brew --prefix php53)/lib/php``

``ln -sfv $(brew --prefix php53)/*.plist ~/Library/LaunchAgents/``

##Install phing

``cd /usr/local/Cellar/php55/5.5.XX/bin/``

``sudo pear channel-discover pear.phing.info``

``sudo pear install --alldeps phing/phing``

``cd /usr/local/Cellar/php55/5.5.XX/bin``

``sudo chown $USER phing``

``cd /usr/local/bin``

``ln -s ../Cellar/php55/5.5.XX/bin/phing``

##Install DNSMASQ and configure for .dev

``brew install -v dnsmasq``

``echo 'address=/.dev/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf``

``echo 'listen-address=127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf``

``echo 'port=35353' >> $(brew --prefix)/etc/dnsmasq.conf``

``ln -sfv $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist ~/Library/LaunchAgents``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.dnsmasq.plist``

``sudo mkdir -v /etc/resolver``

``sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/dev'``

``sudo bash -c 'echo "port 35353" >> /etc/resolver/dev'``

To test, the command ``ping -c 3 fakedomainthatisntreal.dev`` should
return results from ``127.0.0.1``. If it doesn't work right away, try
turning WiFi off and on

##Paths
Place the following in you .zshrc/.bashrc/.profile file in your home directory:

``export PATH="/Users/$USER/bin:/usr/local/sbin:$PATH"``

``export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"``

##Start Up Commands

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.httpd22.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.php56.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.php55.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.php53.plist``


##Shutdown Commands

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.httpd22.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php56.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php55.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php53.plist``


##Swapping PHP versions

####— PHP56

``brew unlink php55 && brew unlink php53``

``brew link php56``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php55.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php53.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.php56.plist``


####— PHP55

``brew unlink php56 && brew unlink php53``

``brew link php55``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php56.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php53.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.php55.plist``


####— PHP53

``brew unlink php55 && brew unlink php56``

``brew link php53``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php55.plist``

``launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.php56.plist``

``launchctl load -Fw ~/Library/LaunchAgents/homebrew.mxcl.php53.plist``

##END SETUP

###NOTES

####To check log files for error output

**Apache:** 

* ``$(brew --prefix)/var/log/apache2/error_log``
* ``$(brew --prefix)/var/log/apache2/access_log``
* ``httpd -DFOREGROUND``

**PHP-FPM:** 

* ``$(brew --prefix)/var/log/php-fpm.log``

**MySQL:**

* ``$(brew --prefix)/var/mysql/$(hostname).err``

**DNSMasq:**

* No log file, run this in terminal to watch output: 
* ``dnsmasq --keep-in-foreground ``




**If you don't want/need launchctl for PostgreSQL, you can just run:**

``pg_ctl -D /usr/local/var/postgres -l logfile start``

``pg_ctl -D /usr/local/var/postgres -l logfile -m fast stop``

**If you don't want/need launchctl for MySQL, you can just run:**

``mysql.server start``

``mysql.server stop``


####To use FastCGI:

You must manually edit ``/usr/local/etc/apache2/2.2/httpd.conf`` to contain:

  ``LoadModule fastcgi_module /usr/local/Cellar/mod_fastcgi/2.4.6/libexec/mod_fastcgi.so``
  
Upon restarting Apache, you should see the following message in the error log:

  ``[notice] FastCGI: process manager initialized``
  

####Paths of note:

* ``/usr/local/bin/php``
* ``/usr/local/etc/php/5.3/php.ini``
* ``/usr/local/etc/php/5.5/php.ini``
* ``/usr/local/etc/php/5.6/php.ini``
* ``/usr/local/opt/php53/libexec/apache2/libphp5.so``
* ``/usr/local/opt/php55/libexec/apache2/libphp5.so``
* ``/usr/local/opt/php56/libexec/apache2/libphp5.so``
* ``~/Sites/httpd-vhosts.conf``
* ``~/Sites/logs/dev-access_log``
* ``~/Sites/logs/dev-error_log``
* ``/usr/local/var/log/php-fpm.log``
* ``/usr/local/var/log/apache2/access_log``
* ``/usr/local/var/log/apache2/error_log``



