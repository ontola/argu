# Usage

1. Add `127.0.0.1   beta.argu.local` to your hosts file
1. Add `127.0.0.1   argu.local` to your hosts file
1. If the `ngingx.conf` file is present, remove it.
1. Run `$ ./setup.sh`.
1. If you run into a `sed: 1: "s/{your_local_ip}/10.0. ...": unescaped newline inside substitute pattern` error, try to manually add your local IP address to `setup.sh`.
1. Run `$ ./run.sh`
