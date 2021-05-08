#!/bin/bash
BASENAME=`basename $0 .sh`
LOGFILE=$HOME/TEST/$BASENAME.txt
TMPFILE=$HOME/TEST/$BASENAME.tmp
TMP2FILE=$HOME/TEST/$BASENAME.tmp2
PROCESSOR=`uname -p`
DIRSYSBIN=/usr/bin
DIRBIN=$HOME/bin


OUTDIR=$HOME/Desktop
if [ ! -d $OUTDIR ]; then
    mkdir -p $OUTDIR
fi

OUTFILE=$OUTDIR/'ID'

rm -f $TMPFILE $TMP2FILE $LOGFILE $LOGFILE.* $OUTFILE.*

SERVERS='4484 2278 4275 26129'

function log {
    echo `date +'%Y-%m-%d %H:%M:%S %Z'` $1 | tee -a $LOGFILE
}

function round() {
    local df=3
    retval=`echo "scale=3; $1 / 1" | bc -l`
}

case "$PROCESSOR" in
    armv7l) INTF=wlan0
            ;;
    *)      INTF=en000rtk
            ;;
esac

for ID in $SERVERS; do
    log 'Start measurements for a server with an identifier '$ID

    $DIRBIN/speedtest --accept-license --progress=no --precision=5 --format=json-pretty --server-id=$ID --interface=$INTF 2>/dev/null 1>$TMPFILE
    if [ $? -eq 0 ]; then
        PINGJIT=`cat $TMPFILE | $DIRSYSBIN/jq '.ping.jitter'`
        PINGLAT=`cat $TMPFILE | $DIRSYSBIN/jq '.ping.latency'`
        DNBANDW=`cat $TMPFILE | $DIRSYSBIN/jq '.download.bandwidth * 8 / 1000000'`
        UPBANDW=`cat $TMPFILE | $DIRSYSBIN/jq '.upload.bandwidth * 8 / 1000000'`
        DNBYTES=`cat $TMPFILE | $DIRSYSBIN/jq '.download.bytes'`
        UPBYTES=`cat $TMPFILE | $DIRSYSBIN/jq '.upload.bytes'`
        HSNAME=`cat $TMPFILE | $DIRSYSBIN/jq '.server.host'`
        HSLOCT=`cat $TMPFILE | $DIRSYSBIN/jq '.server.location'`
        PKLOSS=`cat $TMPFILE | $DIRSYSBIN/jq '.packetLoss'`
        RESURL=`cat $TMPFILE | $DIRSYSBIN/jq '.result.url'`
        log 'Server: '$HSNAME
        log 'Server-Id: '$ID
        log 'Latency: '$PINGLAT' ms'
        log 'Jitter: '$PINGJIT' ms'
        log 'Packet Loss: '$PKLOSS' %'
        log 'Download: '$DNBANDW' Mbps'
        log 'Upload: '$UPBANDW' Mbps'
        log 'Download bytes: '$DNBYTES
        log 'Upload bytes: '$UPBYTES
        log 'URL: '$RESURL
        log 'Measurements completed'
        cat $LOGFILE $TMPFILE >>$LOGFILE.$ID.txt
        $DIRSYSBIN/enscript --language=PostScript \
                            --title="Speedtest for $HSNAME" \
                            --header='[ $n ]|[ %D{%Y-%m-%d} %C ]|[ Page $% of $= ]' \
                            --font=Courier8 \
                            --output=- $LOGFILE.$ID.txt 2>/dev/null |\
        $DIRSYSBIN/ps2pdf - $OUTFILE.$ID.`date +'%Y-%m-%d.%H:%M:%S'`.pdf

        rm -f $LOGFILE.$ID.ps $LOGFILE.$ID.txt $TMPFILE $LOGFILE
    else
        log 'Error'
    fi
    log
done
rm -f $TMPFILE $TMP2FILE $LOGFILE
exit
