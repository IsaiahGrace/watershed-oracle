#! /usr/bin/zsh
set -e

if [[ ! -f .env ]]; then
    echo "Please create a .env file with the following variables defined:"
    echo "DATABASE_PATH"
    echo "DEBUG_CHAT_ID"
    echo "SECRET_TOKEN"
    exit 1
else
    echo "Contents of .env file:"
    cat .env
fi

cp -v watershed-oracle.service /etc/systemd/system/watershed-oracle.service

systemctl daemon-reload
systemctl enable watershed-oracle
systemctl restart watershed-oracle
systemctl status watershed-oracle
