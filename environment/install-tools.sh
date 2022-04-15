#!/bin/bash

mkdir -p ~/tools-bin

vendir sync --locked

find vendor -mindepth 2 -type f -exec mv -t ~/tools-bin -i '{}' +

chmod +x ~/tools-bin/*

echo 'export PATH=$PATH:~/tools-bin' >> ~/.bashrc