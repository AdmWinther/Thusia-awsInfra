<h2>Install Suitecrm on local Xampp</h2>

First download the SuiteCRM zip file from https://suitecrm.com/download/ and unzip it in the htdocs folder of Xampp.
Then open the Xampp control panel and start the Apache and MySQL services.
navigate to http://localhost/phpmyadmin and create a database named "crm_db".
Add a user named "crm_user" with password "crm_password" and give it all privileges on the "crm_db" database.
Then navigate to http://localhost/suitecrm/public/#/install and follow the installation steps.

Download PHP.
Download php package composer and run it with th ePHP you downloaded.
in php folder open php.ini file and enable the following extensions: zip, gd, ldap
Then run the following command in the suitecrm folder: composer update --ignore-platform-req0ext-fileinfo
run: composer install --ignore-platform-req0ext-fileinfo
