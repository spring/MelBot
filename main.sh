#!/bin/sh
while lua main.lua; do
	echo 'restarting...'
	sleep 1
done
