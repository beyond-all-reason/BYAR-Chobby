local welcomePanelItems = {
    {
        Header = "Welcome to BAR Alpha",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Welcome Commander! We hope you are ready for epic single player and multiplayer battles!\n",
    },
    {
        Header = "New single player scenarios",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Play these from the single player menu on the left, and tell us what you think of them on Discord in the #scenarios channel.\n" ,
    },
    {
        Header = "Beyond All Reason Alpha Championship Cup #1",
        Url = "https://challonge.com/tournaments/signup/Q3uHJAKUer#/signup/5fqraa2y7uf",
        Time = nil, --"",
        Text = "Click above for more info!\nFormat: 1v1 - Single Stage - Double Elimination\nDate: Sat 10th April - 15:00 UTC\nGames per Round: Round 1 = Bo1, Middle rounds = Bo3, Grand finals = Bo5\nStart Positions: Default startboxes (not fixed positions)\n \nMaps:\n    Round 1 (Bo1): Quicksilver\n    Round 2 (Bo3): Altair Crossing, Avalanche, Fallendell\n    Round 3 (Bo3): Barren, Flooded Valley, Red Comet\n    Winners & Losers finals (Bo3): Titan Duel, Ravaged, Comet Catcher\n    Grand Finals (Bo5): Tundra, Seth's Ravine, Paradise Lost, Cervino, Nuclear Winter\n    Grand Finals Rematch (Bo5) (if loser bracket player wins): First map = Quicksilver, then loser picks\n    3rd Place Decider (Bo3): First map = Sertaleina, then loser picks\n \nPrize Pool: €220, courtesy of Jazcash (200$) and Badosu (20$)\n    1st Place: 60% (€132)\n    2nd Place: 30% (€66)\n    3rd Place: 10% (€22)\n \nSome ground rules:\n    No spec / stream cheating\n    No custom widgets\n    Try to be timely and don't keep people waiting\nMaps and player limit may be subject to change.\nKeep your eye on #announcements and #tournament channel in discord for more info.\nFeel free to direct any questions to @Jazcash on Discord!"
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
               "!autobalance off - turns off automatic balancing (Recommended for PVE):\n" 
               --"  !force Playername bonus [0-100] - Sets a % resource bonus for player or AI\n"..
               --"  !force Playername team 1 - Places player or AI into a specific team"
               ,
    },
}

return welcomePanelItems