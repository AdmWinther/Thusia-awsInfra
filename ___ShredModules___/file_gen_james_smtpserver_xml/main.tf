variable "james_keystore_password" {}
variable "domain_name" {}
resource "local_file" "smtpserver_xml" {
  #This module generate the file /etc/hosts.
  #This file defines which requests must be accepted by the server.
  filename = "smtpserver.xml"
  content  = replace(<<EOF
<?xml version="1.0"?>
<smtpservers>
	<smtpserver enabled="true">
		<jmxName>smtpserver-global</jmxName>
		<bind>0.0.0.0:25</bind>
		<connectionBacklog>200</connectionBacklog>
		<tls socketTLS="false" startTLS="true">
			<keystore>file://conf/keystore</keystore>
			<keystoreType>PKCS12</keystoreType>
			<secret>${var.james_keystore_password}</secret>
			<provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
			<algorithm>SunX509</algorithm>
		</tls>
		<connectiontimeout>360</connectiontimeout>
		<connectionLimit>0</connectionLimit>
		<connectionLimitPerIP>0</connectionLimitPerIP>
		<auth>
			<announce>never</announce>
			<requireSSL>false</requireSSL>
			<plainAuthEnabled>true</plainAuthEnabled>
		</auth>
		<authorizedAddresses>127.0.0.0/8</authorizedAddresses>
		<!-- Trust authenticated users -->
		<verifyIdentity>false</verifyIdentity>
		<maxmessagesize>0</maxmessagesize>
		<addressBracketsEnforcement>true</addressBracketsEnforcement>
		<smtpGreeting>mail.${var.domain_name}</smtpGreeting>
		<handlerchain>
			<handler class="org.apache.james.smtpserver.fastfail.ValidRcptHandler"/>
			<handler class="org.apache.james.smtpserver.CoreCmdHandlerLoader"/>
		</handlerchain>
	</smtpserver>
    <smtpserver enabled="true">
        <jmxName>smtpserver-TLS</jmxName>
        <bind>0.0.0.0:465</bind>
        <connectionBacklog>200</connectionBacklog>
        <tls socketTLS="true" startTLS="false">
            <!-- To create a new keystore execute:
              keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
             -->
            <keystore>file://conf/keystore</keystore>
            <keystoreType>PKCS12</keystoreType>
            <secret>${var.james_keystore_password}</secret>
            <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
            <algorithm>SunX509</algorithm>

            <!-- Alternatively TLS keys can be supplied via PEM files -->
            <!-- <privateKey>file://conf/private.key</privateKey> -->
            <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
            <!-- An optional secret might be specified for the private key -->
            <!-- <secret>${var.james_keystore_password}</secret> -->
        </tls>
        <connectiontimeout>360</connectiontimeout>
        <connectionLimit>0</connectionLimit>
        <connectionLimitPerIP>0</connectionLimitPerIP>
        <!--
           Authorize only local users
        -->
        <auth>
            <announce>forUnauthorizedAddresses</announce>
            <requireSSL>true</requireSSL>
            <plainAuthEnabled>true</plainAuthEnabled>
            <!-- Sample OIDC configuration -->
            <!--
            <oidc>
                <oidcConfigurationURL>https://changeme.org/auth/realms/upn/.well-known/openid-configuration</oidcConfigurationURL>
                <jwksURL>https://changeme.org/auth/realms/upn/protocol/openid-connect/certs</jwksURL>
                <claim>email</claim>
                <scope>openid profile email</scope>
            </oidc>
            -->
        </auth>
        <authorizedAddresses>127.0.0.0/8</authorizedAddresses>
        <verifyIdentity>true</verifyIdentity>
        <maxmessagesize>0</maxmessagesize>
        <addressBracketsEnforcement>true</addressBracketsEnforcement>
        <smtpGreeting>Apache JAMES awesome SMTP Server</smtpGreeting>
        <handlerchain>
            <handler class="org.apache.james.smtpserver.fastfail.ValidRcptHandler"/>
            <handler class="org.apache.james.smtpserver.CoreCmdHandlerLoader"/>
        </handlerchain>
    </smtpserver>
	<smtpserver enabled="true">
        <jmxName>smtpserver-authenticated</jmxName>
        <bind>0.0.0.0:587</bind>
        <connectionBacklog>200</connectionBacklog>
        <tls socketTLS="false" startTLS="true">
            <!-- To create a new keystore execute:
              keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
             -->
            <keystore>file://conf/keystore</keystore>
            <keystoreType>PKCS12</keystoreType>
            <secret>${var.james_keystore_password}</secret>
            <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
            <algorithm>SunX509</algorithm>

            <!-- Alternatively TLS keys can be supplied via PEM files -->
            <!-- <privateKey>file://conf/private.key</privateKey> -->
            <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
            <!-- An optional secret might be specified for the private key -->
            <!-- <secret>${var.james_keystore_password}</secret> -->
        </tls>
        <connectiontimeout>360</connectiontimeout>
        <connectionLimit>0</connectionLimit>
        <connectionLimitPerIP>0</connectionLimitPerIP>
        <auth>
            <announce>forUnauthorizedAddresses</announce>
            <requireSSL>true</requireSSL>
            <plainAuthEnabled>true</plainAuthEnabled>
            <!-- Sample OIDC configuration -->
            <!--
            <oidc>
                <oidcConfigurationURL>https://changeme.org/auth/realms/upn/.well-known/openid-configuration</oidcConfigurationURL>
                <jwksURL>https://changeme.org/auth/realms/upn/protocol/openid-connect/certs</jwksURL>
                <claim>email</claim>
                <scope>openid profile email</scope>
            </oidc>
            -->
        </auth>
        <authorizedAddresses>127.0.0.0/8</authorizedAddresses>
        <verifyIdentity>true</verifyIdentity>
        <maxmessagesize>0</maxmessagesize>
        <addressBracketsEnforcement>true</addressBracketsEnforcement>
        <smtpGreeting>Apache JAMES awesome SMTP Server</smtpGreeting>
        <handlerchain>
            <handler class="org.apache.james.smtpserver.fastfail.ValidRcptHandler"/>
            <handler class="org.apache.james.smtpserver.CoreCmdHandlerLoader"/>
        </handlerchain>
    </smtpserver>
</smtpservers>

EOF
    , "\r", "")
}
