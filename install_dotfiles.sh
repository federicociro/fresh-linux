# /bin/bash

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo "This script will copy system configuration files and install dotfiles  in both non-root and root users"
echo "Type the non-root user"
read non_root

echo "Linking non-root files"
ln -s /home/$non_root/git/fresh-linux/dotfiles/server/not-root/.bash_aliases /home/$non_root/.bash_aliases
rm -f /home/$non_root/.bashrc
ln -s /home/$non_root/git/fresh-linux/dotfiles/server/not-root/.bashrc /home/$non_root/.bashrc
rm -f /home/$non_root/.bash_profile
ln -s /home/$non_root/git/fresh-linux/dotfiles/server/not-root/.bash_profile /home/$non_root/.bash_profile
ln -s /home/$non_root/git/fresh-linux/dotfiles/server/not-root/.nanorc /home/$non_root/.nanorc


echo "Linking root files"
sudo ln -s /home/$non_root/git/fresh-linux/dotfiles/server/not-root/.bash_aliases /root/.bash_aliases
sudo rm -f /root/.bashrc
sudo ln -s /home/$non_root/git/fresh-linux/dotfiles/server/root/.bashrc /root/.bashrc
sudo rm -f /root/.bash_profile
sudo ln -s /home/$non_root/.bash_profile /root/.bash_profile

echo "Copying system configuration files"
sudo ln -s /root/config/etc/asound.conf /etc/asound.conf
sudo ln -s /root/config/etc/mpd.conf /etc/mpd.conf
sudo mkdir /etc/spotifyd
sudo ln -s /root/config/etc/spotifyd/* /etc/spotifyd
sudo ln -s /root/config/etc/systemd/system/* /etc/systemd/system
sudo ln -s /root/config/etc/logrotate.d/* /etc/logrotate.d
sudo ln -s /root/config/var/spool/cron/crontabs/root /var/spool/cron/crontabs/
sudo ln -s /root/config/etc/wireguard/wg0.conf /etc/wireguard
mkdir /home/$non_root/.config/mpd
sudo ln -s /root/config/home/user/.config/mpd/mpd.conf /home/feder/.config/mpd/
