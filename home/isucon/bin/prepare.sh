#!/bin/sh
set -ex
################################################################################
echo "# Prepare"
################################################################################

cat > /tmp/prepared_env <<EOF
prepared_time="`date +'%Y-%m-%d %H:%M:%S'`"
nginx_access_log="/var/log/nginx/access.log"
nginx_access_json="/var/log/nginx/access.json"
nginx_error_log="/var/log/nginx/error.log"
mysql_slow_log="/var/log/mysql/slow.log"
mysql_error_log="/var/log/mysql/error.log"
result_dir="/result"
data_dir="\${result_dir}/data"
EOF

. /tmp/prepared_env

# app
(
  cd ${HOME}/webapp/go
  go build -o isuride
)
sudo systemctl restart isuride-go

# mysql
mysql --login-path=isu2 -e "CALL sys.ps_truncate_all_tables(FALSE);"
#sudo truncate -s 0 "${mysql_slow_log}"
sudo truncate -s 0 "${mysql_error_log}"
# sudo systemctl restart mysql

# nginx
sudo truncate -s 0 "${nginx_access_log}"
sudo truncate -s 0 "${nginx_access_json}"
sudo truncate -s 0 "${nginx_error_log}"
# sudo systemctl reload nginx

echo "OK"
