#!/bin/bash
############################################################################
# 
# Start and Stop the development environment
# 
# @author James Grundner <james@jgrundner.com>
# v1.0 November 10, 2013
# @version v4.0 June 2, 2015
# 
############################################################################
#                User Definable                                            #
############################################################################
ARGV=$1
#HTTPPASSWORD="SET-TO-YOUR-PASSWORD"
# Apache / PHP
APACHECTL="/usr/local/bin/apachectl"
PHP_EXE="/usr/local/bin/php"
# PostgreSQL
PGSQL_DATA="/usr/local/var/postgres"
PGSQL_LOGS="/usr/local/var/postgres/server.log"
PGSQL_PID_FILE="/usr/local/var/postgres/postmaster.pid"
PGSQL_CTL="/usr/local/bin/pg_ctl"
# MySQL
MYSQL_LOGS=$(brew --prefix)/var/mysql/$(hostname).err
MYSQL_PID=$(brew --prefix)/var/mysql/$(hostname).pid
MYSQL_INIT_SCRIPT=mysql.server
# Logs
APACHE_ERROR_LOG=$(brew --prefix)/var/log/apache2/error_log
APACHE_ACCESS_LOG=$(brew --prefix)/var/log/apache2/access_log
DEV_ERROR_LOG="/Users/$USER/Sites/logs/dev-error_log"
DEV_ACCESS_LOG="/Users/$USER/Sites/logs/dev-access_log"
PHP_FPM_LOG="/usr/local/var/log/php-fpm.log"
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
	apache_stop
    mysql_stop
    postgres_stop
    RETVAL=$?
}
start(){
	apache_start
    mysql_start
    postgres_start
    RETVAL=$?
}
restart(){
    stop
    start
}

status(){
	apache_status
	mysql_status
	postgres_status
}

apache_start(){
	echo "-> Starting Apache"
    brew services start httpd22
    sleep 1
}
apache_stop(){
	echo "-> Shutting down Apache"
    brew services stop httpd22
    sleep 1
}
apache_restart(){
	apache_stop
	apache_start
}
apache_logs(){
    echo "-> Apache error:  $APACHE_ERROR_LOG"
    echo "-> Apache access: $APACHE_ACCESS_LOG"
    echo "-> Dev error:     $DEV_ERROR_LOG"
    echo "-> Dev access:    $DEV_ACCESS_LOG"
}
apache_error_log_stream(){
    tail -f $APACHE_ERROR_LOG
}
apache_access_log_stream(){
    tail -f $APACHE_ACCESS_LOG
}
apache_dev_error_stream(){
    tail -f $DEV_ERROR_LOG
}
apache_dev_access_stream(){
    tail -f $DEV_ACCESS_LOG
}
apache_status(){
	echo ""
	echo "-> Apache Status: "
	$APACHECTL status
}

mysql_start(){
	echo "-> Starting MySQL"
    #$MYSQL_INIT_SCRIPT start
    brew services start mysql
    sleep 1
}
mysql_stop(){
	echo "-> Shutting down MySQL"
    #$MYSQL_INIT_SCRIPT stop
    brew services stop mysql
    sleep 1
}
mysql_restart(){
	mysql_stop
	mysql_start
}
mysql_log(){
    echo "-> $MYSQL_LOGS"
}
mysql_log_stream(){
    tail -f $MYSQL_LOGS
}
mysql_pid_file(){
    echo "-> $MYSQL_PID"
}
mysql_status(){
	echo ""
	echo "-> MySQL Status: "
	$MYSQL_INIT_SCRIPT status
}
mysql_status_long(){
	echo ""
	echo "-> MySQL Status: "
	mysqladmin -u root -p status
	# expect -c "
	#         spawn mysqladmin -u root -p status
	#         expect {
	#             "*password:*" { send $HTTPPASSWORD\r\n; interact }
	#             eof { exit }
	#         }
	#         exit
	#     "
}

postgres_start(){
    echo '-> Starting Postgresql'
    #$PGSQL_CTL -D $PGSQL_DATA -l $PGSQL_LOGS start
	brew services start postgresql
    sleep 1
}
postgres_stop(){
    echo '-> Shutting down Postgresql'
    #$PGSQL_CTL -D $PGSQL_DATA stop -m fast
	brew services stop postgresql
    sleep 1
}
postgres_restart(){
	postgres_stop
	postgres_start
}
postgres_log(){
    echo echo "-> $PGSQL_LOGS"
}
postgres_log_stream(){
    tail -f $PGSQL_LOGS
}
postgres_pid_file(){
    echo "-> $PGSQL_PID_FILE"
}
postgres_status(){
	echo ""
	echo "-> PostgreSQL Status: "
	$PGSQL_CTL status -D $PGSQL_DATA
}

load_php53(){
	echo "-> Loading PHP 5.3"
	brew services start php53
    sleep 1
}
unload_php53(){
	echo "-> Unloading PHP 5.3"
	brew services stop php53
    sleep 1
}
load_php56(){
	echo "-> Loading PHP 5.6"
	brew services start php56
    sleep 1
}
unload_php56(){
	echo "-> Unloading PHP 5.6"
	brew services stop php56
    sleep 1
}

php_logs(){
    echo "-> $PHP_FPM_LOG"
}
php_log_stream(){
    tail -f $PHP_FPM_LOG
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
		unload_php56
        brew unlink php56 && brew link php53
		load_php53
		apache_restart
		end_session
    ;;
    use56)
		unload_php53
        brew unlink php53 && brew link php56
		load_php56
		apache_restart
		end_session
    ;;
    php)
        if [ -z $2 ] ; then
            $PHP_EXE -v
        else
            case "$2" in
                log)
                    php_logs ;;
                tail)
                    php_log_stream ;;
            esac 
        fi
    ;;
    test)
        echo "$APACHECTL configtest"
        $APACHECTL configtest
    ;;
    apache)
        case "$2" in
            stop)
                apache_stop ;;
            start)
                apache_start ;;
            restart)
                apache_restart ;;
            logs)
                apache_logs ;;
			status)
				apache_status ;;
            tail)
                case "$3" in
                    error)
                        apache_error_log_stream ;;
                    access)
                        apache_access_log_stream ;;
                    deverror)
                        apache_dev_error_stream ;;
                    devaccess)
                        apache_dev_access_stream ;;
                esac 
            ;;
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
            log)
                postgres_log ;;
            tail)
                postgres_log_stream ;;
            pidfile)
                postgres_pid_file ;;
			status)
				postgres_status ;;
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
            log)
                mysql_log ;;
            tail)
                mysql_log_stream ;;
            pidfile)
                mysql_pid_file ;;
			status)
				mysql_status ;;
			fullstatus)
				mysql_status_long ;;
        esac
        end_session
    ;;
	start)
		apache_start
		mysql_start
		postgres_start
		end_session
	;;
	stop)
		apache_stop
		mysql_stop
		postgres_stop
		end_session
	;;
	restart)
		apache_restart
		mysql_restart
		postgres_restart
		end_session
	;;
	status)
		status
	;;
    *)
        clear
        echo $"Usage: $0 
    Control the whole development environment at once
            stop      -- Stop the whole DEV environment
            start     -- Start the whole DEV environment
            restart   -- Restart the whole DEV environment
            status    -- Display all statuses
            test      -- Run server configuration test

    Switching PHP versions. Automatically restarts web server
            use53     -- Switch to php 5.3
            use56     -- Switch to php 5.6
            php       -- Display which version is linked
            php [log|tail]

    Controlling individual components 
            postgres  [stop|start|restart|log|tail|pidfile|status]  -- PostgreSQL
            mysql     [stop|start|restart|log|tail|pidfile|status|fullstatus]  -- MySQL
            apache    [
                          stop
                          start
                          restart
                          logs
                          status
                          tail [error|access|deverror|devaccess]
                      ]  -- Apache
        "
        exit 1;;
esac

exit 0

############################################################################
# Voila, Nous sont finis!
############################################################################