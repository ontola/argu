# Installation
1. [Click here](https://bitbucket.org/arguweb/devproxy/downloads/install.sh) or clone/download this repo.
1. Run `$ install.sh`

# Usage
1. Run `./run.sh` to start devproxy and re-read the `nginx.conf` file.

If you run into a `sed: 1: "s/{your_local_ip}/10.0. ...": unescaped newline inside substitute pattern` error, try to manually add your local IP address to `setup.sh`:

````
// setup.sh
# Comment the following line
#IP=$(ifconfig | awk '/broadcast/' | awk '/inet /{print $2}')
# And add your IP address
IP=10.0.1.5
````
