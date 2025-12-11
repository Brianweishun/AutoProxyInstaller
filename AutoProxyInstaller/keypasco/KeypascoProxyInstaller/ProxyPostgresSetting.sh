# !/bin/bash

# Check the number of parameters
if [ $# -eq 0 ]; then
    echo "No parameters provided."
    exit 1
elif [ $# -eq 1 ]; then
    echo "One parameter provided: $1"
else
    echo "Invaslid parameters provided."
	exit 1
fi

IP=$1

#echo $IP

echo "Install Postgres 16"
sudo dnf --disablerepo="*" install ./rpm/postgresql16-libs-16.4-1PGDG.rhel9.x86_64.rpm
#sudo dnf --disablerepo="*" install libicu-67.1-9.el9.x86_64.rpm
sudo dnf --disablerepo="*" install ./rpm/postgresql16-16.4-1PGDG.rhel9.x86_64.rpm
sudo dnf --disablerepo="*" install ./rpm/postgresql16-server-16.4-1PGDG.rhel9.x86_64.rpm

sudo /usr/pgsql-16/bin/postgresql-16-setup initdb

if [ ! -e "./backup/pg_hba.conf.ori" ]; then
    # File does not exist
	cp "/var/lib/pgsql/16/data/pg_hba.conf" "./backup/pg_hba.conf.ori"
fi

if [ ! -e "./backup/postgresql.conf.ori" ]; then
    # File does not exist
	cp "/var/lib/pgsql/16/data/postgresql.conf" "./backup/postgresql.conf.ori"
fi

sudo systemctl start postgresql-16.service
sudo systemctl enable postgresql-16.service

sudo sed -i "/listen_addresses/a listen_addresses = '*'" "/var/lib/pgsql/16/data/postgresql.conf"    #add line
sudo sed -i "s|#password_encryption = scram-sha-256|password_encryption = md5|" "/var/lib/pgsql/16/data/postgresql.conf"  #replacce

sudo sed -i "s|#password_encryption = scram-sha-256|password_encryption = md5|" "/var/lib/pgsql/16/data/postgresql.conf"  #replacce

sudo sed -i "/IPv4 local/a host    all             all             $IP/32            md5" "/var/lib/pgsql/16/data/pg_hba.conf"    #add line
sudo sed -i "s|host    all             all             127.0.0.1/32            scram-sha-256|host    all             all             127.0.0.1/32            trust|" "/var/lib/pgsql/16/data/pg_hba.conf"
#sudo sed -i "s|host    all             all             ::1/128                 scram-sha-256|#host    all             all             ::1/128                 trust|" "/var/lib/pgsql/16/data/pg_hba.conf"

sudo -u postgres psql -c "create user proxyuser;"
sudo -u postgres psql -c "ALTER SYSTEM SET password_encryption = 'md5';"   #scram-sha-256 or md5
sudo -u postgres psql -c "SELECT pg_reload_conf();"
sudo -u postgres psql -c "show password_encryption;"
sudo -u postgres psql -c "alter user proxyuser with password 'Test123456';"
sudo -u postgres psql -c "create database proxydb owner proxyuser;"
sudo -u postgres psql -c "grant all privileges on database proxydb to proxyuser;"

sudo cp ./files/V1.016.39.1.43.0-all.sql /home/
sudo -u postgres PGPASSWORD=Test123456 psql -h 127.0.0.1 -U proxyuser -d proxydb -f /home/V1.016.39.1.43.0-all.sql
sudo rm /home/V1.016.39.1.43.0-all.sql


sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent
sudo firewall-cmd --reload

sudo systemctl restart postgresql-16.service

