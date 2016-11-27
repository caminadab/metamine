#!/bin/sh



# webserver
socat TCP4-LISTEN:10101,fork EXEC:/web.lua || nc -lk -p 10101 -e ./web.lua

