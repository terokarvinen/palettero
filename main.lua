-- Copyright 2022 Tero Karvinen http://TeroKarvinen.com
-- Command palette - fuzzy search commands and textfilters
-- A Micro editor plugin

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local menufile = config.ConfigDir.."/plug/palettero/palettero-defaults.cfg"
local userfile = config.ConfigDir.."/palettero.cfg"

function init()
	-- runs once when micro starts
	config.MakeCommand("palettero", paletteroCommand, config.NoComplete)
	config.TryBindKey("CtrlP", "command:palettero", false)
	config.TryBindKey("CtrlSpace", "command:palettero", false)
	-- config.TryBindKey("F1", "command:palettero", false)
	
	config.MakeCommand("editmenu", editmenuCommand, config.NoComplete)
	
	shell.ExecCommand("touch", userfile)
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

	local showMenuCmd = string.format("bash -c \"cat '%s' '%s'|fzf --layout=reverse\"", menufile, userfile)
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
