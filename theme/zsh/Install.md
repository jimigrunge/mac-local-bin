#Installing oh-my-zsh
-

##Web

**Homepage:** http://ohmyz.sh/ 

**Wiki:** https://github.com/robbyrussell/oh-my-zsh/wiki

**Customization:** https://github.com/robbyrussell/oh-my-zsh/wiki/Customization 

**Plugins:** https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins-Overview 

##Install

###Check ZSH version:

    $ zsh --version

###Check default shell:

    $ echo $SHELL

###Make ZSH your default shell: 

    $ chsh -s $(chsh -l | grep "zsh" -m 1)

###Install DejaVuSansMono font

Located in theme/solorized/DejaVuSansMono-for-powerline.zip

###Install solorized OS X terminal colors

Located in theme/solorized/osx-terminal.app-colors-solarized

###Install Oh-My-Zsh:

    $ curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh 

###Install jimigrunge theme

    $ cp theme/zsh/jimigrunge.zsh-theme ~/.oh-my-zsh/themes/

###Replace config

    $ cp theme/zsh/dot-zshrc ~/.zshrc
	$ source ~/.zshrc
