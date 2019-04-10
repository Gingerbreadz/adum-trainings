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

REGEX_RM_LEADING_SPACES='s/^\s\+//g'
REGEX_RM_TRAILING_SPACES='s/\s\+$//g'
REGEX_RM_EMPTY_LINES='/^$/d'
REGEX_FORMAT_KEYS='s/\(.*\S\)\s\?:$/\1:/g'

fetch_page() {
    url=$1
    outfile=$2
    cookie=$ADUM_COOKIE_FILE
    shift 2

    curl -s -b $cookie $url > $outfile
    tidy -ashtml -latin1 -q --show-warnings no -m $outfile
}

process_module() {
    mod=$1
    shift 1

    mod_id=`echo $mod | cut -d "=" -f2`
    mod_tmp_html="$TMPDIR/mod_${mod_id}.html"
    mod_tmp_file="$TMPDIR/mod_${mod_id}.txt"

    fetch_page $ADUM_URL$mod $mod_tmp_html

    xmllint --html $mod_tmp_html \
            --xpath "/html/body/div/form/div/div/div/table/tr/td//text()" \
        >> $mod_tmp_file

    sed -i $mod_tmp_file \
            -e $REGEX_RM_LEADING_SPACES \
            -e $REGEX_RM_EMPTY_LINES \
            -e $REGEX_FORMAT_KEYS
}


catalogue="$TMPDIR/catalogue.html"

fetch_page $ADUM_URL $catalogue

modules=`xmllint --html $catalogue \
                 --xpath "/html/body/div/form/div/div/div/table/tr/td/a/@href" \
       | cut -d '"' -f2`

for mod in $modules ; do process_module $mod ; done

rm -rf $TMPDIR
