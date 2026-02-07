--[[ -- example
    {
        Header = "bla",
        Text = "bla",
        Url = "https://www.beyondallreason.info",
        UrlText = "Beyond All Reason Website",
        Image = "LuaMenu/configs/gameConfig/byar/images/bla.png",
        Time = "2023-05-06T14:00:00", -- needs to be in UTC and is converted to user's local timezone, shows the time difference
    }
]]


local welcomePanelItems = {

    {
        Header = "Welcome to Beyond All Reason",
        Text = "Welcome back Commander. We hope you are ready for epic Singleplayer and Multiplayer battles. Check out our Discord and join the community!\n",
    },

    {
        Header = "This Month in BAR - February 2026",
        Text = "We've bundled several smaller updates into one bigger announcement! Check out recent UI/UX improvements, the experimental Easy-Tax game mode, an expanded mini-map widget with Picture-in-Picture support, and much more!" .. " \n" .. " \n",
        Url = "https://server4.beyondallreason.info/microblog/show/172",
        UrlText = "Read the Full Update",
    },

    {
        Header = "Update on the recent servers instability",
        Text = "We prepared a detailed post about the recent server instability issues and the steps we are taking to resolve them. Thank you for your patience and continued support!" .. " \n" .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/169",
        UrlText = "Read the full update",
    },

    {
        Header = "New Map: Proving Grounds",
        Text = "Introducing Proving Grounds, a very big space asteroid map with no wind, suitable for 8v8 and more. " .. " \n" .. " \n" .. "Perfect for large-scale epic battles!" .. " \n" .. " \n" .. "By Nikuksis",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/Proving_Grounds_v1.0.png",
    },

--    {
--        Header = "Upcoming Events:",
--    },

    {
        Header = "Help Keep BAR Clean - Join the Overwatch Team!",
        Text = "As BAR grows, so does the need for solid community moderation. We're looking for reliable, level-headed players to join the Overwatch Team—a trusted group that helps review reports, flag issues, and keep things fair.".." \n".." \n".."If you’re active and care about a respectful game space, we’d love your help!".." \n".." \n".."Grab the development role from ⁠Channels & Roles to access the thread below:",
        Image = "LuaMenu/images/welcomepanel/overwatch.png",
        Url = "https://discord.com/channels/549281623154229250/1097438343861649458",
        UrlText = "Sign Up for Overwatch",
    },

    {
        Header = "The Lightbringer Update is Here!",
        Text = "Commanders, after two weeks of a testing run for the Lightbringer Update, we are thrilled to announce the merge went without any major issues. This update represents the largest visual overhaul we have ever attempted. Enjoy BAR battles being more lit than ever!" .. " \n" .. " \n" .. "We have prepared a detailed post about the update and a Cinematic Highlights Video, check it out!",
	    Image = "LuaMenu/images/welcomepanel/lightbringerbox.png",
        Url = "https://www.beyondallreason.info/news/lightbringer-update",
        UrlText = "Read the Full Changes",
    },
    
    {
        Header = "Now Available: BAR Guides",
        Text = "New to Beyond All Reason? Check out these new Guides on Discord written by Zeteo!" .. " \n" .. " \n",
        Url = "https://discord.com/channels/549281623154229250/1303141562120929320/1303141562120929320",
        UrlText = "Read the new Guides",
    },

    {
        Header = "BAR is accepting donations again! ",
        Text = "Dear Commanders, we are delighted to announce the reopening of our donation platform after a longer-than-expected hiatus." .. " \n" .. " \n" .. "As we've been hard at work refining BAR to ensure maximum enjoyment for our ever-expanding community, we repeatedly placed donation efforts on hold to focus on other priorities." .. " \n" .. " \n" .. "Support BAR with our newly reopened donation platform!" .. " \n",
        Image = "LuaMenu/images/welcomepanel/donate.png",
        Url = "https://www.beyondallreason.info/news/support-bar-with-our-newly-reopened-donation-platform",
        UrlText = "Read Announcement",
    },

    --{
    --    Header = "Please help us test new engines!",
    --    Text = "Just select [Engine Test] in the launcher dropdown, and then play Skirmish and Multiplayer games. AMD testers especially needed. Report anything out of the ordinary to Discord!\n",
    --    UrlText = "BAR #engine channel on Discord"
    --},

    {
        Header = "Steam release roadmap",
        Url = "https://www.beyondallreason.info/development/steam-release",
        Text = "We've published our Steam Release roadmap, check it out on the website!",
        UrlText = "Roadmap Link"
    },

    --[[
    {
        Header = "New engine release",
        Text = "We've just released a new engine update. Be sure to report any issues to #bugreports on the discord and thank you for bearing with us through any teething problems with it.."
    },
    --]]

    {
        Header = "Play with your friends: use our servers!",
        Text = "Join any empty (blue), or waiting (green) battle to start playing, or host your own public or private battle by clicking the Host Game button in the Multiplayer Battle List",
    },

    {
        Header = "Useful commands in Multiplayer!",
        Text = "!boss [nickname] \n" ..
            "Boss someone (or yourself) in your battleroom so that person can set all the settings up without voting. You automatically become a boss of a room that you Host yourself.\n" ..
            " \n" ..
            "!forcestart \n" ..
            "If your game is stuck because of some AFK player that refuses to load or press ready, or you encountered a bug that prevents your game from starting, or you set up weird teams, !forcestart is your savior.\n" ..
            " \n" ..
            "!stop \n" ..
            "If you need to terminate the game you're currently playing for whatever reason, !stop will happily do it for you.\n" ..
            " \n" ..
            "!promote \n"  ..
            "Sends a little message on ingame main chat that your room is waiting for people to join.\n" ..
            " \n" ..
            "$rename [name] \n"  ..
            "Renames the battleroom you're currently in. Requires you to be the !boss of the battleroom to do so.\n" ..
            " \n" ..
            "$setratinglevels [min] [max] \n"  ..
            "Sets minimum and maximum skill rating allowed in the room.\n" ..
            " \n" ..
            "$resetratinglevels\n"  ..
            "Removes skill rating limits from the room.\n" ..
            " \n" ..
            "$explain \n" ..
            "Gives you a nice breakdown of how the autobalance works in your current battleroom.\n" ..
            " \n" ..
            "For a full list of commands, use !help and $help in any multiplayer room." ..
            " \n" ..
            " \b",
    },

}

return welcomePanelItems
