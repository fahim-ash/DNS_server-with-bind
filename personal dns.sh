#!usr/bin/bash

yum -y install bind bind-utils

cat > /etc/named.conf <<eof
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

options {
        listen-on port 53 { 127.0.0.1;192.168.0.104; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { any; };

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-enable yes;
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

zone "ash.com" IN {
type master;
file "forward.ash.com";
allow-update {none; };
};

zone "0.168.192.in-addr.arpa" IN {
type master;
file "reverse.ash.com";
allow-update {none; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
eof



cat > /var/named/forward.ash.com <<eof
\$TTL 1D
@       IN SOA  ash.com.                 root.ash.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       IN      NS      ash.com.
@       IN      A       192.168.0.104
ash     IN      A       192.168.0.104
host    IN      A       192.168.0.104
desktop IN      A       192.168.0.105
client  IN      A       192.168.0.105
eof

cat > /var/named/reverse.ash.com<<eof
\$TTL 1D
@       IN SOA  ash.com.                 root.ash.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       IN      NS      ash.com.
@       IN      PTR     ash.com.
@       IN      A       192.168.0.104
ash     IN      A       192.168.0.104
host    IN      A       192.168.0.104
desktop IN      A       192.168.0.105
client  IN      A       192.168.0.105
104     IN      PTR     ash.com.
105     IN      PTR     desktop.com.

eof



#start the service

systemctl start named
systemctl enable named

firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --reload



chown root:named /var/named/forward.ash.com
chown root:named /var/named/reverse.ash.com

systemctl restart named





