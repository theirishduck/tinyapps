#!/bin/sh
##
## Test for tpwd script
## Copyright (c) 2014 by Michal Nazareicz (mina86/AT/mina86.com)
##
## This software is OSI Certified Open Source Software.
## OSI Certified is a certification mark of the Open Source Initiative.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##
## This is part of Tiny Applications Collection
##   -> http://tinyapps.sourceforge.net/
##

set -eu


run_test() {
	run() {
		printf "$ %s\n<" "$*"
		ec=0
		HOME=$home "$@" || ec=$?
		printf '> %d\n' $ec
	}

	for lp in '' -L -P; do
		for n in '' -n; do
			run "$1" $lp $n
			run "$1" $lp $n 5
			run "$1" $lp $n 5 '{'
			run "$1" $lp $n 5 ... 1
			run "$1" $lp $n 5 '' 1
		done
	done
}

case ${1:-} in --run-test)
	home=$PWD
	cd foobar/qux
	run_test "$2"
	exit 0
esac


if [ $# -eq 0 ]; then
	for sh in /bin/ash /bin/bash /bin/dash /bin/ksh /bin/ksh93 \
		  /bin/sh /bin/zsh /usr/bin/zsh
	do
		if [ -x "$sh" ]; then
			set -- "$@" "$sh"
		fi
	done
	if [ $# -eq 0 ]; then
		echo 'No shells found, pass one as command line' >&2
		exit 2
	fi
fi


self="$PWD/tpwd-test.sh"
tpwd="$PWD/tpwd"
if ! [ -x "$self" ] || ! [ -x "$tpwd" ]; then
	echo "Expected $self and $tpwd to be executable." >&2
	exit 2
fi

temp=$(mktemp -d || exit 2)
trap 'rm -r "$temp"' 0

mkdir "$temp/foobar" "$temp/foobar/baz"
cd "$temp/foobar"
ln -s baz qux
cd "$temp"

cat >$temp/expected <<EOF
$ /home/mpn/code/tinyapps/tpwd
<~/foobar/qux
> 0
$ /home/mpn/code/tinyapps/tpwd 5
<...ux
> 0
$ /home/mpn/code/tinyapps/tpwd 5 {
<{/qux
> 0
$ /home/mpn/code/tinyapps/tpwd 5 ... 1
<.../qux
> 0
$ /home/mpn/code/tinyapps/tpwd 5  1
</qux
> 0
$ /home/mpn/code/tinyapps/tpwd -n
<~/foobar/qux> 0
$ /home/mpn/code/tinyapps/tpwd -n 5
<...ux> 0
$ /home/mpn/code/tinyapps/tpwd -n 5 {
<{/qux> 0
$ /home/mpn/code/tinyapps/tpwd -n 5 ... 1
<.../qux> 0
$ /home/mpn/code/tinyapps/tpwd -n 5  1
</qux> 0
$ /home/mpn/code/tinyapps/tpwd -L
<~/foobar/qux
> 0
$ /home/mpn/code/tinyapps/tpwd -L 5
<...ux
> 0
$ /home/mpn/code/tinyapps/tpwd -L 5 {
<{/qux
> 0
$ /home/mpn/code/tinyapps/tpwd -L 5 ... 1
<.../qux
> 0
$ /home/mpn/code/tinyapps/tpwd -L 5  1
</qux
> 0
$ /home/mpn/code/tinyapps/tpwd -L -n
<~/foobar/qux> 0
$ /home/mpn/code/tinyapps/tpwd -L -n 5
<...ux> 0
$ /home/mpn/code/tinyapps/tpwd -L -n 5 {
<{/qux> 0
$ /home/mpn/code/tinyapps/tpwd -L -n 5 ... 1
<.../qux> 0
$ /home/mpn/code/tinyapps/tpwd -L -n 5  1
</qux> 0
$ /home/mpn/code/tinyapps/tpwd -P
<~/foobar/baz
> 0
$ /home/mpn/code/tinyapps/tpwd -P 5
<...az
> 0
$ /home/mpn/code/tinyapps/tpwd -P 5 {
<{/baz
> 0
$ /home/mpn/code/tinyapps/tpwd -P 5 ... 1
<.../baz
> 0
$ /home/mpn/code/tinyapps/tpwd -P 5  1
</baz
> 0
$ /home/mpn/code/tinyapps/tpwd -P -n
<~/foobar/baz> 0
$ /home/mpn/code/tinyapps/tpwd -P -n 5
<...az> 0
$ /home/mpn/code/tinyapps/tpwd -P -n 5 {
<{/baz> 0
$ /home/mpn/code/tinyapps/tpwd -P -n 5 ... 1
<.../baz> 0
$ /home/mpn/code/tinyapps/tpwd -P -n 5  1
</baz> 0
EOF


line() {
	tput setf 0; tput bold
	echo '---------- >8 --------------------------------------------------'
	tput sgr 0
}

assert() {
	__ec=0
	"$sh" "$self" --run-test "$tpwd" >got-${sh##*/} 2>&1 || __ec=$?
	if [ $__ec -ne 0 ]; then
		tput setf 4; tput bold; echo "FAILED; exit code: $__ec:"
		line; cat "got-${sh##*/}"; line
		ec=1
	elif ! cmp -s "expected" "got-${sh##*/}"; then
		tput setf 4; tput bold; echo 'FAILED; got difference:'
		line; diff -u "expected" "got-${sh##*/}"; line
		ec=1
	fi
}

ec=0
for sh; do
	tput setaf 2
	echo "> Testing $sh"
	tput sgr 0
	assert
done
exit $ec