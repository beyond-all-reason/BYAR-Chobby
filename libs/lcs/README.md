#LCS : Lua Class System#
*Lua Class System* (LCS) is a small library which offers a clean, minimalistic but powerful API for (Pseudo) Object Oriented programming style using Lua.
LCS is light-weight, abstract thus can fit in every project where OOP mechanisms are needed.
 
  
##Usage##
Add [LCS.lua](https://github.com/Yonaba/Lua-Class-System/blob/master/LCS.lua) file inside your project.<br/>
Call it using __require__ function.</br>
It will return a table containing a set of functions.
	
##Full API Overview##
* __LCS.class(args)__  : Creates a class
* __LCS.class.final(args)__  : Creates a final class.
* __LCS.class.abstract(args)__  : Creates a static class.
* __LCS.is_A(thing,kind)__  : Checks the nature of the given argument 'thing'.
* __class(args)__ : Default class constructor used for instantiation.
* __class:new(args)__ : Same as class(args)__
* __class:extends(args)__ : Returns a new class derived from class class.
* __class:getClass()__ : Returns a reference to the superclass of class class 
* __class:getSubClasses()__ : Returns a list of all classes deriving from class class 
* __class:super(method,...)__ : Calls a method defined in a parent of class class
* __instance:getClass()__ : Returns a reference to the class from which 'instance' was created
* __instance:is_A(aClass)__ : Checks if instance instance was instantiated from a specific class.
* __instance:super(method,...)__ : Calls a methods defined in a parent of a class from which object 'instance' was created

##Printing classes and objects
As of [v1.2](https://github.com/Yonaba/Lua-Class-System/blob/master/version_history.md), a light feature have been added.<br/>
Any attempt to [print](http://pgl.yoyo.org/luai/i/print) or [tostring](http://pgl.yoyo.org/luai/i/tostring) a class/instance will return a custom string, 
as shown in the following:

```lua
local LCS = require 'LCS'
-- A Cat Class
local Cat = LCS.class({name = 'Animal'})
-- Init
function Cat:init(name)
  self.name = name
end

print(Cat) --> "class: <table: 0058C4C0>"

local kitten = Cat('kitty')
print(kitten) --> "object: <table: 0058C628>"
````

Yet, this behaviour can still be easily overriden if you want to provide your own output.
Just attach a method named <tt>describe</tt> to the class.

```lua
local LCS = require 'LCS'
-- A Cat Class
local Cat = LCS.class({name = 'Animal'})
-- Init
function Cat:init(name)
  self.name = name
end

print(Cat) --> "class: <table: 0058C4C0>"

local kitten = Cat('kitty')
print(kitten) --> "object: <table: 0058C628>"

-- Now providing a describe method to have our own output
function Cat:describe()
  return self.name
end

print(Cat) --> "Animal"
print(kitten) --> "kitty""
````

__Note__: <tt>describe</tt> method can be passed a variable number of arguments.

##Documentation##
* Full Documentation is available, with example snippets: [Documentation][].
* Find some tests here: [Tests.lua][]
* Find a quicktour here: [quickTour.lua][]
* Documentation generated with [LuaDoc][].

		
##License##
This work is under [zLIB License][]<br/>
Copyright (c) 2012 Roland Yonaba

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.

[Documentation]: https://github.com/Yonaba/Lua-Class-System/tree/master/docs
[Tests.lua]: https://github.com/Yonaba/Lua-Class-System/blob/master/tests.lua
[quickTour.lua]: https://github.com/Yonaba/Lua-Class-System/blob/master/quickTour.lua
[LuaDoc]: http://keplerproject.github.com/luadoc/
[zLIB License]: http://www.opensource.org/licenses/zlib-license.php

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Yonaba/lua-class-system/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

