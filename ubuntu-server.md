# Ubuntu Server 21.04
Starting from a fresh Ubuntu Server 21.04 (non LTS) install for ARM architecture.

## Overclock CPU [3] (optional - use cooler fan)
Edit /boot/config.txt and change the following:
```
over_voltage=4
arm_freq=1850
sudo reboot now
```

## Update the system
```
sudo apt update
sudo apt -y full-upgrade
sudo reboot now
```

## Edit hostname
Edit the following files and reboot
```
sudo nano /etc/hostname
sudo nano /etc/hosts
sudo reboot now
```

## Harden server
### Do some check routines:
- Ensure Only root Has UID of 0
```
awk -F: '($3=="0"){print}' /etc/passwd
```
- Check for Accounts with Empty Passwords
```
cat /etc/shadow | awk -F: '($2==""){print $1}'
```

### Change default user [6]
Create new user and it to sudo and other groups
```
export NEW_USER=feder
sudo adduser $NEW_USER
sudo usermod -a -G adm,dialout,cdrom,floppy,sudo,audio,video,dip,plugdev,games,users,input,netdev,lxd $NEW_USER
sudo reboot now
```
Delete default "ubuntu" user and permission to sudo without password for pi.
```
sudo deluser -remove-home ubuntu
```

## Export variables again
```
export SSH_PORT=22222
```

### Harden' SSH security
Add authorized public SSH keys
```
mkdir /home/$USER/.ssh/
nano /home/$USER/.ssh/authorized_keys
```

Edit `/etc/ssh/sshd_config` with the following [5]
```
Port $SSH_PORT
#AddressFamily any
ListenAddress 0.0.0.0
#ListenAddress ::

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin no               
#StrictModes yes
MaxAuthTries 6
MaxSessions 10

PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
AuthorizedKeysFile      .ssh/authorized_keys .ssh/authorized_keys2

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no                                                                                                                
PermitEmptyPasswords no

UsePAM no
```

Restart SSH service and test the SSH connection with Keys before logging out.
```sudo service sshd restart```

### Install and config a firewall [1]
Uncomplicated FireWall (UFW)
```
sudo apt install -y ufw
```
Config some basic rules
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit from 192.168.0.0/16 to any port $SSH_PORT proto tcp comment 'SSH'
```

Enable the firewall
```
sudo ufw enable
```

### Install Fail2ban
```
sudo apt install -y fail2ban
```
Configure fail2ban as (following)[6]

## Mount a storage device (i.e.: USB)[2]
You can mount your storage device at a specific folder location. It is conventional to do this within the /mnt folder, for example /mnt/mydisk. Note that the folder must be empty.
1. Plug the storage device into a USB port on the Raspberry Pi.
2. List all the disk partitions on the Pi using the following command:
```
lsblk -o UUID,NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,MODEL
```
3. If disk is not formated yet, format disk to ext4
Check following link: [https://superuser.com/questions/643765/creating-ext4-partition-from-console]

4. Create a target folder to be the mount point of the storage device. The mount point name used in this case is mydisk. You can specify a name of your choice:
```
sudo mkdir /mnt/$DISKNAME
```
5. Mount the storage device at the mount point you created:
```
sudo mount /dev/sda1 /mnt/$DISKNAME
```
6. Verify that the storage device is mounted successfully by listing the contents:
```
sudo ls /mnt/$DISKNAME
```
Optional: (move /home or any other folder to the external disk)[7].

### Setting up automatic mounting
1. Get the UUID of the disk partition:
```
blkid
```
2. Find the disk partition from the list and note the UUID. For example, `5C24-1453`.
3. Open the fstab file using a command line editor:
```
sudo nano /etc/fstab
```
4. Add the following line in the fstab file:
```
UUID=5C24-1453 /mnt/mydisk fstype defaults,auto,users,rw,nofail 0 0
```
Replace fstype with the type of your file system, which you found in step 2 of 'Mounting a storage device' above, for example: ntfs.
5. If the filesystem type is FAT or NTFS, add `,umask=000` immediately after nofail - this will allow all users full read/write access to every file on the storage device.


## Install some utilities:
```
sudo apt install -y tldr tree locate logrotate lnav dnsutils libraspberrypi-bin net-tools
```

### Install backups utilities
```
sudo apt install -y borgbackup rsync rclone
```

### Install Docker
See Docker docs. [4]

```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Install Docker Compose
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Alternative, for Raspbian OS:
First install dependencies (and PIP):
```
sudo apt install -y libffi-dev libssl-dev
sudo apt install -y python3-pip
```

Then, install with PIP:
```
sudo pip3 install docker-compose
```

Add non-sudo user to docker group in order to use docker without sudo.
```
sudo usermod -aG docker $USER
```

### Install Git
```
export GIT_USER='Federico'
export GIT_MAIL='me@federicociro.com'
sudo apt install -y git
```
#### Set Global Credentials
Set your username:
```
git config --global user.name $GIT_USER
```

Set your email address: 
```
git config --global user.email $GIT_MAIL
```


#### Connect with GitHub by a SSH key
  1- Generate a SSH key
```
ssh-keygen -t rsa -b 4096 -C $GIT_MAIL
```
  
  2- Initiate the SSH-key agent.
```
eval `ssh-agent -s`
```

  3- Add the SSH key to your SSH-key agent.
```
ssh-add ~/.ssh/github.com
```
  
  4- Add the SSH key to your GitHub account.
  Copy the content of the key and paste in the Github SSH keys section.
```
cat ~/.ssh/github.com.pub
```


## Install Wireguard VPN
Now, install Wireguard
```
sudo apt update
sudo apt install -y wireguard linux-headers
```

Allow firewall rules
```
sudo ufw allow $WG_PORT/udp comment Wireguard
```

Start Wireguard on boot
```
sudo systemctl enable wg-quick@wg0
```


Allow IP forwarding (to allow DNS request in a different subnet)
Edit `/etc/sysctl.conf` and uncomment `net.ipv4.ip_forward=1`. (Alternative recover from backups)

# Install services
## Install a LEMP stack (Linux + Nginx + MariaDB + PHP)
### Install Nginx (webserver)
```
sudo apt install -y nginx certbot python-certbot-nginx python3-certbot-nginx webhook
```

More details in this [tutorial](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-10) and in [Certbot](https://certbot.eff.org/lets-encrypt/debianbuster-nginx).

Recover config files from Backup.

Allow Nginx in the firewall
```
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
```

#### Restore Nginx configurations
Restore from backup `etc/nginx/sites-available` and generate new SSL certificates for each site.

### Install Maria DB (SQL server)
```
sudo apt install -y mariadb-server
```

Configurar db root user and answer "Y" to all the questions
```
sudo mysql_secure_installation
```

####  Restore Mysql databases
To recover backups, always do it as `root` and with `cp -rp`. Only neccesary files. Watch out for `/etc/sudoers` and `/etc/passwd` specially. Don't override them.
Restore mysqldump file (.sql) from backup (see `var/lib/mysql/backups`).
Uncompress backup and:
```
gzip -dk db.gz
```

Restore all databases
```
sudo mysql -u root < db.sql
```

### Install PHP and some modules
```
sudo apt install -y php-fpm php-mysql php-bcmath php-gmp php-imagick
```

Disable "open_basedir" for PHP FPM:

```
export PHP_VERSION=$(php -r "echo PHP_VERSION;" | grep --only-matching --perl-regexp "7.\d+")
sudo nano /etc/php/$PHP_VERSION/fpm/php.ini
```
Set ```open_basedir = none```

```
sudo service php$PHP_VERSION-fpm restart
```

#### Install phpMyAdmin
```
sudo apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl php-mbstring
```

## Install Pi-Hole
### Install and configure the [prerequisites](https://docs.pi-hole.net/guides/nginx-configuration/)
```
sudo apt install -y nginx php-fpm php-cgi php-xml php-sqlite3 php-intl apache2-utils
```

```
wget -O basic-install.sh https://install.pi-hole.net
sudo bash basic-install.sh
sudo usermod -aG pihole www-data
```

Allow ports in firewall
```
sudo ufw allow from 192.168.0.0/16 to any port 53 proto tcp comment 'DNS Pi-Hole'
sudo ufw allow from 192.168.0.0/16 to any port 53 proto udp comment 'DNS Pi-Hole'
```

## Install Unbound
```
sudo apt install -y unbound
```

See [Pi-Hole Docs](https://docs.pi-hole.net/guides/unbound/) to config Unbound and Pi-Hole. (Alternative recover from backups)


## Sources
[1]:https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands
[2]:https://www.raspberrypi.org/documentation/configuration/external-storage.md
[3]:https://friendsoflittleyus.nl/overclocking-raspberry-pi4-on-ubuntu-20-10/
[4]:https://docs.docker.com/engine/install/debian/
[5]:https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server
[6]:https://www.raspberrypi.org/documentation/configuration/security.md
[7]:https://www.digitalocean.com/community/tutorials/how-fail2ban-works-to-protect-services-on-a-linux-server
[8]:https://unix.stackexchange.com/questions/131311/moving-var-home-to-separate-partition
[9]:https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
[10]:https://www.nuharborsecurity.com/ubuntu-server-hardening-guide-2/