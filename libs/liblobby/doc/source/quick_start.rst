Quick start
===========

Preparation
-----------

Before installing the library we need to ensure we have a usable environment. First you should check if Spring settings allow for TCP connections (usually configured in *.springrc* on Linux or *springsettings.cfg* on Windows). The file should contain the following line: ``TCPAllowConnect = server:port``, which is probably going to be something like this if you want to connect to the official server: ``TCPAllowConnect = springrts.com:8200``.

Next you should check if your *system.lua* file (located in the LuaUI/ folder) contains the socket=socket line. Add it if it's not there.

Installation
------------

To use liblobby first get it from the official `repository <https://github.com/gajop/liblobby>`_ with git: ``git clone https://github.com/gajop/liblobby.git``.

Put the downloaded liblobby folder in your project's /libs folder (create it if you don't have it).

Copy the api_lobby.lua file to your LuaUI/widgets folder. On next restart of Spring you should see it available in the widget list (F11).

The library should then be available in WG.LibLobby. You can verify this by putting the following code in your widget's initialization, which should print "LibLobby is available" if everything is properly configured:

.. code-block:: lua

    function widget:Initialize()
        if not WG.LibLobby then
            widgetHandler:RemoveWidget(widget)
        else
            Spring.Echo("LibLobby is available")
        end
    end

Usage
-----

Using the library involves calling methods of the :ref:`wrapper` class, which is provided by the object lobby:

.. code-block:: lua
    
    lobby = WG.LibLobby.lobby

Usually you will first want to connect to the lobby server:

.. code-block:: lua
    
    lobby:Connect("springrts.com", "8200")

Before logging in you should probably verify that a connection has been successfully made. You can do this by adding an *OnTASServer* listener, that gets invoked when the connection is established:

.. code-block:: lua

    lobby:AddListener("OnTASServer", 
        function(listener)
            -- connection happened we can now login
            lobby:Login(username, password)
        end
    )
    lobby:Connect("springrts.com", "8200")

We can also verify if we have been connected successfully by listening to the *OnAccepted* event:

.. code-block:: lua

    lobby:AddListener("OnTASServer", 
        function(listener)
            lobby:AddListener("OnAccepted",
                function(listener)
                    -- login has been successful
                end
            )
            -- connection happened we can now login
            lobby:Login(username, password)
        end
    )
    lobby:Connect("springrts.com", "8200")

Let's say we want to handle only **one** message received event. We would do that by creating an *OnSaid* listener, similar like before:

.. code-block:: lua

    lobby:AddListener("OnSaid", 
        function(listener, chanName, userName, message)
            -- do stuff with the message
        end
    )

However, this listener would be triggered for subsequent events as well. We therefor need to unregister it. We do this by invoking the *RemoveListener* method:

.. code-block:: lua

    lobby:AddListener("OnSaid", 
        function(listener, chanName, userName, message)
            -- do stuff with the message
            lobby:RemoveListener("OnSaid", listener)
        end
    )

We pass the listener variable (which represents our listener function and is passed as a matter of convenience), as well as the event it's tied to. 
Alternatively if we want to remove a custom listener we would do this as follows:

.. code-block:: lua

    local function onPongListener = function(listener)
        Spring.Echo("Pong happened")
    end)
    lobby:AddListener("OnPong", onPongListener)

    lobby:AddListener("OnSaid", 
        function(listener, chanName, userName, message)
            lobby:RemoveListener("OnSaid", listener)
            -- this will also remove the onPongListener
            lobby:RemoveListener("OnPong", onPongListener) 
        end
    )


For detailed usage refer to the API and the `chililobby <https://github.com/gajop/chililobby>`_ project (Chili based lobby).
Further information is also available in the `lobby protocol documentation <http://springrts.com/dl/LobbyProtocol/>`_.
