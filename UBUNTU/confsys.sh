#!/usr/bin/bash

for ROW in `<manifest`; do
    echo $ROW
    set -- $ROW
    case "${1}" in
        [cC][pP])
            cp ${2} ${3}
            chown ${4} ${3}/`basename ${2}`
            chmod ${5} ${3}/`basename ${2}`
                 ;;
        [tT][xX]
            mkdir -p ${3}
            tar zxvf ${2} --directory ${3} ${4=''}
                 ;;
    esac
done
exit

cp legacy/conf/en000rtk /etc/networkd-dispatcher/routable.d/ root:root 0555
cp legacy/conf/98-usb-lan-card-realtek.rules /etc/udev/rules.d/ root:root 0644
cp legacy/conf/jail.local /etc/fail2ban/ root:root 0644
cp legacy/conf/rules.v4 /etc/iptables/ root:root 0644
cp legacy/conf/rules.v6 /etc/iptables/ root:root 0644
tx legacy/conf/postfix.tar.gz /etc/
cp legacy/conf/root /var/spool/cron/crontabs/ root:crontab 0600
tx legacy/conf/ssh.tar.gz /home/monter/.ssh --strip-components=1
cp legacy/conf/10-ipv6-disable.conf /etc/sysctl.d/ root:root 0644
cp lecacy/conf/hosts /etc/ root:root 0644
cp legacy/bin/speedtest /usr/bin/ root:root 0555
cp legacy/conf/policy.xml /etc/ImageMagick-6/ root:root 0444
cp legacy/conf/config /etc/selinux/config root"root 0444