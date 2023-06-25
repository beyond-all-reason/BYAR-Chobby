# chotify
Chotify: Chili Notification library for Spring

Dependencies:
- LCS: https://github.com/gajop/chiliui
- ChiliUI: https://github.com/gajop/chiliui
- ChiliFX: https://github.com/gajop/chilifx

Usage:

```lua
Chotify = WG.Chotify  -- do this only once in your project

-- Send notifications
local notificationId = Chotify:Post({
    title = title -- title of the notification
    body = body -- text of the notification
    icon = icon -- optional image
    time = time -- how long should it be displayed (optional, default is 5)
})


-- Disable the library: the Post calls will be ignored.
Chotify:Disable()

-- Enable the library again
Chotify:Enable() 

-- Check if it's enabled
Chotify:IsEnabled() 

-- Update 
Chotify:Update(id, { -- id of the notification
    title = title -- title of the notification
    body = body -- text of the notification
})
```