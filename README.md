# Usage

1. If the `nginx.conf` file is present, remove it (minding your local changes).
1. Add `127.0.0.1	argu.dev` to your hosts file
1. Add `::1		argu.dev` to your hosts file
1. Add `127.0.0.1	beta.argu.dev` to your hosts file
1. Add `::1		beta.argu.dev` to your hosts file
1. Run `$ ./setup.sh`
1. If you run into a `sed: 1: "s/{your_local_ip}/10.0. ...": unescaped newline inside substitute pattern` error, try to manually add your local IP address to `setup.sh`.
