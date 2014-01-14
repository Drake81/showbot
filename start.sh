#!/bin/sh

# create bot.config if not exists
echo "Checking Config"
if [ ! -f "bot.config" ]; then
    cp bot.config.def bot.config
    $EDITOR bot.config
fi

# check directory in config file
dire=$(cat bot.config | grep directory | perl -n -e'm~directory\s+([\w+|/]+)~;print $1');

# make logs directory
if [ ! -e "logs" ]; then
    mkdir logs;
    chmod 777 logs/;
fi

echo "\nStarting bot"
./bot.pl
