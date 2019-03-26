#!/bin/env bash

usage() {
  echo "usage: $0 -p <hostname 1> -s <hostname 2> -f <file of paths> [-d <Delay between fetches> -x <Sed Filter> -i <Grep Filter> -v]"
  echo "    -p The primary hostname to compare against"
  echo "    -s The secondary hostname to compare against the primary"
  echo "    -f  A file containing paths to check (newline separated)"
  echo "    -d  Delay between fetches to reduce load on services"
  echo "    -x  Sed filter to run responses through before comparison (excluding content)"
  echo "    -i  Grep filter to run responses through before comparison (including content)"
  echo "    -v  Verbose output of both filtered results"
  echo ""
  exit 1
}

VERBOSE=0

while getopts "p:s:f:d:x:i:v" opt; do
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
    d)
      DELAY=$OPTARG
      ;;
    x)
      SED_FILTER=$OPTARG
      ;;
    i)
      GREP_FILTER=$OPTARG
      ;;
    v)
      VERBOSE=1
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

  SED_CMD="tee"
  GREP_CMD="tee"

  if [ -n "${SED_FILTER}" ]; then
    SED_CMD="sed -r '${SED_FILTER}'"
  fi

  if [ -n "${GREP_FILTER}" ]; then
    GREP_CMD="grep -Eo '${GREP_FILTER}'"
  fi

  eval "cat ${TMPDIR}/host1_test | ${SED_CMD} | ${GREP_CMD}" > ${TMPDIR}/host1_test_filt
  eval "cat ${TMPDIR}/host2_test | ${SED_CMD} | ${GREP_CMD}" > ${TMPDIR}/host2_test_filt

  if [ $VERBOSE -eq 1 ]; then
    cat ${TMPDIR}/host1_test_filt
    echo "---"
    cat ${TMPDIR}/host2_test_filt
  fi

  MD5_HOST1=`md5sum ${TMPDIR}/host1_test_filt | awk ' { print $1 }'`
  MD5_HOST2=`md5sum ${TMPDIR}/host2_test_filt | awk ' { print $1 }'`

  if [ "${MD5_HOST1}" == "${MD5_HOST2}" ]; then
    echo "MD5 Match for path ${TEST_PATH}"
  else
    echo "MD5 Failure for path ${TEST_PATH}: Host ${HOST_ONE} ${MD5_HOST1}, ${HOST_TWO} ${MD5_HOST2}"
  fi

  if [ -n "${DELAY}" ]; then
    sleep ${DELAY}
  fi
done

if [ -f $TMPDIR/host1_test ]; then
  rm $TMPDIR/host1_test
  rm $TMPDIR/host1_test_filt
fi

if [ -f $TMPDIR/host2_test ]; then
  rm $TMPDIR/host2_test
  rm $TMPDIR/host2_test_filt
fi
