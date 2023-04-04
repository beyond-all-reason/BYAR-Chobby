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

---------------------------------------------------------------------------------------------
--[[
  quickTour Program for Lua Class System
    Copyright (C) 2012.
  Written by Roland Yonaba - E-mail: roland[dot]yonaba[at]gmail[dot]com
--]]
----------------------------------------------------------------------------------------------

local Topics = {
'Loading LCS',
'Creating Classes',
'Library-defined Functions For Classes',
'Instantiation',
'Adding Methods To Classes',
'Single Inheritance',
'Library-defined Functions For Inheritance relationships',
'End'
}

local samples = {
[Topics[1]] =
[[
-- Copy 'LCS.lua' file inside your project folder
-- Use require to have LCS library loaded

LCS = require 'LCS']],

[Topics[2]] =
[[
-- Creating a simple class called Account
-- we can add members to this class
Account = LCS.class {balance = 100, owner = 'Boss'}
print(Account.balance,Account.owner)]],

[Topics[3]] =
[[
-- You can check if a var is a class is_A function
print('is Account a class ? ',LCS.is_A(Account))
print('is Account a class ? ',LCS.is_A(Account,'class'))
]],

[Topics[4]] =
[[
-- Objects can be created the easy way, by calling the class, or using the new operator.
print('\nwe create two accounts')
myAccount = Account()
yourAccount = Account:new()

-- Objects share common properties with their mother class while being different one from another
-- We can act on each object properties
print('setting myAccount balance to 45')
myAccount.balance = 45
print('setting yourAccount owner name to \'You\'')
yourAccount.owner = 'You'
print('myAccount','balance '..myAccount.balance,'owner '..myAccount.owner)
print('yourAccount','balance '..yourAccount.balance,'owner '..yourAccount.owner)

-- Objects can also be instantiated and customized at the same time by calling the class itself, though a special method name init.
print( '\nLet\'s reset new objects')
print('setting myAccount with balance of 250 and owner name \'Roland\'')

function Account:init(balance,owner)
self.balance = balance
self.owner = owner
end
myAccount = Account (250,'Roland')
print('setting \'yourAccount\' with balance of 150')
yourAccount = Account:new(150)
print('myAccount','balance '..myAccount.balance,'owner '..myAccount.owner)
print('yourAccount','balance '..yourAccount.balance,'owner '..yourAccount.owner)

-- We can check if 'object' is an instance using is_A
print('\nis myAccount an instance ?',LCS.is_A(myAccount))
print('\nis myAccount an instance ?',LCS.is_A(yourAccount,'object'))

-- We can check if 'object' is an instance of 'class' using is_A()
print('is myAccount an instance of class Account ?',myAccount:is_A(Account))

-- We can also call getClass() default method to return the class from which an object was instantiated
print('is myAccount an instance of class Account ?',myAccount:getClass() == Account )

-- A class can be abstract.
print('\nWe set a new abstractAccount class')
abstractAccount = LCS.class.abstract{ owner = 'staticMe', balance = 500}

print('Now, trying to instantiate from abstractAccount will throw an error!')
print('ERROR when executing "myAccount = abstractAccount()" : ',select(2,pcall(abstractAccount)))


]],

--
[Topics[5]] =
[[
--Let's redefine the Account class
print('We create a class named Account')
Account = LCS.class {balance = 100,owner = 'Noone'}

-- Let's add a new members to the class Account.
print('we add a member \'maximum_balance\' to this class')
Account.maximum_balance = 500

-- Let's add methods to the class account
print('Adding method withdraw() to Account class')
function Account:withdraw(s)
    if self.balance >= s then
  self.balance = self.balance - s
  else
  print('[WARNING] : It remains only '..self.balance..', you moron! You cannot withdraw '..s)
  end
end

print('Adding method deposit() to Account class')
function Account:deposit(s)
    if self.balance + s <= self.maximum_balance then
  self.balance = self.balance + s
  else
  print('[WARNING] : Your account balance is currently '..self.balance..' and is limited to '..self.maximum_balance)
  end
end

print('we create Account with default balance of 100')
myAccount = Account()
print('Let\'s try to withdraw 200, more than the balance!')
myAccount:withdraw(200)
print('Let\'s try to make a huge deposit or 1000!')
myAccount:deposit(1000)
print('Now we make a reasonable deposit of 100')
myAccount:deposit(100)
print('current balance is',myAccount.balance)
print('Now we make a reasonable withdraw of 5')
myAccount:withdraw(5)
print('current balance is',myAccount.balance)
]],

[Topics[6]]=
[[
-- First, remember our previous class Account has methods withdraw() and deposit()
-- We have defined them so that it is not possible to withdraw more than the account balance
-- or deposit more than an authorized maximum_deposit.

-- Now let's create a new class called vipAccount.
-- This class will inherit from Account

VipAccount = Account:extends()
print('vipAccount','balance '..VipAccount.balance,'owner '..VipAccount.owner,'maximum balance '..VipAccount.maximum_balance)
print('we create an instance of vipAccount')
myVipAccount = VipAccount()

-- The subclass vipAccount can use its superclass Account methods
print('myVipAccount current balance is',myVipAccount.balance)
print('making a deposit in a vipAccount')
myVipAccount:deposit(100)
print('myVipAccount current balance is',myVipAccount.balance)

-- We can even redefine superclass methods in a subclass
print('now we redefine deposit() method in VipAccount class so that a VipAccount can hold more money than the maximum_balance')

function VipAccount:deposit(s)
  self.balance = self.balance + s
end
print('Let\'s try to make a huge deposit of 1000!')
myVipAccount:deposit(1000)
print('myVipAccount current balance is',myVipAccount.balance,' the maximum balance is still ',myVipAccount.maximum_balance,'and I don\'t care!')

-- Now, the awesome stuff, we can still call the original deposit() method in the superclass Account
print('Calling the original deposit() method in the superclass from the subclass to make a deposit of 1 in the vipAccount')
myVipAccount:super('deposit',1)

]],

[Topics[7]] =
[[
-- We have seen previously that all classes are granted default methods
-- Some lets you identity subclass/superclass relationships between classes.

print('is VipAccount a subclass of class Account ?',VipAccount:getClass() == Account)
print('is Account a superclass of class VipAccount ?',(Account:getSubClasses())[VipAccount])

-- We can get the whole list of subclasses of a class
print('\nList of subclasses of Account')
local l = Account:getSubClasses()
for k,v in pairs(l) do
print(k,v)
end

-- We can create final classes.
-- A final class is a class from which derivation is not possible.
print('\nWe create a new  finalVipAccount class')
finalVipAccount = LCS.class.final()
print('Now trying to make a new class inherit from finalVipAccount will throw an error')
print('ERROR when executing "vipAccountNew = (finalVipAccount:extends())" : ',select(2,pcall(finalVipAccount.extends,finalVipAccount)))

]],

[Topics[8]] =
[[
  print('\n The quick tour is complete!\n Now, enjoy using LCS.\nFeel free to report any comment/bugs/suggestions at :\n roland[dot]yonaba[at]gmail[dot]com')
]]

}


for i,topic in ipairs(Topics) do
  local sample = samples[topic]
  if os.getenv('os') then os.execute('cls') end
  print('=== Topic : '..topic..' ===\n')
    if topic~='End' then
      print(sample)
      print('\n=== Output === \n')
    end

  local exec,failed = pcall(loadstring(sample))
  if not exec then
    output = ''
    print('\n Failed to run a sample.\nPlease report the following error to the author.\n')
    print(failed)
  end

  print('\nPress Enter to run the next sample')
  io.read()
end

