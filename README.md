# jGrundner Mac Local Bin #

This is just a collection of utility scripts used on my Macs.

## What is this repository for?

* Things I get tired of typing out on the command line
* Version 2.1

## Scripts

* __dev__: This script controls starting and stopping local dev servers.
    * __Servers__: Apache, MySQL, PostgreSQL
    * __Instructions__: `dev --help`


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

### 2.1
* Removed PHP 5.2 support

### 2.0

* Changes for OSX Mavericks and Homebrew development environment

### 1.0 ###
* This is the initial version of the plugin.