Epub OPF ISBN check and fix
=========================== 

Introduction
------------
This is a utility to check the OPF file for the ISBN entry and check it matches the
filename wich should be the ISBN number. If it does not match it is corrected and
saved into the OPF. This allows proper insertion into system that need to read the
isbn from the OPF such as Adobe Content server.

Unit Testing.
-------------
As the utility runs on a single or folder of epubs validation is easily performed.


3rd Party requirements
----------------------
The Chilkatsoft Zip utility is used, as Linux and .Net versions used the same logic. If
no valid key is found a 30-day free trial will be performed.
