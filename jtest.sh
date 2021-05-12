#!/bin/bash

function log {
    echo `date +'%Y-%m-%d %H:%M:%S %Z'` $1
}

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROCESSOR=`uname -p`
DIRSYSBIN=/usr/bin
DIRBIN=$HOME/bin
FONTSIZE=11

OUTDIR=$HOME/Desktop
[ ! -d $OUTDIR ] && mkdir -p $OUTDIR

OUTFILE=$OUTDIR/'ID'

log "Delete old PDF files in "$OUTDIR
rm -f $OUTDIR/*.[pP][dD][fF]

SERVERS='4484 2278 4275 26129'

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

    RESSPEED=`$DIRBIN/speedtest --accept-license --progress=no --precision=5 --format=json --server-id=$ID --interface=$INTF 2>/dev/null`
    if [ $? -eq 0 ]; then
	TMPRES=`echo $RESSPEED | $DIRSYSBIN/jq --raw-output ".server.host, .server.location, .ping.latency, .ping.jitter, .packetLoss, .download.bandwidth*8/1000000, .upload.bandwidth*8/1000000, .download.bytes, .upload.bytes, .result.url" 2>/dev/null`
	set -- $TMPRES
	OUTRES=''
	OUTRES=$OUTRES'@color{1 0 1}Server-Id:   @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'$ID'@font{default}\n'
	OUTRES=$OUTRES'@color{1 0 1}Server:      @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${1}' ('${2}')@font{default}\n'
#	OUTRES=$OUTRES'@color{1 0 1}Location:    @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${2}'@font{default}\n'
        OUTRES=$OUTRES'@color{1 0 1}Latency:     @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${3}'@font{default} ms\n'
        OUTRES=$OUTRES'@color{1 0 1}Jitter:      @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${4}'@font{default} ms\n'
        OUTRES=$OUTRES'@color{1 0 1}Packet Loss: @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${5}'@font{default} %\n'
        OUTRES=$OUTRES'@color{1 0 0}Download / Upload:    @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${6}' / '${7}'@font{default} Mbps\n'
#        OUTRES=$OUTRES'@color{1 0 0}Upload:      @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${7}'@font{default} Mbps\n'
#        OUTRES=$OUTRES'@color{1 0 1}Download bytes: @color{0 0 0}'${8}'\n'
#        OUTRES=$OUTRES'@color{1 0 1}Upload bytes:   @color{0 0 0}'${9}'\n'
        OUTRES=$OUTRES'@color{1 0 1}URL:         @color{0 0 0}@font{Courier-Bold'$FONTSIZE'}'${10}'@font{default}\n\n'
	OUTRES=$OUTRES'@color{0 0 1}'
	OUTRES=$OUTRES$( echo $RESSPEED | $DIRSYSBIN/jq | $DIRSYSBIN/awk 'BEGIN{ORS="\\n"} {print $0}' )
	OUTRES=$OUTRES'@color{0 0 0}'
        log 'Measurements completed'
        log 'Make PDF'
	echo -e $OUTRES | \
            $DIRSYSBIN/enscript --language=PostScript \
	                        --escapes=@ \
                                --title="Speedtest for $HSNAME" \
                                --header='[ $n ]|[ %D{%Y-%m-%d} %C ]|[ Page $% of $= ]' \
                                --font=Courier$FONTSIZE \
                                --output=- 2>/dev/null |\
            $DIRSYSBIN/ps2pdf - $OUTFILE.$ID.`date +'%Y-%m-%d.%H:%M:%S'`.pdf
    else
        log 'Error'
    fi
done

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

