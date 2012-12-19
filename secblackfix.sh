#!/bin/bash
# jason szostek 12/19/12

function geniparts {
# assumes the first line above -A INPUT is a safe place to put new drop rules
# splits iptables into 2 files, the top before INPUT rules and the rest
IFS='
'
for i in `cat /etc/sysconfig/iptables`; do
        if test -n "`echo $i|grep '\-A INPUT'`" ; then break;
        else echo $i ; fi ;
        done > /etc/sysconfig/iptables.top

T=`wc -l /etc/sysconfig/iptables.top|awk '{print $1}'`
T=`expr $T + 1`
tail -n +$T /etc/sysconfig/iptables > /etc/sysconfig/iptables.rnd
}

function gsec {
# search secure for 3 ssh related black hat clues and get their ip addresses
grep 'Invalid user recruit from' /var/log/secure|awk '{print $10}'
grep 'Invalid user' /var/log/secure|awk '{print $10}'
grep 'reverse mapping checking getaddrinfo' /var/log/secure|awk '{print $11}'|awk -F\. '{print $1}'|awk -F\- '{print $1"."$2"."$3"."$4}'
}

#MAIN PROGRAM

if test -z "`id -u|egrep ^0$`" ; then echo must be root - try again ; exit; fi
if test -z "$SSH_CLIENT" ; do echo env_keep SSH_CLIENT in sudoers and try again ; exit; fi
ME=`echo $SSH_CLIENT|awk -F\= '{print $1}'|awk '{print $1}'`
/bin/cp /etc/sysconfig/iptables /etc/sysconfig/iptables.last
/sbin/service iptables save
geniparts

cat /etc/sysconfig/iptables.top > /tmp/iptables.new

echo \# generated by secblackfix `date` >> /tmp/iptables.new

# check that all the bad guys except YOU are not already in iptables
# and put them in

for i in `gsec|sort -u|grep -v $ME` ; do
if test -z "`grep $i /etc/sysconfig/iptables`" ;
then
echo -A INPUT -s $i/255.255.255.0 -i eth0 -j DROP ;
fi;
done >> /tmp/iptables.new

cat /etc/sysconfig/iptables.rnd >> /tmp/iptables.new
cp /etc/sysconfig/iptables /etc/sysconfig/iptables.last
cp /tmp/iptables.new /etc/sysconfig/iptables

# /sbin/service iptables restart

