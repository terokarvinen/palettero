# Palettero - command palette / menu for Micro editor

Command palette for Micro editor - fuzzy search commands and textfilters

The first and original command paletter for Micro. 

![Screenshot](palettero-command-palette-menu-for-micro-editor.png)

# Usage

Press **Ctrl-P** to open Palettero. Type to fuzzy search commands and their descriptions. Use up and down arrows to move. Press enter to select, or Esc to cancel. 

Command is pre-filled to command bar. Edit the command, then press enter to execute. 

Tab completes file names in some commands, such as "tab" and "open". 

# Requirements

Requires fzf and bash, optionally pythonpy for extra features. 

	$ sudo apt-get update
	$ sudo apt-get -y install fzf
	$ sudo apt-get -y install pythonpy # optional

Only tested on Linux. 

# Installation

In the future, you will be able to install Palettero by 

	$ micro --plugin install palettero

Currently, there is just development install

	$ cd $HOME/.config/micro/plug/
	$ git clone https://github.com/terokarvinen/palettero

# Adding your own commands

You can add your own commands to $HOME/.config/micro/palettero.cfg

# Adminstrivia

https://TeroKarvinen.com/micro
