# jGrundner Mac Local Bin #

This is just a collection of utility scripts used on my Macs.

## What is this repository for?

* Things I get tired of typing out on the command line
* This helps to control my development environment
	* Switching PHP versions
	* Starting and stoping MySQL and PostgreSQL
	* Starting and stoping Apache
* Version 4.0

## Scripts

* __server__: This script controls starting and stopping local dev servers.
    * __Servers__: Apache, MySQL, PostgreSQL
    * __Instructions__: `server --help`


##Installing

### Get the code
Checkout repository to your `/Users/<username>` directory:

    $ cd ~
    $ mkdir bin
    $ cd bin
    $ git clone https://jimigrunge@bitbucket.org/jimigrunge/mac-local-bin.git .

### Make files executable: 

    $ chmod -R u+x ~/bin

### Add path to your PATH. 
The file to edit may differ on your machine, please check your documentation.

    $ vi ~/.profile

Add this line

    if [ -d "$HOME/bin" ] ; then
        PATH="$PATH:$HOME/bin"
    fi

## Frequently Asked Questions ##

### Why isn't there any questions ###

* No one has asked any yet.

## Changelog ##

### 4.0
* Changed dev env install to use the new `brew services` command.
* Modified `server` script to use the new `brew services` command.
* Rewrite of the documentation.
* Removed PHP 5.5 support.
* `mysql fullstatus` now requires you to enter password, no longer stored.

### 3.3
* Added ability to show server statuses.
* Fixed typos in readme file.

### 3.2.2
* Fixed typos.

### 3.2
* Added more functions to server.
* Switched postgres to use pg_ctl due to server locks.
* Added myzsh config.

### 3.1.3
* Cleaning up configuration file.
* Changing MySQL to version 5.5 for client compatability.

### 3.1.2
* Cleaning up configuration file.
* Update OSX install guide to fix 10.10.2 issues.

### 3.1.1
* Added, Updated, and fixed typos in documentation.
* Refined shell script functions.

### 3.1
* Moved to OSX Yosemite.
* Dev setup is now based on <a href="https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew" target="_blank">ALAN IVEY's setup</a>.
* Adding my setup script. 
	* This is Alan's instructions modified with my unique requirements.

### 2.1
* Removed PHP 5.2 support.

### 2.0
* Changes for OSX Mavericks and Homebrew development environment.

### 1.0 ###
* This is the initial version of the plugin.