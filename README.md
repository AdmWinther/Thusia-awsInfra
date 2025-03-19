This file is made by Adam Winther.
This is a guide on how to run the server and how to set up the server.
The server is made to run on AWS and is made with terraform.
The server is made of an AWS EC2 instance that runs a Postgres database and Apache/James Docker container.

How to run the server:

1- You need to add your access key file with name AccessKey.pem in this folder. The file
will be generated on AWS.
2- You need to make configfiles.zip with the following structure
PLEASE NOTE: the zip file structure must be exactly like this, otherwise it is not going to work
configfiles.zip
    ├───james
    │   ├───config_files
    │	│	├───james-database.properties	(see section 2.1)
    │	│	└───keystore			(see section 2.2)
    │   └───postgres_driver
    │		└───postgresql-42.7.5.jar	(see section 2.3)
    └───postgres
        └───config_files
            └───pg_hba.conf			(see section 2.4)


IMPORTANT: REMEMBER IF YOU WANT TO CHANGE PASSWORDS OR NAMES, YOU MUST SET THE VARIABLES IN
BOTH terrafom.tfvar AND IN CORRESPONDING CONFIG FILE.


2.1- Your james-database.properties should look like this. Important parameters are:
    database.driverClassName      - the driver class name for the database
    database.url                  - the url or the connection url for the database
    database.username             - the username for the database
    database.password             - the password for the database
    vendorAdapter.database        - the database design, like SQL, POSTGRESQL, etc.

```
database.driverClassName=org.postgresql.Driver
database.url=jdbc:postgresql://post/db_name
database.username=DB_USERNAME
database.password=DB_PASSWORD
```

2.2- You need to create a keystore file. At the moment I do not know what keystore file is used for.
You do not need the keystore if you are running the postgres image linagora/james-jpa-spring:branch-master but
if you decide to switch to apache/james:jpa-3.6.1 or higher, you need the keystore.
Keystore is made using JAVA OpenJDK. You MUST make the keystore from inside the james container itself otherwise
because the JDK would be different, you would not get it decode.to store the password for the database.
these are the steps to make the keystore:
2.2.1- Run the server without James any container. You can comment the lines that
    run the postgresql and james containers in the terraform.tf file.

2.2.2- Connect to the server with SSH and then run one simple apache/james:jpa-3.6.1 container.
    ```docker run --rm --name james -it -d apache/james:jpa-3.6.1```

    2.2.3- Switch to the bash of the container
    ```docker exec -it james bash```

2.2.4- Run the keytool command to create the keystore
    ```keytool -genkey -alias james -keyalg RSA -keystore keystore```
In this stage, the code will ask you for a password. The default is ```james72laBalle```
You need to enter this password two times in the beginning. then you answere some silly questions and
at the end yes or y. then you would see that a new file nemed "keystore" is created in the folder.

2.2.5- Copy the keystore file from the container to your EC2 instance.
You first need to exit the container and then using "docker cp" to copy the file to the EC2.
    ```docker cp james:/root/keystore /home/ec2-user/keystore```

do ```ls``` to make sure the file is copied to the EC2 instance.
kill the running james container
```docker kill james```

2.2.6- Now you have the keystore file. test the james container with the new keystore. This time
you do not deattach from the container run to make sure you would see the james service run successfully.
```docker run --rm --name james -it -v /home/ec2-user/keystore:/root/conf/keystore apache/james:jpa-3.6.1```
Now you should see a beautiful message that the james server is running.
```[INFO ] o.a.j.GuiceJamesServer - JAMES server started```
stop the server by ```ctrl+C```

2.2.7- Now you have to take the keystore out of the EC2 and place it in the folder
configfiles.zip/james/config_files/.
we move the file first to S3 bucket and then download it from S3 on our maching.
Note: since we are using Amazon Linux, there is already aws-cli installed. otherwise you need
to install aws-cli from yum or apt-get.
Make a new role in AWS IAM and give it S3FullAccess permission. lets name it EC2_S3_Access. go back
to the Instance and select it, click actions and under security, click modify IAM role. In the new
page, select the role you just made and click save. Now your EC2 has access to S3.

2.2.8- Copy the file to one of your existing s3 buckets. if you do not have any, you need to make one.
my bucket name is temp.bucket. Therefore, the command for transferring the file to bucket is:
    ```aws s3 cp /home/ec2-user/keystore s3://temp.bucket/keystore```

2.2.9- Now you need to download the file from the S3 bucket to your local machine.
CONGRATULATIONS! you have the keystore file in your local machine. I am sure you can figure
out the rest by yourself.


2.3-You need to download file postgresql-42.7.5.jar from https://jdbc.postgresql.org/download/ and
place it in the folder configfiles.zip/james/postgres_driver/





2.4 The database password and name you set in james-database.properties as db_password, db_name
must be also set equally in the terraform.tfvar file as db_password, and db_name respectively)


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