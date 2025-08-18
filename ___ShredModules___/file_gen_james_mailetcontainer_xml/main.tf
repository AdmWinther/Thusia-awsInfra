variable "aws_ses_smtp_relay_username" {}
variable "aws_ses_smtp_relay_password" {}
variable "aws_ses_mail_relay_address" {}
variable "aws_ses_mail_relay_port" {}
variable "domain_name" {}
resource "local_file" "james_mailetcontainer_xml" {
  filename = "mailetcontainer.xml"
  content = replace(<<EOF
<?xml version="1.0"?>

<!--
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
 -->

<!-- Read https://james.apache.org/server/config-mailetcontainer.html for further details -->

<mailetcontainer enableJmx="true">

    <context>
        <!-- When the domain part of the postmaster mailAddress is missing, the default domain is appended.
        You can configure it to (for example) <postmaster>postmaster@myDomain.com</postmaster> -->
        <postmaster>postmaster</postmaster>
    </context>

    <spooler>
        <threads>20</threads>
        <errorRepository>file://var/mail/error/</errorRepository>
    </spooler>

    <processors>
        <processor state="root" enableJmx="true">
            <mailet match="All" class="PostmasterAlias"/>
            <mailet match="RelayLimit=30" class="Null"/>
            <mailet match="All" class="ToProcessor">
                <processor>transport</processor>
            </mailet>
        </processor>

        <processor state="error" enableJmx="true">
            <mailet match="All" class="MetricsMailet">
                <metricName>mailetContainerErrors</metricName>
            </mailet>
            <mailet match="All" class="Bounce">
                <onMailetException>ignore</onMailetException>
            </mailet>
            <mailet match="All" class="ToRepository">
                <repositoryPath>file://var/mail/error/</repositoryPath>
                <onMailetException>propagate</onMailetException>
            </mailet>
        </processor>

	<processor state="transport" enableJmx="true">
		<matcher name="relay-allowed" match="org.apache.james.mailetcontainer.impl.matchers.Or">
			<matcher match="SMTPAuthSuccessful"/>
			<matcher match="SMTPIsAuthNetwork"/>
			<matcher match="SentByMailet"/>
		</matcher>

		<mailet match="All" class="RemoveMimeHeader">
			<name>bcc</name>
			<onMailetException>ignore</onMailetException>
		</mailet>

		<mailet match="SMTPAuthSuccessful" class="SetMimeHeader">
			<name>X-UserIsAuth</name>
			<value>true</value>
			<onMailetException>ignore</onMailetException>
		</mailet>

		<mailet match="HasMailAttribute=org.apache.james.SMIMECheckSignature" class="SetMimeHeader">
			<name>X-WasSigned</name>
			<value>true</value>
			<onMailetException>ignore</onMailetException>
		</mailet>

		<mailet match="All" class="RecipientRewriteTable"/>

		<!-- Place a copy in the user Sent folder -->
		<mailet match="SenderIsLocal" class="ToSenderFolder">
			<folder>Sent</folder>
			<consume>false</consume>
		</mailet>

		<!-- Is the recipient is for a local account, deliver it locally -->
		<mailet match="RecipientIsLocal" class="Sieve"/>
		<mailet match="RecipientIsLocal" class="AddDeliveredToHeader"/>
		<mailet match="RecipientIsLocal" class="LocalDelivery"/>

		<!-- If the host is handled by this server and it did not get -->
		<!-- locally delivered, this is an invalid recipient -->
	        <mailet match="HostIsLocal" class="ToProcessor">
			<processor>local-address-error</processor>
			<notice>550 - Requested action not taken: no such user here</notice>
		</mailet>

		<!-- CHECKME! -->
		<!-- This is an anti-relay matcher/mailet combination -->
		<!--
		<mailet match="RemoteAddrNotInNetwork=127.0.0.1" class="ToProcessor">
			<processor>relay-denied</processor>
			<notice>550 - Requested action not taken: relaying denied</notice>
		</mailet>
		-->
		<!-- Attempt remote delivery using the specified repository for the spool, -->
		<!-- using delay time to retry delivery and the maximum number of retries -->
		<mailet match="All" class="RemoteDelivery">
			<outgoing>outgoing</outgoing>
			<delayTime>5000, 100000, 500000</delayTime>
			<maxRetries>3</maxRetries>
			<maxDnsProblemRetries>0</maxDnsProblemRetries>
			<deliveryThreads>10</deliveryThreads>
			<sendpartial>true</sendpartial>
			<bounceProcessor>bounces</bounceProcessor>

			<!-- A single mail server to deliver all outgoing messages. -->
			<gateway>${var.aws_ses_mail_relay_address}</gateway>
			<gatewayPort>${var.aws_ses_mail_relay_port}</gatewayPort>
			<gatewayUsername>${var.aws_ses_smtp_relay_username}</gatewayUsername>
			<gatewayPassword>${var.aws_ses_smtp_relay_password}</gatewayPassword>
			<!-- Set the HELO/EHLO name to use when connectiong to remote SMTP-Server -->
			<mail.smtp.localhost>${var.domain_name}</mail.smtp.localhost>

		</mailet>

        </processor>

        <processor state="relay" enableJmx="true">
            <mailet match="All" class="RemoteDelivery">
                <outgoingQueue>outgoing</outgoingQueue>
                <delayTime>5000, 100000, 500000</delayTime>
                <maxRetries>3</maxRetries>
                <maxDnsProblemRetries>0</maxDnsProblemRetries>
                <deliveryThreads>10</deliveryThreads>
                <sendpartial>true</sendpartial>
                <bounceProcessor>bounces</bounceProcessor>
            </mailet>
        </processor>

        <processor state="local-address-error" enableJmx="true">
            <mailet match="All" class="MetricsMailet">
                <metricName>mailetContainerLocalAddressError</metricName>
            </mailet>
            <mailet match="All" class="Bounce">
                <attachment>none</attachment>
            </mailet>
            <mailet match="All" class="ToRepository">
                <repositoryPath>file://var/mail/address-error/</repositoryPath>
            </mailet>
        </processor>

        <processor state="relay-denied" enableJmx="true">
            <mailet match="All" class="MetricsMailet">
                <metricName>mailetContainerRelayDenied</metricName>
            </mailet>
            <mailet match="All" class="Bounce">
                <attachment>none</attachment>
            </mailet>
            <mailet match="All" class="ToRepository">
                <repositoryPath>file://var/mail/relay-denied/</repositoryPath>
                <notice>Warning: You are sending an e-mail to a remote server. You must be authenticated to perform such an operation</notice>
            </mailet>
        </processor>

        <processor state="bounces" enableJmx="true">
            <mailet match="All" class="MetricsMailet">
                <metricName>bounces</metricName>
            </mailet>
            <mailet match="All" class="DSNBounce">
                <passThrough>false</passThrough>
            </mailet>
        </processor>

        <processor state="rrt-error" enableJmx="false">
            <mailet match="All" class="ToRepository">
                <repositoryPath>file://var/mail/rrt-error/</repositoryPath>
                <passThrough>true</passThrough>
            </mailet>
            <mailet match="IsSenderInRRTLoop" class="Null"/>
            <mailet match="All" class="Bounce"/>
        </processor>

    </processors>

</mailetcontainer>
EOF
, "\r", "")
}
