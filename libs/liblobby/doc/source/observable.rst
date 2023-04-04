.. _observable:

Observable
==========

.. class:: Observable

    Used to register lobby event listeners.

    .. method:: AddListener(event : string, listener : function)

        Adds a *listener* function for the specified *event*. This function will be invoked when the event happens.
    
    .. method:: RemoveListener(event : string, listener : function)

        Removes an existing *listener* function for the specified *event*.
