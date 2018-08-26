# Web-Server-Setup-for-WordPress
1.Copy the wordpress.sh file it will install wordpress sql php and nginx. 




It will configure Domain name and all configurations.


2.Once run the script to check on server use: curl example.com.




3.Used deb-conf utlis package for non-iterative methods.


4.Run that wordpress.sh file with execution permission.


5.Password level secuirity purpose to generate required passwords using default password generate methods.


6.Store the all passwords in /etc/motd.tail file


7.This file Check if PHP, Mysql & Nginx are installed,otherwise installed it.


8.Start the nginx and mysql services.


9.Using wget to Download the wordpress package and unzip it.


10.create databse example_db(example.com_db have mysql synatx error).


11.set the user give the all related privillages.


12.configure the php and restart the php service.


13.It will ask the domain name , after that it will be saved in /etc/hosts file.


14.Take the back up default file and add the required lines /etc/nginx/sites-available/default.


15.Upadte the Domain name in /etc/nginx/sites-available/default.


16.copy the default to wordpress in/etc/nginx/sites-availble.


17.remove the default files in /etc/nginx/sites-availble /etc/nginx/sites-enabled.


18.link the file wordpress to /etc/nginx/sites-availble /etc/nginx/sites-enabled.


19.Configure the wp-config.php file for set DB name, user name and DB password and also use default generate password wp_salt.


20.Copy the all files in wordpress to /var/www/html and remove index.html.


21.So nginx.config file get the index.php files for static content.


22.change the owners www-data:www-data /var/www/html.


23.Resatart Nginx Service.


24.change the execution permission to this file: chmod +x wordpress.sh.



25.excute: bash wordpress.sh.


26.Once the script execution has completed,to check on server which Domain name you set in /etc/hosts file.


27.To check: curl example.com.
       
        
        
