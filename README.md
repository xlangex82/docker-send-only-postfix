# docker-send-only-postfix
Docker container with Postfix configured in send-only mode and OpenDKIM.
Postfix will accept emails from all private IP addresses on all network interfaces.
All emails send from Postfix to other email servers are encrypted using standard TLS.

## Clone Repo
```bash
sudo git pull https://github.com/xlangex82/docker-send-only-postfix.git 
```

## Update your local Repo files
```bash
sudo git pull origin master
```
## Prepare your Folderstructure for docker-compose usage
If we assume that you will create your docker-compose project unter the path /docker/YOURPROJECTNAME/
Change YOURPROJECTNAME with your foldername

change into cloned repor folder and run following commands:
```bash
cd docker-send-only-postfix
cd docker-compose
sudo chmod +x create_files_and_folders.sh
sudo ./create_files_and_folders.sh /docker/YOURPROJECTNAME/data/
```
After that, you need to copy the example docker-compose.yml and .env file
```bash
sudo cp docker-compose.yml /docker/YOURPROJECTNAME/.
sudo cp .env /docker/YOURPROJECTNAME/.
```
Your projectfolder should look like this
```bash
drwxr-xr-x 4 root root 4096 May 21 07:29 .
drwxr-xr-x 7 root root 4096 May 20 13:11 ..
drwxr-xr-x 3 root root 4096 May 19 03:11 data
-rw-r--r-- 1 root root 1964 May 19 03:29 docker-compose.yml
-rw-r--r-- 1 root root 1007 May 19 03:30 .env
```

Next edit .env file to your needs!
Next edit docker-compose.yml file according your needs!

## Build your own local image from Dockerfile

Run the following to create your local image (change the tagging/naming as you wish)
change into cloned repor folder and run following commands:
```bash
sudo docker build -t xlangex82/send-only-postfix:2025-05-20.Alpha1 -f Dockerfile . 
```
If the process ends without any errors, the image is normally created successfully.

If not successfull, please check the errormessage!

To check the newly created image is now available on your hostsystem fire the following command and look for your given imagename
```bash
sudo docker images
```

## Run the container with docker-compose

To start the container the first time execute

```bash
cd /docker/YOURPROJECTNAME
sudo docker compose up -d && sudo docker logs -f postfix-relay-server
```

## Initial Setup explained
If files in foleder YOURPROJECTNAME/data doesn't exist or are 0byte - the initial setup starts automatically.
initial setup only work if all env variables are properly set!

The setup takes care about the config files and creates them properly.
The Setup generates a DKIM pair of private-public key:
The command will generate also 2 DKIM files `${DKIM_SELEKTOR}.private`, your private key, and `${DKIM_SELEKTOR}.txt`, with the DNS record you need to setup.


## Usage
Make sure the container is not directly exposed on the Internet, since it will accept emails from every network interface. The typical setup is to connect it to other Docker containers using some private network.

Watch your Firewall settings!
sample
```bash
sudo ufw allow smtp
```
## Logging
All logfiles are present with
```bash
sudo docker logs -f postfix-relay-server
```
The RSYSLOG module is installed and running.
If you wish to enable "logshipping" - eg. to GrayLog - check the rsyslog.conf in .data/config/rsyslog folder.
Alternate: add in docker-compose.yml file for local mount volume to /var/log/mail.log

## Optional - but highly recommended
Setup SPF to limit who can send emails on behave of your domain. See the references.
Go to your DNS-Provider and create/change the following DNS-Entries
# SPF
Example (limit only the IP that maps to domain example.com to send emails):
```txt
TXT example.com "v=spf1 a -all"
```
# DKIM
Create your DKIM Record with values from created file
```bash
sudo cat /docker/YOURPROJECTNAME/data/config/opendkim/domainkeys/${DKIM_SELEKTOR}.txt 
```

# DMARC
Setup DMARC to limit who can send emails on behave of your domain. Please setup and check SPF and DKIM before DMARC.
```
TXT _dmarc.example.com "v=DMARC1; p=reject; pct=100; adkim=s; aspf=s"
```
Check tool: https://dmarcian.com/dmarc-inspector/

## References
- https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy
- https://www.digitalocean.com/community/tutorials/how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability

## Initial Forked
This is basically forked from https://github.com/davidepedranz/docker-send-only-postfix

## License
See [LICENSE](LICENSE) file.
