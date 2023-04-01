.. _interface:

Interface
=========

.. class:: Interface
   
    extends :ref:`observable`

    Used to send and receive all lobby commands.

    
    .. method:: SendCustomCommand(command)

    .. method:: AddBot(name, battleStatus, teamColor, aiDll)
    
    .. method:: AddStartRect(allyNo, left, top, right, bottom)
    
    .. method:: ChangeEmail(newEmail, userName)
    
    .. method:: ChangePassword(oldPassword, newPassword)
    
    .. method:: Channels()
    
    .. method:: ChannelTopic(chanName, topic)
    
    .. method:: ConfirmAgreement()
    
    .. method:: ConnectUser(userName, ipAndPort, scriptPassword)
    
    .. method:: DisableUnits(...)
    
    .. method:: EnableAllUnits()
    
    .. method:: EnableUnits(...)
    
    .. method:: Exit(reason)
    
    .. method:: ForceAllyNo(userName, teamNo)
    
    .. method:: ForceJoinBattle(userName, destinationBattleId, destinationBattlePassword)
    
    .. method:: ForceLeaveChannel(chanName, userName, reason)
    
    .. method:: ForceSpectatorMode(userName)
    
    .. method:: ForceTeamColor(userName, color)
    
    .. method:: ForceTeamNo(userName, teamNo)
    
    .. method:: GetInGameTime()
    
    .. method:: Handicap(userName, value)
    
    .. method:: Join(chanName, key)
    
    .. method:: JoinBattle(battleID, password, scriptPassword)
    
    .. method:: JoinBattleAccept(userName)
    
    .. method:: JoinBattleDeny(userName, reason)
    
    .. method:: KickFromBattle(userName)
    
    .. method:: Leave(chanName)
    
    .. method:: LeaveBattle()
    
    .. method:: ListCompFlags()
    
    .. method:: Login(user, password, cpu, localIP)
    
    .. method:: MuteList(chanName)
    
    .. method:: MyBattleStatus(battleStatus, myTeamColor)
    
    .. method:: MyStatus(status)
    
    .. method:: OpenBattle(type, natType, password, port, maxPlayers, gameHash, rank, mapHash, engineName, engineVersion, map, title, gameName)
    
    .. method:: Ping()
    
    .. method:: RecoverAccount(email, userName)
    
    .. method:: Register(userName, password, email)
    
    .. method:: RemoveBot(name)
    
    .. method:: RemoveScriptTags(...)
    
    .. method:: RemoveStartRect(allyNo)
    
    .. method:: RenameAccount(newUsername)
    
    .. method:: Ring(userName)
    
    .. method:: Say(chanName, message)
    
    .. method:: SayBattle(message)
    
    .. method:: SayBattleEx(message)
    
    .. method:: SayData(chanName, message)
    
    .. method:: SayDataBattle(message)
    
    .. method:: SayDataPrivate(userName, message)
    
    .. method:: SayEx(chanName, message)
    
    .. method:: SayPrivate(userName, message)
    
    .. method:: Script(line)
    
    .. method:: ScriptEnd()
    
    .. method:: ScriptStart()
    
    .. method:: SetScriptTags(...)
    
    .. method:: TestLogin(userName, password)
    
    .. method:: UpdateBattleInfo(spectatorCount, locked, mapHash, mapName)
    
    .. method:: UpdateBot(name, battleStatus, teamColor)
