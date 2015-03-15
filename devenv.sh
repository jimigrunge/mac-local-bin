#!/bin/bash
############################################################################
# 
# Start and Stop the development environment
# 
# @author James Grundner <james@jgrundner.com>
# v1.0 November 10, 2013
# @version v3.1.1 March 12, 2015
# 
############################################################################
#                User Definable                                            #
############################################################################
# APACHECTL="/usr/sbin/apachectl"
# APACHEUSR="sudo"
# HTTPPASSWORD="rocker"
# MYSQL_INIT_SCRIPT=mysql.server
# PGSQL_INIT_SCRIPT='pg_ctl -D /usr/local/var/postgres -l /var/log/psql.log'
HTTPPASSWORD="rocker"
ARGV=$1
APACHECTL="/usr/local/bin/apachectl"
PHP_EXE="/usr/local/bin/php"
PGSQL_PLIST="/Users/$USER/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
MYSQL_PLIST="/Users/$USER/Library/LaunchAgents/homebrew.mxcl.mysql.plist"
HTTPD_PLIST="/Users/$USER/Library/LaunchAgents/homebrew.mxcl.httpd22.plist"
PHP53_PLIST="/Users/$USER/Library/LaunchAgents/homebrew.mxcl.php53.plist"
PHP55_PLIST="/Users/$USER/Library/LaunchAgents/homebrew.mxcl.php55.plist"
PHP56_PLIST="/Users/$USER/Library/LaunchAgents/homebrew.mxcl.php56.plist"
############################################################################
#                End of User Definable                                     #
############################################################################

############################################################################
# Get the source directory of this script
############################################################################
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
############################################################################

############################################################################
# Define functions
############################################################################
stop(){
	server_stop
    mysql_stop
    postgres_stop
    RETVAL=$?
}
start(){
	server_start
    mysql_start
    postgres_start
    RETVAL=$?
}
restart(){
    stop
    start
}

server_start(){
	echo "-> Starting Apache"
    launchctl load -Fw $HTTPD_PLIST
    sleep 1
}
server_stop(){
	echo "-> Shutting down Apache"
    launchctl unload $HTTPD_PLIST
    sleep 1
}
server_restart(){
	server_stop
	server_start
}

mysql_start(){
	echo "-> Starting MySQL"
    launchctl load -Fw $MYSQL_PLIST
    sleep 1
}
mysql_stop(){
	echo "-> Shutting down MySQL"
    launchctl unload $MYSQL_PLIST
    sleep 1
}
mysql_restart(){
	mysql_stop
	mysql_start
}

postgres_start(){
    echo '-> Starting Postgresql'
    launchctl load -Fw $PGSQL_PLIST
    sleep 1
}
postgres_stop(){
    echo '-> Shutting down Postgresql'
    launchctl unload $PGSQL_PLIST
    sleep 1
}
postgres_restart(){
	postgres_stop
	postgres_start
}

load_php53(){
	echo "-> Loading PHP 5.3"
    launchctl load -Fw $PHP53_PLIST
    sleep 1
}
unload_php53(){
	echo "-> Unloading PHP 5.3"
    launchctl unload $PHP53_PLIST
    sleep 1
}

load_php55(){
	echo "-> Loading PHP 5.5"
    launchctl load -Fw $PHP55_PLIST
    sleep 1
}
unload_php55(){
	echo "-> Unloading PHP 5.5"
    launchctl unload $PHP55_PLIST
    sleep 1
}

load_php56(){
	echo "-> Loading PHP 5.6"
    launchctl load -Fw $PHP56_PLIST
    sleep 1
}
unload_php56(){
	echo "-> Unloading PHP 5.6"
    launchctl unload $PHP56_PLIST
    sleep 1
}
end_session(){
    echo "-> Execution complete!"
}
############################################################################

############################################################################
# Excecute
############################################################################
case "$ARGV" in
    use53)
        brew unlink php55 && brew unlink php56 && brew link php53
		unload_php55
		unload_php56
		load_php53
		server_restart
		end_session
    ;;
    use55)
        brew unlink php53 && brew unlink php56 && brew link php55
		unload_php53
		unload_php56
		load_php55
		server_restart
		end_session
    ;;
    use56)
        brew unlink php53 && brew unlink php55 && brew link php56
		unload_php53
		unload_php55
		load_php56
		server_restart
		end_session
    ;;
    php)
        $PHP_EXE -v
    ;;
    test)
        echo "$APACHECTL configtest"
        $APACHECTL configtest
    ;;
    apache)
        case "$2" in
            stop)
                server_stop ;;
            start)
                server_start ;;
            restart)
                server_restart ;;
        esac
        end_session
    ;;
    postgres)
        case "$2" in
            stop)
                postgres_stop ;;
            start)
                postgres_start ;;
            restart)
                postgres_stop
                postgres_start ;;
        esac
        end_session
    ;;
    mysql) 
        case "$2" in
            stop)
                mysql_stop ;;
            start)
                mysql_start ;;
            restart)
                mysql_stop
                mysql_start ;;
        esac
        end_session
    ;;
	start)
		server_start
		mysql_start
		postgres_start
		end_session
	;;
	stop)
		server_stop
		mysql_stop
		postgres_stop
		end_session
	;;
	restart)
		server_restart
		mysql_restart
		postgres_restart
		end_session
	;;
    *)
        clear
        echo $"Usage: $0 
    Control the whole development environment at once
            stop      -- Stop the whole DEV environment
            start     -- Start the whole DEV environment
            restart   -- Restart the whole DEV environment
            test      -- Run server configuration test

    Switching PHP versions. Automatically restarts web server
            use53       -- Switch to php 5.3
            use55       -- Switch to php 5.5
            use56       -- Switch to php 5.6
            php         -- Display which version is linked

    Controlling individual components 
            postgres  [stop|start|restart]  -- PostgreSQL
            mysql     [stop|start|restart]  -- MySQL
            apache    [stop|start|restart]  -- Apache
        "
        exit 1;;
esac

exit 0

############################################################################
# Voila, Nous sont finis!
############################################################################