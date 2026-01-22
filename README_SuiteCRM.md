This file is made by Adam Winther. It is a guide to configure SuiteCRM after it has been deployed.

Config SuiteCRM after it runs for the first time:
1- Email settings: (Admin -> Email Settings)
    From Name: Does not matter much, it will be the name of the sender of the emails. It can be "Thusia" for example.
    From Address: crm@awin.dk
    SMTP Mail Server: mail.awin.dk
    SMTP Port: 465
    Enable SMTP over SSL or TLS: SSL
    Use SMTP Authentication: Yes (checked)
    Username: crm@awin.dk 
    Password: The password is saved in Terraform.tfvar file.


2- Make an API agent (Admin -> OAuth2 Clients and tokens)
    New Client Credentials client, use password that is in terraform.tfvar file. 
    You will receive new client-id, you need to copy the new client-id in three places:
        Rest_Api local application.properties file.
        Postman Environment variable
        AWS-infra in terraform.tfvar file.

3- Make the Workflow (Admin -> Workflow Management)
    Make a new Workflow.
    Name: "Send Email to Customer"
    WorkFlow Module: "Accounts"
    Run On: "New Records"

    Add Action:
        Select Action: Calculate Fields
        Name: set ID as the account description
        Parameters: ID, Raw value -> Add parameter.        
            It will make a new parameter with value ID that can be used by {P0} in formulas.
        Formulas; Description -> Add formula -> {P0}
        
    Add Action:
        Select Action: Send Email
        Name: Send Email - Opt in
        Click Email + set To as "Record Email".
        Email Template: Confirm Opt-in
        Edit the email template: change the link target to https://api.awin.dk/verifyEmail?userId=$description&code=$sic_code

4- Add the SSL certificate issuer as a trusted agent to Java. (This is done on the EC2 instance) 
    This is done automatically but sometimes we need to do it manually too. Run this command in the EC2:
    sudo docker exec ${var.rest-api-container-name} bash -c "keytool -import -trustcacerts -alias myserver -file /certificates/fullchain.pem -cacerts -storepass changeit -noprompt"
    
5- Import the module for mail mask.