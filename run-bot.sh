#!/bin/bash

_dir=/home/sgarcia/.local/gmbros.net/viktortrasto/src
docker run --rm -v ${_dir}:/opt/bot viktortrasto/twurl:latest /bin/bash -c /opt/bot/bot.sh &>> ${_dir}/../bot.log
