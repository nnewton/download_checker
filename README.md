Download_Checker 1.0
=======================

Simple script to loop through a file of paths and fetch each one from a primary server and a secondary. It will
then md5sum the two and report if they match or not. Also supports adding a delay between loops to reduce
server load, sed filtering of the results and grep filtering of the results (to remove version numbers, service names
or anything else that makes results not match, but isn't data-integral).

Usage
-----
./download_checker -p host1.example.com -s host2.example.com -f paths.txt

Where paths.txt looks as follows:

/testpath1
/testpath2/subpath
/testpath3/subpath3

Requirements
------------
Bash, curl, md5sum
