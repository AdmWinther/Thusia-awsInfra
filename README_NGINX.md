<h1>1. NGINX setup</h1>

<h2>1.01</h2>
<h2>1.02</h2>
<h2>1.03</h2>
<h2>1.04</h2>


<h2>1.10 Config Nginx to accept big files</h2>
When I needed to upload a big file in Joomla, I got the error "request entity too large".
In the logs of the Nginx container, I found the error "client intended to send too large body".
To fix this, I added the following line to the `nginx.conf` file under "awin.dk" and "www.awin.dk" server blocks:
```
client_max_body_size 100M;
```
