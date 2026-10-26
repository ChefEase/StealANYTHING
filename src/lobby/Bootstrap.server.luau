--!strict
require(script.Parent.LobbyWorld).Build()
require(script.Parent.LobbySeatingService).Start()
require(script.Parent.WardrobeService).Start()

local LobbyService = require(script.Parent.LobbyService)
LobbyService.Start()
