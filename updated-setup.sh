#1. update ec2 instance
sudo su
sudo yum update -y


#2. install apache 
sudo yum install -y httpd httpd-tools mod_ssl
sudo systemctl enable httpd 
sudo systemctl start httpd


#3. install php 7.4
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata
sudo yum install php php-common php-pear -y
sudo yum install php-{cgi,curl,mbstring,gd,mysqli,gettext,json,xml,fpm,intl,zip} -y


#4. install mysql client for RDS connection
sudo rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
sudo yum install mysql-community-client -y


#5. download the FleetCart zip from s3 to the html directory on the ec2 instance
sudo aws s3 sync s3://arm1webfile /var/www/html


#6. unzip the FleetCart zip folder
cd /var/www/html
sudo unzip rentzone.zip


#7. move all the files and folder from the FleetCart directory to the html directory
sudo mv rentzone/* /var/www/html


#8. move all the hidden files from the FleetCart diretory to the html directory
sudo mv rentzone/.well-known /var/www/html
sudo mv rentzone/.env /var/www/html
sudo mv rentzone/.htaccess /var/www/html



#9. delete the FleetCart and FleetCart.zip folder
sudo rm -rf rentzone rentzone.zip


#10. enable mod_rewrite on ec2 linux, add apache to group, and restart server
sudo sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
chown apache:apache -R /var/www/html 
sudo service httpd restart

#11. set permissions on the files on our ec2 instance
sudo chmod -R 777 /var/www/html
sudo chmod -R 777 storage/

#12. Add Database credentials for RDS MySQL connection
sudo vi .env  


DB_CONNECTION=mysql
DB_HOST=arm1.cpgiwdhcwh1s.eu-west-1.rds.amazonaws.com
DB_PORT=3306
DB_DATABASE=ARM0
DB_USERNAME=ARM1
DB_PASSWORD=your-rds-password

#13. Create database and run migrations
mysql -h arm1.cpgiwdhcwh1s.eu-west-1.rds.amazonaws.com -u ARM1 -p
# In MySQL prompt: CREATE DATABASE ARM0; EXIT;
php artisan migrate

#14. Restart Server 
sudo service httpd restart