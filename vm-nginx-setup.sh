#! /bin/bash
# TO BE EXECUTED ON VM

sudo apt update
sudo apt -y upgrade 
sudo apt -y install nginx

set -e
# Install pre-reqs
sudo apt -y install python3 git

o=$(python3 -c $'import os\nprint(os.get_blocking(0))\nos.set_blocking(0, True)')

#Download Latest Go
GOURLREGEX='https://dl.google.com/go/go[0-9\.]+\.linux-amd64.tar.gz'
echo "Finding latest version of Go for AMD64..."

url="$(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 )"

latest="$(echo $url | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )"
echo "Downloading latest Go for AMD64: ${latest}"

wget --quiet --continue --show-progress "${url}"

unset url
unset GOURLREGEX


# Remove Old Go
sudo rm -rf /usr/local/go

# Install new Go
sudo tar -C /usr/local -xzf go"${latest}".linux-amd64.tar.gz
echo "Create the skeleton for your local users go directory"
mkdir -p ~/go/{bin,pkg,src}
echo "Setting up GOPATH"
echo "export GOPATH=~/go" >> ~/.profile && source ~/.profile
echo "Setting PATH to include golang binaries"
echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >> ~/.profile && source ~/.profile
echo "Installing dep for dependency management"
go get -u github.com/golang/dep/cmd/dep

# Remove Download
rm go"${latest}".linux-amd64.tar.gz

# Vegeta
go get -u github.com/tsenart/vegeta