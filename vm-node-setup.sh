#!/bin/bash

sudo apt -y update
sudo apt -y upgrade

sudo apt -y install psmisc

# [get_golang.sh](https://gist.github.com/n8henrie/1043443463a4a511acf98aaa4f8f0f69)
# Download latest Golang release for AMD64
# https://dl.google.com/go/go1.10.linux-amd64.tar.gz

set -e

# Install pre-reqs
sudo apt-get -y install python3 git

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

# Download .NET SDK
wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
wget https://packages.microsoft.com/config/debian/10/prod.list
sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list

sudo apt -y update
sudo apt -y install apt-transport-https
sudo apt -y update
sudo apt -y install dotnet-sdk-3.1

# Clone and build gci-proxy
git clone https://github.com/lucashsilva/gci-proxy
cd gci-proxy
go install
go build
cd ..

# Clone and build gci-aspnet and copy binary to msgpush
git clone https://github.com/lucashsilva/gci-aspnet.git
cd gci-aspnet
dotnet build
cd ..

# Clone and build msgpush
git clone https://github.com/lucashsilva/garbage-generator
cd garbage-generator
mkdir ./GarbageGenerator/lib/
cp ../gci-aspnet/bin/Debug/netcoreapp3.1/GCI.dll ./GarbageGenerator/lib/
cd