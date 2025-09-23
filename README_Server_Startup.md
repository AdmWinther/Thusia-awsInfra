<h2>1 start the server</h2>
Set the ``` container_volume_initialize = "true" ``` to initialize the volume.
Run the CICD_file in Rest API project to build the images and upload it into the S3 bucket.
Start the server with ```erraform apply -auto-approve```.

<h2>2 stop the server</h2>
Setup the Joomla server with usual parameters.

Setup the mail settingss for SuiteCRM.

<h2>3 setup Joomla parameters</h2>
install the plugin to manage the users and go to extension manager and enable it.

install the Joomla Signup form component, make a main menu item and assign the signup form to it.

install the Joomla Theme and activate the theme.

add JavaRestApiToken User into Joomla.
Assign it to Superuser group.
Login into that user and copy the token to the terraform.tfvars file.

<h2>4 setup SuiteCRM parameters</h2>
Go to Admin and make an authentication token for the Rest Api user.
