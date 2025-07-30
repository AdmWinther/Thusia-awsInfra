<h1>1. Joomla Setup</h1>
<h2>1.1 Where to find php.ini file</h2>
The location of the `php.ini` file is specified in Joomla web interface. Navigate to: System > System Information >
PHP Information. Look for the line that says "Configuration File (php.ini) Path". This is the address.

<h2>1.2 How to change the maximum package size</h2>
You need to change the `upload_max_filesize` and `post_max_size` values in the `php.ini` file.

<h2>1.3 Running the server from scratch</h2>
<h3>1.3.1 Install Joomla</h3>
When you run Joomla for the first time, it will ask you to install it. You can do this by following the instructions.
The database type settings should be set to `MySQLi`. For the database hostname, enter the docker container name. 
Currently the database container neme is "mariadb". The rest is normal setup.

<h3>1.3.2 Turn on Search Engine URL friendly</h3>
Go to System > Global Configuration > Site and set "Search Engine Friendly URLs" to "Yes".
You also need to rename the `htaccess.txt` file to `.htaccess` in the root directory of your Joomla installation.
Since the root directory is a mounted volume, the change will be persistent.

<h3>1.3.3 Install the Backup Component</h3>
install the Akeeba Backup component from the Joomla Extension Directory.
Go to Components > Akeeba Backup and configure it. Just follow the instructions on the screen.
Then select "Configure" and set the "Archive Format" to "ZIP".


<h3>1.3.4 Install SSH certificate for HTTPS</h3>
I got a certificate from zeroSSL.
Then I made two modules, one to make the file configuration.php and the other to make .htaccess file.
At the end of the process, it was just as simple as sending the ssl files to the client via NGINX.

<h2>1.4 How to write Scripts for forms</h2>
1- under System > Global Configuration > Text Filters, set the "Super User" to "No Filtering".
2- Go to System > Manage > Plugins and search for "TinyMCE Editor". Under "Prohibited Elements", remove "script" and 
under Valid Elements, add "script". This will allow you to write scripts in the TinyMCE editor. 
To allow all attrebutes, you can set the "Valid Elements" to "*[*]". make sure you also add *[*] to extended valid elements.
THIS MUST BE DONE FOR SET0, SET1, and SET2.

<h2>1.5 How to make an API token</h2>
A new user of type Super User must be created. After that, login with the user and go to Users > Manage > Your User.
Under the "API Tokens" tab, you can create a new token.

<h2>1.6 Note while trying to use Joomla API</h2>
Java does not know how to connect the SSL certificate to the chain SSL. Therefore, we need to combine the SSL certificates
manually and load the full chain in Nginx.
To do this, you can use the following command:
```
cat joomla_ssl-certificate.crt joomla_ssl_ca_certificate.crt > joomla_ssl_fullchain.crt
```
Then this must be provisioned to the Nginx container and loaded in the Nginx configuration file.
