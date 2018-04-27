#!/bin/bash

cat $1 | ./parse | ./solve.lua
