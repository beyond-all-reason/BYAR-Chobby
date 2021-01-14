local welcomePanelItems = {
    {
        Header = "Welcome to BAR Alpha",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Welcome Commander! We have set up a single player skirmish for you, click start to jump right in!\n" .. 
        "Right now you can enjoy single player skirmish with multiple AIs or multiplayer battles, join one of active rooms to play with the community.\n" .. 
        "This lobby is currently being built, more functionality coming soon." ,
    },
    {
        Header = "Lobby Updates!",
        Url = nil,--"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Account recovery and start boxes on minimaps in progress!",
    },
    {
        Header = "Play with your friends",
        Url = nil,--"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Join any empty room with your friends and type !boss to be able to !lock the game. Hosting your own battles is under development.",
    },
    {
        Header = "Useful multiplayer battle room commands",
        --Url = "https://www.beyondallreason.info/",
        --Time = "NowTime",
        Text = "Type these commands into the battle room chat\n" ..  
               "!help - The battle room will give you detailed commands in the chat tab\n" .. 
               "!boss username - set username as a boss to gain full control (to disable: !boss)\n" ..
               "!preset teams - sets the room to Team vs Team game\n" ..  
               "!preset ffa - sets the room to Free-for-all game\n" ..
               "!preset coop - sets all players to one team and AIs to the other\n" ..
               "!fixcolors - Makes sure players dont have identical colors\n" ..
               "!forcestart - starts the game even if teams arent balanced or colors arent fixed\n" .. 
               "!autobalance off - turns off automatic balancing (Recommended for PVE):\n" ..
               "  !force Playername bonus [0-100] - Sets a % resource bonus for player or AI\n"..
               "  !force Playername team 1 - Places player or AI into a specific team"
               ,
    },
}

return welcomePanelItems