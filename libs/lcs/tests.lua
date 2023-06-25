-- Copyright (c) 2012 Roland Yonaba
--[[
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
--]]

local insert = table.insert
local require = require
local pcall = pcall
local loadstring = loadstring
local print = print


local tests = {}
local aborted =  {}
local function addTest (test)
  test.n = #tests+1
  insert(tests,test)
end

local function runTests(listOfTests,output)
  local output = output or io.stdout
  local status,err,fails
  for i,test in ipairs(listOfTests) do
    output:write(i..'/  TOPIC : '..test.topic..'\n')
    output:write('COMMENTS : '..test.comments..'\n')
    output:write('Sample Code :\n'..test.sample..'\n')
    output:write('Output\n')
    status,err = pcall(loadstring(test.sample))
      if not status then
        output:write('Error occured\n')
        insert(aborted,{test = test, error = err})
      end
    output:write('\nEnd of Test '..i..'\n\n')
  end
  fails = #aborted
  if fails > 0 then
    output:write(fails..' test'..(fails>1 and 's' or '')..' aborted..\n')
    for i in ipairs(aborted) do
      output:write('Test '..aborted[i].test.n..' : '..aborted[i].error..'\n')
    end
  else
    output:write('All tests runned successfully\n')
    output:close()
  end
end

addTest(
{
  topic = 'Class Creation',
  comments = 'We will cover various ways to create classes using LCS',
  sample = [[
    local LCS = require "LCS"
    local myClass = LCS.class()
      local myClass2 = LCS.class {var1 = 0,  var2 = nil}
    print(myClass2.var1)
    print(myClass2.var2)
    print(myClass2.var3)
    print(LCS.is_A(myClass,'class'))
    print(LCS.is_A(myClass))
  ]],
}
)

addTest(
{
  topic = 'Instantiation (1/2)',
  comments = 'We will cover differents ways to instantiate objects from a class',
  sample = [[
    local LCS = require 'LCS'
    local Animal = LCS.class {name = 'Animal'}

    function Animal:yell()
    print('I am a '..self.name)
    end

    local kitty = Animal()
    print(kitty.name)

    kitty.name = 'kitty'
    kitty:yell()

    local doggy = Animal:new()
    print(doggy.name)
    doggy.name = 'doggy'
    doggy:yell()

    ]],

}
)

addTest(
{
  topic = 'Instantiation (2/2)',
  comments = 'We will cover how to instantiante objects and init them with parameters',
  sample = [[
    local LCS = require 'LCS'
    local Animal = LCS.class {name = 'Animal', weight = nil}

    function Animal:init(name,weight)
    self.name = name
    self.weight = weight
    end

    function Animal:yell()
    print('I am a ',self.name,', I weight ',self.weight)
    end

    local kitty = Animal('kitty',10)
    local doggy = Animal:new('doggy',20)

    kitty:yell()
    doggy:yell()
    ]],

}
)

addTest(
{
  topic = 'Inheritance ',
  comments = 'We will learn how to use inheritance feature in LCS',
  sample = [[
    local LCS = require 'LCS'
    local Animal = LCS.class {name = 'Animal'}

    function Animal:init(name)
    self.name = name
    end

    function Animal:yell()
    print('I am a ',self.name)
    end

    local Cat = Animal:extends()
    local Dog = Animal:extends()

    function Cat:speak()
    print('Meeoow')
    end

    function Dog:speak()
    print('Ouah Ouah!')
    end

    local kitty = Cat('kitty')
    local doggy = Dog('Doggy')

    kitty:yell()
    doggy:yell()
    kitty:speak()
    doggy:speak()

    ]],

}
)

addTest(
{
  topic = 'Super Call ',
  comments = 'We will learn how to call methods defined within a superclass from a derived class',
  sample = [[
    local LCS = require 'LCS'
    local Animal = LCS.class {name = 'Animal'}

    function Animal:init(name)
    self.name = name
    end

    function Animal:yell()
    print('I am a ',self.name)
    end

    local Cat = Animal:extends()

    function Cat:yell()
    print('Meeoow')
    end

    local kitty = Cat('kitty')


    kitty:yell()
    kitty:super('yell')

    ]],

}
)

addTest(
{
  topic = 'Final and static classes ',
  comments = 'We will learn how to create final and static classes.\nThis test will have no output.',
  sample = [[
    local LCS = require 'LCS'
    local FinalAnimal = LCS.class.final {name = 'Animal'}
    local StaticAnimal = LCS.class.static {name = 'Animal'}

    -- This will throw an error
    -- local FinalDog = FinalAnimal:extends()

    -- This will throw an error
    -- staticKitty = StaticAnimal()


    ]],

}
)

addTest(
{
  topic = 'Full Api review ',
  comments = 'We will learn the use of the whole api functions',
  sample = [[
    local LCS = require 'LCS'
    local Animal = LCS.class {name = 'Animal'}

    function Animal:init(name)
    self.name = name
    end

    local Cat = Animal:extends()

    function Cat:yell()
    print('Meeoow')
    end

    local thing = Animal('thing')
    local kitty = Cat('kitty')

    print(kitty:getClass() == Cat)
    print(Cat:getClass() == Animal)
    print(thing:getClass() == Animal)
    print(Animal:getClass() == nil)

    print(kitty:is_A(Cat))
    print(thing:is_A(Animal))
    print(LCS.is_A(kitty,'object'))
    print(LCS.is_A(thing))
    print(LCS.is_A(Cat,'class'))
    print(LCS.is_A(Animal))

    print((Animal:getSubClasses())[Cat])


    ]],

}
)

runTests(tests)

