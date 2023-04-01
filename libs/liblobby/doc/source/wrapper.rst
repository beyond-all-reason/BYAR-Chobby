.. _wrapper:

Wrapper
=======

.. class:: Wrapper
   
    extends :ref:`interface`

    Provides a wrapper around the lobby interface.

    .. method:: GetUserCount() -> int
        
        Online user count.

    .. method:: GetUser(userName : string) -> user

        Returns user by userName. Values present: *userName*, *country*, *cpu*, *accountId*

    .. method:: GetUsers() -> users
        
        All online users.

    .. method:: GetBattleCount() -> int

        Available battles count.

    .. method:: GetBattle(battleName : string) -> battle

        Return battle by battleName. Values present: *battleID*, *type*, *natType*, *port*, *maxPlayers*, *passworded*, *engineName*, *engineVersion*, *map*, *title*, *gameName*, *users*

    .. method:: GetBattles() -> battles

        All available battles.

    .. method:: GetLatency() -> int

        Returns the current latency in milliseconds.
