#!/bin/env bash

usage() {
  echo "usage: $0 -p <hostname 1> -s <hostname 2> -f <file of paths>"
  echo "    -p The primary hostname to compare against"
  echo "    -s The secondary hostname to compare against the primary"
  echo "    -f  A file containing paths to check (newline separated)"
  echo ""
  exit 1
}

while getopts "p:s:f:" opt; do
  case $opt in
    p)
      HOST_ONE=$OPTARG
      ;;
    s)
      HOST_TWO=$OPTARG
      ;;
    f)
      PATH_FILE=$OPTARG
      ;;
    *)
      usage
  esac
done

if [ -z "${HOST_ONE}" ]
then
  usage
fi

if [ -z "${HOST_TWO}" ]
then
  usage
fi

if [ -z "${PATH_FILE}" ]
then
  usage
fi


TMPDIR="/tmp"
IFS=$'\n'

for TEST_PATH in `cat $PATH_FILE`; do
  curl -k -L "${HOST_ONE}${TEST_PATH}" -o "${TMPDIR}/host1_test" 2>/dev/null
  curl -k -L "${HOST_TWO}${TEST_PATH}" -o "${TMPDIR}/host2_test" 2>/dev/null
  MD5_HOST1=`md5sum ${TMPDIR}/host1_test | awk ' { print $1 } '` 
  MD5_HOST2=`md5sum ${TMPDIR}/host2_test | awk ' { print $1 }'`
  if [ "${MD5_HOST1}" == "${MD5_HOST2}" ]; then
    echo "MD5 Match for path $_TEST_PATH"
  else
    echo "MD5 Failure for path $TEST_PATH: Host $HOST_ONE $MD5_HOST1, $HOST_TWO $MD5_HOST2"
  fi
done

if [ -f $TMPDIR/host1_test ]; then
  rm $TMPDIR/host1_test
fi

if [ -f $TMPDIR/host2_test ]; then
  rm $TMPDIR/host2_test
fi
