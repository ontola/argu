# Usage

## First time setup
1. If the `nginx.conf` file is present, remove it (minding your local changes).
1. Add `127.0.0.1	argu.dev` to your hosts file
1. Add `::1		argu.dev` to your hosts file
1. Add `127.0.0.1	beta.argu.dev` to your hosts file
1. Add `::1		beta.argu.dev` to your hosts file
1. Run `$ ./setup.sh`

If you run into a `sed: 1: "s/{your_local_ip}/10.0. ...": unescaped newline inside substitute pattern` error, try to manually add your local IP address to `setup.sh`:

````
// setup.sh
# Comment the following line
#IP=$(ifconfig | awk '/broadcast/' | awk '/inet /{print $2}')
# And add your IP address
IP=10.0.1.5
````

## Run
1. Run `./run.sh` to start devproxy and re-read the `nginx.conf` file.

## Hosting local files
Add files to `/www` to make them available. The files will be accessible at `argu.dev/filename`. You can put files in folders to simulate routes.
