#!/bin/bash

cat << EOT > /home/ec2-user/.bashrc.d/banner.bash
if [ "\$TERM_PROGRAM" = "vscode" ]; then
    if [ ! -f ~/.banner ]; then
        touch ~/.banner

        if [ -f /home/ec2-user/.banner-text ]; then
            cat /home/ec2-user/.banner-text
        fi
    fi
fi
EOT