#!/bin/sh
while lua main.lua; do
  echo 'restarting...'
done
