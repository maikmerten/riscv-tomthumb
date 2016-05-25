#/bin/bash
hexdump -v -f hexdump-format-byte $1 | sed s/\'/\"/g
printf "\n"
