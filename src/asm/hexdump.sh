#/bin/bash
hexdump -v -f hexdump-format $1 | sed s/\'/\"/g
