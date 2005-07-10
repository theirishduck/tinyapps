#!/bin/sh

# Displays the CPU load
# $Id: cpuload.sh,v 1.3 2005/07/10 23:05:51 mina86 Exp $
# By Michal Nazareicz (mn86/AT/o2.pl)
# Released to Public Domain


while true; do
	head -n 1 /proc/stat
	sleep 1 || exit
done | while true; do
	read IGNORE A B C D IGNORE2
	read IGNORE A B C D IGNORE2 <<<"`cat /proc/stat`"
	LOAD=$(( $A + $B + $C ))
	TOTAL=$(( $LOAD + $D ))

	if [ -z "$OTOTAL" -o $TOTAL == "$OTOTAL" ]; then CPULOAD=0; else
		CPULOAD=$((100 * ($LOAD-$OLOAD) / ($TOTAL-$OTOTAL)))
	fi

	printf " %3d%%\r" $CPULOAD

	OTOTAL=$TOTAL
	OLOAD=$LOAD
	sleep 1
done
