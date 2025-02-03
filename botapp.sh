#!/bin/bash
cd r1storm
rm .env
wget https://z2ai-file.s3.us-east-1.amazonaws.com/.env
clear
nohup gradio bot_template.py &
echo "Open Web Browser and type http://127.0.0.1:7861 to access the R1Storm ChatBot"