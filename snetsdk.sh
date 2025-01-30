#!/bin/bash
set -e
#pip install --upgrade pip
if [ ! -d "snet-sdk-python" ]; then
    git clone --branch v3.6.1 https://github.com/singnet/snet-sdk-python.git
else
    echo "Repo already exists. Skipping clone."
fi
cd snet-sdk-python || { echo "Failed to enter directory"; exit 1; }
pip install -r requirements.txt
pip install -e .
echo "snet sdk setup done"