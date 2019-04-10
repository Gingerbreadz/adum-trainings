#!/bin/sh

ADUM_COOKIE_FILE=cookie
ADUM_URL="https://adum.fr/phd/formation/catalogue.pl"
OUTFILE="catalogue.json"

require_file() {
    [ -f $1 ] || {
        echo "$1: file required but not found. Exiting."
        exit 1
    }
}

TMPDIR=`mktemp -d -p /tmp -t tmp.adumparser.XXXXXXXXXX` || {
    echo "Could not create temporary directory. Exiting."
    exit 1
}

require_file $ADUM_COOKIE_FILE

fetch_page() {
    url=$1
    outfile=$2
    cookie=$ADUM_COOKIE_FILE
    shift 2

    curl -s -b $cookie $url > $outfile
    tidy -ashtml -latin1 -q --show-warnings no -m $outfile
}


catalogue="$TMPDIR/catalogue.html"

fetch_page $ADUM_URL $catalogue

modules=`xmllint --html $catalogue \
                 --xpath "/html/body/div/form/div/div/div/table/tr/td/a/@href" \
       | cut -d '"' -f2`

for mod in $modules ; do echo $ADUM_URL$mod >> $OUTFILE ; done

rm -rf $TMPDIR
