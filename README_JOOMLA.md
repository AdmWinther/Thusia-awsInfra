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