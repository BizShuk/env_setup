#!/bin/bash

CAT <<EOF >>~/.ssh/config
# Kerberos authentication
Host *
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials no
Host git.byted.org
    Hostname git.byted.org
    Port 29418
    User shuk.liu
Host review.byted.org
    Hostname git.byted.org
    Port 29418
    User shuk.liu
Host *.byted.org
    GSSAPIAuthentication yes
    User shuk.liu
EOF


CAT <<EOF >>~/.gitconfig
[url "gitr"]
    insteadOf = git://git.byted.org/
[credential "https://code.byted.org"]
    username = shuk.liu
[url "ssh://shuk.liu@git.byted.org:29418"]
    insteadOf = https://git.byted.org
[url "git@code.byted.org:"]
    insteadOf = https://code.byted.org/
EOF

# Check the connection
ssh -T code.byted.org