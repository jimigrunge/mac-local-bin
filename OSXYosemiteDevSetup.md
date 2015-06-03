#Installing dev Environment On Mac OSX 10.10 Yosemite

Based on [ALAN IVEY's setup](https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew)


##Install xCode and command line tools

On OSX 10.10.2+ We need to manually re-install the command line tools.

``xcode-select --install``

##Install HomeBrew

If you've not already installed Homebrew, you can follow the instructions at [http://brew.sh](http://brew.sh). 

``ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"``

##Install GIT, if missing

If you do not have git available on your system, either from Homebrew, Xcode, or another source, you can install it with Homebrew now

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

brew tap homebrew/services
```

This last command leverages the new brew services command. No longer any need to mess with `launchctl`. 
More information can be found at [brew services](https://github.com/Homebrew/homebrew-services)

##Install PostgreSQL

``brew install postgresql``

``brew services start postgresql``

Default database user will automatically be set to your system username with no password. 
To see your system username type the  into the console.

``echo $USER``

##Install MySQL

###Install MySQL with Homebrew:

``brew install mysql``

###Setup MySQL Configurations for performance

``cp -v $(brew --prefix mysql)/support-files/my-default.cnf $(brew --prefix)/etc/my.cnf``

```
cat >> $(brew --prefix)/etc/my.cnf <<'EOF'
    # -------------------------
    # Manual changes follow
	max_allowed_packet = 1073741824
	innodb_file_per_table = 1
EOF
```	

``sed -i '' 's/^#[[:space:]]*\(innodb_buffer_pool_size\)/\1/' $(brew --prefix)/etc/my.cnf``

###Start MySQL service

``brew services start mysql``

> By default, MySQL's root user has an empty password from any connection. 
> It is advisable to run mysql_secure_installation and at least set a password for the root user.
> ``$(brew --prefix mysql)/bin/mysql_secure_installation``

##Apache

###Stopping the built-in Apache, 
If Apache is running, stop it and prevent it from starting on boot. 
This is one of very few times you'll need to use sudo:

``sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null``

###Why Apache 2.2
We're installing Apache 2.2 with the event MPM and set up PHP-FPM instead of mod_php. 

1. switching PHP versions is far easier with PHP-FPM and the default 9000 port instead of also editing the Apache configuration to switch the mod_php module location

2. Not using mod_php we don't have to use the prefork MPM and can get better performance with event or worker.

3. I'm using 2.2 instead of 2.4 because popular projects like Drupal and WordPress still ship with 2.2-style .htaccess files.

4. 2.4 sometimes means you have to set up "compat" modules, and that's above the requirement for a local environment, in my opinion.

###Install Apache
Onward with the install. We'll use Homebrew's OpenSSL library since it's more up-to-date than OS X's

``brew install -v homebrew/apache/httpd22 --with-homebrew-openssl --with-mpm-event``

In order to get Apache and PHP to communicate via PHP-FPM, we'll install the mod_fastcgi module:

``brew install -v homebrew/apache/mod_fastcgi --with-homebrew-httpd22``

To prevent any potential problems with previous mod_fastcgi setups, let's remove all references to the mod_fastcgi module 
( _we'll re-add the new version later_ )

``sed -i '' '/fastcgi_module/d' $(brew --prefix)/etc/apache2/2.2/httpd.conf``

###Configure Apache

Add the logic for Apache to send PHP to PHP-FPM with mod_fastcgi, and reference that we'll want to use the file 
`~/Sites/httpd-vhosts.conf` to configure our VirtualHosts.

**This is all one command, so copy and paste the entire code block at once:**

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; export MODFASTCGIPREFIX=$(brew --prefix mod_fastcgi) ; cat >> $(brew --prefix)/etc/apache2/2.2/httpd.conf <<EOF
 # -------------------------
 # Manual changes follow
 # -------------------------
 # Load PHP-FPM via mod_fastcgi
 # -------------------------
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
  AddType application/x-httpd-php .php
  DirectoryIndex index.php index.html
 </IfModule>
 # -------------------------
 # Include our VirtualHosts
 # -------------------------
Include ${USERHOME}/Sites/httpd-vhosts.conf
EOF
)
```

###Configure automated Vhosts

We'll be using the file `~/Sites/httpd-vhosts.conf` to configure our VirtualHosts.
The `~/Sites` folder doesn't exist by default in OSX (10.10+).
We'll also create folders for logs and SSL files:

``mkdir -pv ~/Sites/{logs,ssl}``

``touch ~/Sites/httpd-vhosts.conf``

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/httpd-vhosts.conf <<EOF
 # -------------------------
 # Listening ports.
 # -------------------------
 #Listen 8080  # defined in main httpd.conf
 # -------------------------
Listen 8443
 
 # -------------------------
 # Use name-based virtual hosting.
 # -------------------------
NameVirtualHost *:8080
NameVirtualHost *:8443
 
 # -------------------------
 # Set up permissions for VirtualHosts in ~/Sites
 # -------------------------
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
 # -------------------------
 # For http://localhost in the users' Sites folder
 # -------------------------
 <VirtualHost _default_:8080>
    ServerName localhost
    DocumentRoot "${USERHOME}/Sites"
	<Location "/server-status">
	   SetHandler server-status
	   Order allow,deny
	   Allow from all 
	</Location>
 </VirtualHost>
 <VirtualHost _default_:8443>
    ServerName localhost
    Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
    DocumentRoot "${USERHOME}/Sites"
	<Location "/server-status">
	   SetHandler server-status
	   Order allow,deny
	   Allow from all 
	</Location>
 </VirtualHost>
 
 # -------------------------
 # VirtualHosts
 # -------------------------
 ## Manual VirtualHost template for HTTP and HTTPS
 # -------------------------
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
 
 # -------------------------
 # Automatic VirtualHosts
 # -------------------------
 # A directory at ${USERHOME}/Sites/webroot can be accessed at http://webroot.dev
 # In Drupal, uncomment the line with: RewriteBase /
 # -------------------------
 # This log format will display the per-virtual-host as the first field followed by a typical log line
LogFormat "%V %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combinedmassvhost
 
 # -------------------------
 # Auto-VirtualHosts with .dev
 # -------------------------
 <VirtualHost *:8080>
  ServerName dev
  ServerAlias *.dev
 
  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
  <Location /server-status>
    SetHandler server-status
    Order allow,deny
    Deny from all
    Allow from dev
  </Location>
 </VirtualHost>
 <VirtualHost *:8443>
  ServerName dev
  ServerAlias *.dev
  Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
 
  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
  <Location /server-status>
    SetHandler server-status
    Order allow,deny
    Deny from all
    Allow from dev
  </Location>
 </VirtualHost>

ExtendedStatus On

EOF
)
```

###Configure SSL certs

You may have noticed that ~/Sites/ssl/ssl-shared-cert.inc is included multiple times; 
create that file and the SSL files it needs:

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/ssl/ssl-shared-cert.inc <<EOF
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

###Start Homebrew's Apache and set to start on login

``brew services start httpd22``

###Fix ports
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

The following is for the latest release of PHP, version 5.6. If you'd like to use 5.3, 5.4 or 5.5, 
simply change the "5.6" and "php56" values below appropriately.

###Image Magic support
If you need Image Magic support for image manipulation run the following commands.

See what versions are available:

``brew search imagick``

Install required version:

``brew install php56-imagick``


###Install PHP

We are installing with postgresql and imap support. Other options can be added as needed.

> If you installed with imagick then use `reinstall`

``brew install -v homebrew/php/php56 --with-postgresql --with-imap``

Set timezone and change other PHP settings (sudo is needed here to get the current timezone on OS X) 
to be more developer-friendly, and add a PHP error log (without this, 
you may get Internal Server Errors if PHP has errors to write and no logs to write to)

```shell
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; sed -i '-default' -e 's|^;\(date\.timezone[[:space:]]*=\).*|\1 \"'$(sudo systemsetup -gettimezone|awk -F"\: " '{print $2}')'\"|; s|^\(memory_limit[[:space:]]*=\).*|\1 512M|; s|^\(post_max_size[[:space:]]*=\).*|\1 200M|; s|^\(upload_max_filesize[[:space:]]*=\).*|\1 100M|; s|^\(default_socket_timeout[[:space:]]*=\).*|\1 600|; s|^\(max_execution_time[[:space:]]*=\).*|\1 300|; s|^\(max_input_time[[:space:]]*=\).*|\1 600|; $a\'$'\n''\'$'\n''; PHP Error log\'$'\n''error_log = '$USERHOME'/Sites/logs/php-error_log'$'\n' $(brew --prefix)/etc/php/5.6/php.ini)
```

###Fix a pear and pecl permissions problem

``sudo chown -R $USER $(brew --prefix php56)/lib/php``

``chmod -R ug+w $(brew --prefix php56)/lib/php``

###Opcache

The optional Opcache extension will speed up your PHP environment dramatically, so let's install it. Then, we'll bump up the opcache memory limit:

``brew install -v php56-opcache``

``/usr/bin/sed -i '' "s|^\(\;\)\{0,1\}[[:space:]]*\(opcache\.enable[[:space:]]*=[[:space:]]*\)0|\21|; s|^;\(opcache\.memory_consumption[[:space:]]*=[[:space:]]*\)[0-9]*|\1256|;" $(brew --prefix)/etc/php/5.6/php.ini``

###Finally, let's start PHP-FPM

``brew services start php56``

> Optional: At this point, if you want to switch between PHP versions, you'd want to: `brew services stop php56 && brew unlink php56 && brew link php54 && brew services start php54`. No need to touch the Apache configuration at all!

##Install phing

Replace 5.6.XX with your installed version

``cd /usr/local/Cellar/php56/5.6.XX/bin/``

``sudo ./pear channel-discover pear.phing.info``

``sudo ./pear install --alldeps phing/phing``

``sudo chown -R  $USER ../bin``

``chmod -R ug+w ../bin``

~~``sudo chown $USER phing``~~

``cd /usr/local/bin``

``ln -s ../Cellar/php56/5.6.XX/bin/phing``

##DNSMASQ

Never touch your local /etc/hosts file in OS X again.
Any DNS request ending in .dev reply with the IP address 127.0.0.1

###Install DNSMASQ
``brew install -v dnsmasq``

``echo 'address=/.dev/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf``

``echo 'listen-address=127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf``

``echo 'port=35353' >> $(brew --prefix)/etc/dnsmasq.conf``

###Start DNSMasq

`brew services start dnsmasq`

###Configure 
With DNSMasq running, configure OS X to use your local host for DNS queries ending in .dev:

``sudo mkdir -v /etc/resolver``

``sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/dev'``

``sudo bash -c 'echo "port 35353" >> /etc/resolver/dev'``

###Test 
To test, the command ``ping -c 3 fakedomainthatisntreal.dev`` should
return results from ``127.0.0.1``. If it doesn't work right away, try
turning WiFi off and on

##Capistrano requirements

If you are going to use Capistrano/Capifony for pushing your code to servers then you will need to install the Ruby Version Manager. 
This will allow you to update Ruby and add gems without disturbing the Mac version of Ruby. 

###Install RVM, Ruby, and Rails

**Disable excess documentation** 

``echo "gem: --no-document" >> ~/.gemrc``

**Install RVM w/Ruby and Rails**

``\curl -L https://get.rvm.io | bash -s stable  --auto-dotfiles --autolibs=enabled --rails``

**Load RVM in current terminal session**

``source ~/.rvm/scripts/rvm``

**If it is not already there, place this in your ~/.profile file to load at every login**

``[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"``

**Check if RVM loaded as a function**

``type rvm | head -1``

**Check versions**

``rvm -v`` :: *rvm 1.26.11 at time of document*

``ruby -v`` :: *ruby 2.2.1p85 at time of document*

``rails -v`` :: *Rails 4.2.1 at time of document*

###Install Capifony

*For detailed instructions on installation and usage please see the [Capifony](http://capifony.org/) site.* 

**Run the following command to do a simple install**

``gem install capifony``

**Check install version**

``capifony --version`` :: *capifony v2.8.3 at time of document*

##END SETUP

#NOTES

##Paths
Place the following in you .zshrc/.bashrc/.profile file in your home directory:

``export PATH="/Users/$USER/bin:/usr/local/sbin:$PATH"``

``export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"``

##Start Up Commands

``brew services start postgresql``

``brew services start mysql``

``brew services start httpd22``

``brew services start php53``

``brew services start php56``

##Shutdown Commands

``brew services stop postgresql``

``brew services stop mysql``

``brew services stop httpd22``

``brew services stop php53``

``brew services stop php56``

##Swapping PHP versions

####— PHP56

``brew services stop php53 && brew unlink php53 && brew link php56 && brew services start php56``

####— PHP53

``brew services stop php56 && brew unlink php56 && brew link php53 && brew services start php53``

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



