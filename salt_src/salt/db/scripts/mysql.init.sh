username=$1
password=$2

[ -z $username ] && username=manager
[ -z $password ] && password=1234QWER

systemctl start mysqld
sleep 3
mysql -uroot -e "delete from mysql.user where user='';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO ${username}@'%' IDENTIFIED BY '${password}' WITH GRANT OPTION;"
mysql -uroot -e "FLUSH PRIVILEGES;"
mysql -uroot -e "select host, user, password from mysql.user;"

systemctl stop mysqld
cat << EOF > /etc/my.cnf.d/optimization.cnf
[mysqld]
innodb_file_per_table
innodb_flush_method=O_DIRECT
innodb_log_file_size=1G
innodb_buffer_pool_size=4G

skip-name-resolve
EOF

/bin/rm -f /var/lib/mysql/ib_logfile*

touch /var/lib/mysql/inited
systemctl start mysqld
mysql -uroot -e "show variables like '%per_table%';"
