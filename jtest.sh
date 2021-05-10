#!/bin/bash
BASENAME=`basename $0 .sh`
LOGFILE=$HOME/TEST/$BASENAME.txt
TMPFILE=$HOME/TEST/$BASENAME.tmp
TMP2FILE=$HOME/TEST/$BASENAME.tmp2
PROCESSOR=`uname -p`
DIRSYSBIN=/usr/bin
DIRBIN=$HOME/bin


OUTDIR=$HOME/Desktop
[ ! -d $OUTDIR ] && mkdir -p $OUTDIR

OUTFILE=$OUTDIR/'ID'

rm -f $TMPFILE $TMP2FILE $LOGFILE $LOGFILE.* $OUTFILE.*

SERVERS='4484 2278 4275 26129'

function log {
    echo `date +'%Y-%m-%d %H:%M:%S %Z'` $1 | tee -a $LOGFILE
}

case "$PROCESSOR" in
    armv7l)
            INTF=wlan0
            MAILATT='-a '
            MAILSUBJ='-s '
            ;;
    *)
            INTF=en000rtk
            MAILATT='--attach='
            MAILSUBJ='--subject='
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
        log 'Make PDF'
        cat $LOGFILE $TMPFILE >>$LOGFILE.$ID.txt
        $DIRSYSBIN/enscript --language=PostScript \
                            --title="Speedtest for $HSNAME" \
                            --header='[ $n ]|[ %D{%Y-%m-%d} %C ]|[ Page $% of $= ]' \
                            --font=Courier8 \
                            --output=- $LOGFILE.$ID.txt 2>/dev/null |\
        $DIRSYSBIN/ps2pdf - $OUTFILE.$ID.`date +'%Y-%m-%d.%H:%M:%S'`.pdf

        rm -f $LOGFILE.$ID.ps $LOGFILE.$ID.txt $TMPFILE $LOGFILE 2>/dev/null
    else
        log 'Error'
    fi
    log
done
rm -f $TMPFILE $TMP2FILE $LOGFILE

RECEIVER=`head -q -n1 $OUTDIR/E-mail.txt 2>/dev/null| grep -E -e'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$'`
if [ -z "$RECEIVER" ]; then
    log "Error. E-mail.txt is empty or e-mail incorrect"
    exit 0
fi

[ `$DIRSYSBIN/find $OUTDIR -name *.pdf -print | wc -l` -gt 0 ] || exit 0
ATTLIST=''
for ID in `$DIRSYSBIN/find $OUTDIR -name *.pdf -print`; do
    if [ `$DIRSYSBIN/head -n1 -q $ID` != "%PDF-1.4" ]; then
        log "Error in PDF: "$ID
        rm -f $ID 2>/dev/null
        continue
    fi
    ATTLIST=$MAILATT$ID' '$ATTLIST
done
[ -n "$ATTLIST" ] || exit 0
log "Sent e-mail to "$RECEIVER
TIMESTAMP=`date +'%Y-%m-%d %H:%M:%S %Z'`
echo "Only for Technical Support. Don't distribute this files" | \
     mailx $ATTLIST $MAILSUBJ"Speedtest measurements at $TIMESTAMP" $RECEIVER 2>/dev/null
exit

