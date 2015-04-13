#!/bin/bash
# run arbitrary commands across a list of servers and see the output in real time
# usage: ./scriptname.sh [-f /path/to/server/list] [command and any arguments]

# temporary screen file used to store config
ss=$HOME/.screentemp
# server list here, can be overridden with -f
servers=( "example-server.example.com" "192.168.1.5" )

# the main function that builds the screenfile based on servers array and inputted commands and ultimately calls screen with the config file
function connect {
	# if called with -f, then disregard previously set array and use a file specified as the array
	if [ $1 == "-f" ]; then
		IFS=$'\r\n' GLOBIGNORE='*' :;
		servers=($(cat $2))
		# throw away the first two params, -f and the file
		shift 2
	fi
	# remove the temp file when the script exits
	trap "rm $ss" EXIT
	# add a line to the screen file for every server in the array and pass arguments along to it
	# the -t by the way sets the title
	for server in "${servers[@]}"; do
		cat <<EOF >> $ss
screen -t $server sh -c "ssh $server $@"
EOF
	done

	# i needs to be 2.  Don't question it.
	i=2
	# add split commands for one less than the number of servers in the array
	while [ $i -le ${#servers[@]} ]; do
		cat <<EOF >> $ss
split
focus down
other
EOF
		let i=i+1
	done
	# Q quits screen (allowing you to quit without sending the screen control command
	# K kills the current window, R restarts it (which will re-run the command)
	cat <<EOF >> $ss
bindkey "q" quit
zombie kr
EOF
	# finally, connect to the screen with the built-out config
	screen -c $ss
}

# test if script was run with no parameters
if [ -z $1 ]; then
	echo -e "runs a specified command against a given server list and displays output in separate screens"
	echo -e "usage:"
	echo -e "$0 [-f /path/to/server/list] [command and any arguments]"
else
	# connect using provided arguments with hardcoded server list
	connect $@
fi
