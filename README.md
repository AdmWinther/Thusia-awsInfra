gitThis file is made by Adam Winther.
This is a guide on how to run the server and how to set up the server.
The server is made to run on AWS and is made with terraform.
The server is made of an AWS EC2 instance that runs a Postgres database and Apache/James Docker container.

How to run the server:

1- You need to add your access key file with name AccessKey.pem in this folder. The file
will be generated on AWS.

2- You need to make a series of configuration files.

```
    ├───james
    │   ├───config_files
    │	│	├───james-database.properties	(see section 2.1)
    │	│	└───keystore                    (see section 2.2)
    │   └───JDBC_driver
    │		└───mysql-jdbc-driver.jar      (see section 2.3)
    └───mysql
        └───config_files
            ├───pg_hba.conf		        (see section 2.4)
            └───database_init.sql	        (see section 2.5)
```

IMPORTANT: REMEMBER IF YOU WANT TO CHANGE PASSWORDS OR NAMES, YOU MUST SET THE VARIABLES IN
BOTH ```terrafom.tfvar``` AND IN CORRESPONDING CONFIG FILE.


<h2>2.1</h2>- Your james-database.properties you should have the following parameters:

```
    database.driverClassName      - the driver class name for the database
    database.url                  - the url or the connection url for the database
    database.username             - the username for the database
    database.password             - the password for the database
    vendorAdapter.database        - the database design, like SQL, POSTGRESQL, etc.
```

for mysql database, the file should look like this:

```
database.driverClassName=com.mysql.cj.jdbc.Driver
database.url=jdbc:mysql://The_server_address/db_name
database.username=DB_USERNAME
database.password=DB_PASSWORD
```

Since we make a docker network and all the containers are in the same network, we do not need to add prot at
the end of the server address, otherwise we need that.

<h2>2.2</h2>- You need to create a keystore file. At the moment I do not know what keystore file is used for.
You do not need the keystore if you are running the postgres image linagora/james-jpa-spring:branch-master but
if you decide to switch to apache/james:jpa-3.6.1 or higher, you need the keystore.
Keystore is made using JAVA OpenJDK. You MUST make the keystore from inside the james container itself otherwise
because the JDK would be different, you would not get it decode.to store the password for the database.
these are the steps to make the keystore:
<h3>2.2.1</h3>- Run the server without James any container. You can comment the lines that
    run the postgresql and james containers in the terraform.tf file.

<h3>2.2.2</h3>- Connect to the server with SSH and then run one simple apache/james:jpa-3.6.1 container.

    ```docker run --rm --name james -it -d apache/james:jpa-3.6.1```
2.2.3- Switch to the bash of the container
    ```docker exec -it james bash```

<h3>2.2.4</h3>- Run the keytool command to create the keystore 

```keytool -genkey -alias james -keyalg RSA -keystore keystore```

In this stage, the code will ask you for a password. The default is ```james72laBalle```
You need to enter this password two times in the beginning. then you answer some silly questions and
at the end yes or y. then you would see that a new file nemed "keystore" is created in the folder.

2.2.5- Copy the keystore file from the container to your EC2 instance.
You first need to exit the container and then using "docker cp" to copy the file to the EC2.
    ```docker cp james:/root/keystore /home/ec2-user/keystore```

do ```ls``` to make sure the file is copied to the EC2 instance.
kill the running james container
```docker kill james```

2.2.6- Now you have the keystore file. test the james container with the new keystore. This time
you do not disconnect (-d) from the container run to make sure you would see the james service run successfully.
```docker run --rm --name james -it -v /home/ec2-user/keystore:/root/conf/keystore apache/james:jpa-3.6.1```
Now you should see a beautiful message that the james server is running.
```[INFO ] o.a.j.GuiceJamesServer - JAMES server started```
stop the server by ```ctrl+C```

2.2.7- Now you have to take the keystore out of the EC2 and place it in the folder
configfiles.zip/james/config_files/.
we move the file first to S3 bucket and then download it from S3 on our matching.
Note: since we are using Amazon Linux, there is already aws-cli installed. otherwise you need
to install aws-cli from yum or apt-get.
Make a new role in AWS IAM and give it S3FullAccess permission. let's name it EC2_S3_Access. go back
to the Instance and select it, click actions and under security, click modify IAM role. In the new
page, select the role you just made and click save. Now your EC2 has access to S3.

2.2.8- Copy the file to one of your existing s3 buckets. if you do not have any, you need to make one.
my bucket name is temp.bucket. Therefore, the command for transferring the file to bucket is:
    ```aws s3 cp /home/ec2-user/keystore s3://temp.bucket/keystore```

2.2.9- Now you need to download the file from the S3 bucket to your local machine.
CONGRATULATIONS! you have the keystore file in your local machine. I am sure you can figure
out the rest by yourself.


<h2>2.3</h2>-You need to download file postgresql-42.7.5.jar from https://jdbc.postgresql.org/download/ and
place it in the folder configfiles.zip/james/postgres_driver/





<h2>2.4</h2> The database password and name you set in james-database.properties as db_password, db_name
must be also set equally in "terraform.tfvar" file as db_password, and db_name respectively.


This is the content of your pg_hba.conf
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     md5
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5

host all all all scram-sha-256
```

<h2>2.5</h2>
file

    ```database_init.sql```    
is the file that is used to initialize the database. The file should have the following content:

```
CREATE DATABASE ${var.james_db_name};
CREATE USER '${var.james_db_username}'@'%' IDENTIFIED BY '${var.james_db_password}';
GRANT ALL PRIVILEGES ON ${var.james_db_name}.* TO '${var.james_db_username}'@'%';


CREATE DATABASE ${var.crm_db_name};
CREATE USER '${var.crm_db_username}'@'%' IDENTIFIED BY '${var.crm_db_password}';
GRANT ALL PRIVILEGES ON ${var.crm_db_name}.* TO '${var.crm_db_username}'@'%';
```

<h2>2.6</h2>
To store the database data you need to create a volume in AWS EBS. The volume should be at least 10GB.
#First make an EBC volume in AWS console/EC2/volume, get the volume id and attach it to the instance.
#The Terraform code already attach the EBC volume to the instance. you just need to replace the volume-id in the code.

```
Volume will be mounted at /dev/xvdd
```
#If the volume is new, you need to format it. This is needed for the first time after creating the volume.
```
sudo mkfs -t ext4 /dev/xvdd
```
#Then create a directory to mount the volume: Run EC2. Terraform must already mount the EBC in /var/lib/docker/volume/
```
sudo mount /dev/xvdd /home/ec2-user/volumes
```

#make a folder for database volume
```
mkdir /home/ec2-user/volumes/database
```
#Change the ownership of the directory to mysql
```
sudo chown -R 999:999 /home/ec2-user/volumes/database
```

#Then run the database container and mount the volume to the container
```
docker run --rm --name mariadb -v /home/ec2-user/volumes/database:/var/lib/mysql -v /home/ec2-user/database_init.sql:/docker-entrypoint-initdb.d/database_init.sql -e MARIADB_ROOT_PASSWORD=rootsecret --network my-docker-network mariadb:10.6
```


#hereafter, we can run the following command to start the database container. we do not need to mount database_init.sql file anymore.
```
docker run --rm --name mariadb -v /home/ec2-user/volumes/database:/var/lib/mysql -e MARIADB_ROOT_PASSWORD=rootsecret --network my-docker-network mariadb:10.6
```

<h2>James</h2>

```
docker run --rm --name james -v /home/ec2-user/james-database.properties:/root/conf/james-database.properties -v /home/ec2-user/jdbc.jar:/root/libs/jdbc.jar -v /home/ec2-user/keystore:/root/conf/keystore -p25:25 -p110:110 -p143:143 -p465:465 -p587:587 -p993:993 -p8000:8000 --network my-docker-network -d apache/james:jpa-3.8.2
```


<h2>SuiteCRM</h2>
Running SuiteCRM is very simple. You just need to run the following command:



The database for CRM must be built separately.
```
docker run --rm --name mariadb -e ALLOW_EMPTY_PASSWORD=yes -e MARIADB_ROOT_PASSWORD=rootsecret -e MARIADB_USER=crmdb -e MARIADB_PASSWORD=rootsecret -e MARIADB_DATABASE=crmdb --network my-docker-network -v /home/ec2-user/volumes/suite_crm:/var/lib/mysql mariadb:10.6
```

and then running SuiteCRM
```
docker run --rm --name suitecrm \
  -p 8080:8080 -p 8443:8443 \
  -e ALLOW_EMPTY_PASSWORD=yes \
  -e SUITECRM_DATABASE_USER=adam \
  --env SUITECRM_DATABASE_PASSWORD=adamsecret \
  --env SUITECRM_DATABASE_NAME=crmdb \
  --network thusia_my-docker-network \
  --volume /home/ec2-user/volumes/suitecrm:/bitnami/suitecrm \
  bitnami/suitecrm:8.8.0
```

docker run --rm --name suitecrm \
-p 8080:8080 -p 8443:8443 \
-e ALLOW_EMPTY_PASSWORD=yes \
-e SUITECRM_DATABASE_USER=adam \
--env SUITECRM_DATABASE_PASSWORD=adamsecret \
--env SUITECRM_DATABASE_NAME=crmdb \
--network my-docker-network \
--volume /home/ec2-user/vvv:/bitnami/suitecrm \
bitnami/suitecrm:latest



<h2>SuiteCRM API</h2>
First thing first. According to https://community.suitecrm.com/t/rest-api-v8-for-bitnami-container-version/93238 I 
need to follow the instruction in https://docs.suitecrm.com/developer/api/developer-setup-guide/json-api/#_generate_private_and_public_key_for_oauth2
but with a difference, at the last step the user is daemon, not www-data. 
So I exec bash on the suiteCRM container, navigated to /opt/bitnami/suitecrm and run the following command:

```
composer install
```
Then navigate to `/bitnami/suitecrm/public/legacy/Api/V8/OAuth2` and generate a private key:
```
openssl genrsa -out private.key 2048
```
Then to Generate a public key:
```
openssl rsa -in private.key -pubout -out public.key
```
The permission of the key files must be 600, so change it.
```
chmod 600 private.key public.key
```
Then executed:
```
chown daemon:daemon p*.key
```
Next step is to make a credentials in SuiteCRM. In the browser, navigate to http://{{ip}}:8080 and login with admin/admin
Then go to Admin Panel > OAuth2 Clients and Tokens. From the top menu, under "OAuth2 Clients", click "Create" click on 
"+ New Client Credentials client" and fill the form, and make sure you choose some password in the field "Secret".
Then click "Save" and you will see the client id next page. Save them ID and secret, we need that for using APIs.


<h2>Telnet to James</h2>
I could successfully telnet to James, I ran another EC2 and installed telnet on it and then:
```
telnet mail.awin.dk 587
```
If you make the connection successfully, the response to this command would be:
```
Trying 54.84.219.48...
Connected to mail.awin.dk.
Escape character is '^]'.
220 Apache JAMES awesome SMTP Server
```
Then I identified myself as adam;
```
HELO adam
```
And the server confirmed my connection being successful by replying;
```
250 947c5b429b27 Hello adam [54.227.41.25])
```
Now I will mention from which mailbox I want to send an email:
```
MAIL FROM:<awin@awin.dk>
```
Please pay attention to the format of the command. The command and spaces must be exactly as specified.
And as a result the server responded with code 250 which shows success. Please note that in this pint the server will not control if the mailbox is valid, so even if you enter an invalid mailbox, you still get code 250.
```
250 2.1.0 Sender <awin@awin.dk> OK
```
Now I should mention the receiver mailbox:
```
RCPT TO:<jpo@awin.dk>
```
and therefore the server response will be;
```
250 2.1.5 Recipient <jpo@awin.dk> OK
```
Now I will tell the server that I am going to enter the mail itself:
So I enter:
```
DATA
```
And the server responded:
```
354 Ok Send data ending with <CRLF>.<CRLF>
```
Finally time to enter the mail body:
```
Subject: this is a very important moment
This is the moment that I sent the first email from my own mail server.
```
then I ended the body with a single period and enter;
```
.
```
then the server responded:
```
250 2.6.0 Message received
```
<h3>Turning on the authentication</h3>
Followed the comments on git page: https://github.com/apache/james-project/blob/master/server/apps/spring-app/src/main/resources/smtpserver.xml
disconnecting all of the ports, and only letting port 25 to be open.
Use 
```
auth login
```
to login. then it asks you for userneme and password. enter followings respectively.
```
YXdpbkBhd2luLmRr
YXdpbg==
```
```
```
```
```
```
```
```
```


