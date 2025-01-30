#!bin/bash
git clone git@github.com:singnet/snet-sdk-python.git
cd snet-sdk-python
pip install -r requirements.txt
pip install -e .
echo "snet sdk setup done"