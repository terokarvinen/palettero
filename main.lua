-- Copyright 2022 Tero Karvinen http://TeroKarvinen.com
-- Command palette - fuzzy search commands and textfilters
-- A Micro editor plugin

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local os = import("os") -- Go library
local ioutil = import("io/ioutil") -- Go library
local strings = import("strings") -- Go library
local menufile = config.ConfigDir.."/plug/palettero/palettero-defaults.cfg"
local userfile = config.ConfigDir.."/palettero.cfg"
local collectedfile = config.ConfigDir.."/plug/palettero/palettero-collected.cfg"

function init()
	-- runs once when micro starts
	config.MakeCommand("palettero", paletteroCommand, config.NoComplete)
	config.TryBindKey("CtrlP", "command:palettero", false)
	config.TryBindKey("CtrlSpace", "command:palettero", false)
	-- config.TryBindKey("F1", "command:palettero", false)
	
	config.MakeCommand("editmenu", editmenuCommand, config.NoComplete)
	config.MakeCommand("updatemenu", collectRuntime, config.NoComplete)

	if not pathExists(collectedfile) then
		micro.InfoBar():Message("First run, Palettero running 'updatemenu'...")
		collectRuntime()
	end

	if not pathExists(userfile) then
		shell.ExecCommand("touch", userfile)
	end
end

-- ## Prompt ##

function commandBar(command)
	-- open ctrl-E command bar, fill it with start of command, allow user to fill the rest
	micro.InfoBar():Prompt("T> ", command, "Command", nil, promptDoneCallback)
end

function promptDoneCallback(resp, cancelled)
	-- called by prompt() when user is done with ctrl-E command bar
	if cancelled then
		micro.InfoBar():Message("Command cancelled.")
	end
	micro.InfoBar():Message("Running: ", resp)
	
	local bp = micro.CurPane()
	bp:HandleCommand(resp)
end

-- ## commands ##

function paletteroCommand(bp)
	-- ctrl-E palettero
	micro.InfoBar():Message("Palettero command palette activated!")

	local showMenuCmd = string.format("bash -c \"cat '%s' '%s' '%s'|fzf --layout=reverse\"", userfile, menufile, collectedfile)
	micro.Log("Requesting user input with: ", showMenuCmd) -- run 'micro --debug tero' to create log.txt
	local choice = shell.RunInteractiveShell(showMenuCmd, false, true)
	micro.Log("User chose: ", choice)
	local cmd = getCommand(choice)
	micro.Log("Command: ", cmd)
	if nil == cmd then
		micro.InfoBar():Message("Empty choice, not running.")
		return
	end
	micro.InfoBar():Message("Running: ", cmd)
	-- bp:HandleCommand(cmd)
	commandBar(cmd)
end

function editmenuCommand(bp)
	-- ctrl-E editmenu - add your own commands to Palettero command palette
	bp:HandleCommand("tab "..userfile)
end

-- ## Menu item collection ##

function getCommand(s)
	-- return command part of string, or empty if string starts with comment char
	-- "command # comment" -> "command"
	-- "# command # comment" -> ""
	-- "command # comment # comment" -> "command"

	if string.len(s) == 0 then
		return
	end

	if "#" == s:sub(1,1) then
		return "" -- string starts with comment character
	end
	
	local cmd = string.match(s, "([^#]*) ?#")
	if nil ~= cmd and string.len(cmd) > 0 then
		return cmd -- string had a comment char, return what was before it
	end

	return s -- no comment char in string	
end

function collectRuntime()
	-- collect Runtime items to collectedfile
	help = rtNames(config.RTHelp, "help")
	colorscheme = rtNames(config.RTColorscheme, "set colorscheme")
	data = help.."\n"..colorscheme
	-- Go (Golang) io.ioutil.WriteFile() is depraced, os.WriteFile() is recommended, 
	-- but the newer one is not in micro 2.0.11 as of 2022
	local perms = tonumber("0600", 8)
	local err = ioutil.WriteFile(collectedfile, help.."\n"..colorscheme, perms)
end

function rtNames(rtType, command)
	-- return a string with all rtType items, one item per line
	-- rtType should be one of 
	-- 0 config.RTColorscheme, 1 config.RTSyntax, 2 config.RTHelp, 3 config.RTPlugin, 4 config.RTSyntaxHeader
	-- add command at the start of each line, e.g. "plugins" -> "help plugins"
	-- a helper function for collectRuntime
	micro.Log(rtType, command)
	local goStyleItems = config.ListRuntimeFiles(rtType) -- returns Go type (not string, not Lua table)
	micro.Log("goStyleItems", goStyleItems)
	local itemsOnOneLine = strings.Join(goStyleItems, " ") -- go strings.Join(), returns one line Lua string
	multiLine = string.gsub(itemsOnOneLine, " ", "\n") -- convert to one word per line

	-- add "command " to start of each line
	multiLine = string.gsub(multiLine, "^", command.." ")
	multiLine = string.gsub(multiLine, "\n", "\n"..command.." ")
	
	return multiLine
end

-- ## Generic Helper Functions ##

function pathExists(path)
	-- return true if path (file or directory) exists
	local _, err = os.Stat(path)
	return err == nil
end
