# reset Mac DNS

sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# test for domain

ping grafafa.test
dig @127.0.0.1 -p 10053 grafana.test
dscacheutil -q host -a name grafana.test
