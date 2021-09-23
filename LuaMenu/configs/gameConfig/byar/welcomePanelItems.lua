local welcomePanelItems = {
    {
        Header = "Welcome to BAR Alpha",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Welcome Commander! We hope you are ready for epic single player and multiplayer battles!\n",
    },

    --[[
    {
        Header = "Map Download Issues",
        Url = "https://drive.google.com/drive/folders/16eBcMpkgMTV9mlKxYmNda64X_dmCFdkk",
        Time = nil,-- "NowTime",
        Text = "We are experiencing some issues with automatic map downloads. You can download all of the maps from the google drive link in the title and just put them into /data/maps/ .",
    },
    {
        Header = "Server Moved",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "We have moved the multiplayer lobby server from road-flag.bnr.la:8200 to bar.teifion.co.uk:8200. We hope games will continue to be uninterrupted, report any connectivity issues to us on Discord!\n Please update your game to automatically switch over, and if you need to manually switch servers, you can do so in Settings->Lobby->Choose Server" ,
    },]]--
    {
        Header = "New single player scenarios",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Play these from the single player menu on the left, and tell us what you think of them on Discord in the #scenarios channel.\n" ,
    },
    {
        Header = "New code of conduct",
        Url = nil,--"https://www.beyondallreason.info/code-of-conduct",
        Time = nil,-- "NowTime",
        Text = "We recently updated our code of conduct; be sure to check it out. As our community growth we've added the ability to report problems, click a user and select 'report user' to alert the moderator team to an issue. See the full code of conduct at https://www.beyondallreason.info/code-of-conduct",
    },
    {
        Header = "Play with your friends: use our servers!",
        Url = nil,--"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Join any empty room (marked blue) with your friends and type !boss to be able to !lock the game. Hosting your own private battles is under development, but there are always empty rooms on demand, just use them.",
    },
    {
        Header = "Multiplayer battle room commands",
        --Url = "https://www.beyondallreason.info/",
        --Time = "NowTime",
        Text = "Type these commands into the battle room chat\n" ..
               "!help - The battle room will give you detailed commands in the chat tab\n" ..
               -- "!boss username - set username as a boss to gain full control (to disable: !boss)\n" ..
               "!preset team - sets the room to Team vs Team game\n" ..
               "!preset ffa - sets the room to Free-for-all game\n" ..
               "!preset coop - sets all players to one team and AIs to the other\n" ..
               -- "!fixcolors - Makes sure players dont have identical colors\n" ..
               "!forcestart - starts the game even if teams arent balanced or colors arent fixed\n" ..
               "!autobalance off - turns off automatic balancing (Recommended for PVE)\n" ..
               "!autofixcolors off - turns off automatic color assignment\n" 
               --"  !force Playername bonus [0-100] - Sets a % resource bonus for player or AI\n"..
               --"  !force Playername team 1 - Places player or AI into a specific team"
               ,
    },
}

return welcomePanelItems
