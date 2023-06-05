# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true

#Partitioning Disk
echo " "
echo -e "\e[32m# SELECT DISK FOR PARTITONING #\e[0m"
echo " "
lsblk 
echo " "
read -p "Enter disk for Partitioning: /dev/" disk
cfdisk /dev/$disk
echo " "
echo -e "\e[31m# \e[33mCHECK PARTITIONS CAREFULLY #\e[31m#\e[0m"
echo " "
lsblk -f
echo " "
read -p "Partitioning Completed? [y/n] " ask
if [[ $ask = n ]] ; then
  cfdisk /dev/$disk
fi

#Mounting Partions
echo " "
echo -e "\e[32m# MOUNT LINUX PARTITION #\e[0m"
echo " "
lsblk 
echo " "
read -p "Linux partition: /dev/" partition
echo " "
read -p "Erase partition? [y/n] " ext4par
if [[ $ext4par = y ]] ; then
  mkfs.ext4 /dev/$partition
fi
mount /dev/$partition /mnt
echo " "
echo -e "\e[32m# MOUNT BOOT PARTITION #\e[0m"
echo " "
read -p "Use efi partition? [y/n] " answer
if [[ $answer = y ]] ; then
  echo " "
  lsblk 
  echo " "
  read -p "EFI partition: /dev/" efipartition
  mkfs.vfat -F 32 /dev/$efipartition
  mkdir /mnt/boot
  mkdir /mnt/boot/efi
  mount /dev/$efipartition /mnt/boot/efi
fi

#Installing ArchLinux
echo " "
echo -e "\e[32m#######################\e[0m"
echo -e "\e[32m# INSTALLING PACKAGES #\e[0m"
echo -e "\e[32m#######################\e[0m"
echo " "
read -p "Do you have cache partition? [y/n] " answer
if [[ $answer = y ]] ; then
  echo " "
  lsblk 
  echo " "
  read -p "Cache partition: /dev/" cachepartition
  mkdir /cache
  mount /dev/$cachepartition /cache
  pacstrap -c /mnt --cachedir=/cache/pkg base base-devel linux-lts linux-firmware archlinux-keyring
  umount -l /cache
  mount /dev/$cachepartition /mnt/var/cache/pacman/ 
else
  pacstrap /mnt base base-devel linux-lts linux-firmware archlinux-keyring
fi
genfstab -U /mnt >> /mnt/etc/fstab 
sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh 
chmod +x /mnt/arch_install2.sh 
arch-chroot /mnt ./arch_install2.sh 
exit

#part2
printf '\033c'
pacman -S --noconfirm sed git

#Setting Up System
echo " "
echo -e "\e[32m#####################\e[0m"
echo -e "\e[32m# SETTING UP SYSTEM #\e[0m"
echo -e "\e[32m#####################\e[0m"
echo " "
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo " "
echo -e "\e[32m# SYSTEM NAME #\e[0m"
echo " "
read -p "Enter Hostname: " hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
echo " "
echo -e "\e[32m# SUDO PASSWD #\e[0m"
echo " "
passwd

#Installing GRUB
echo " "
pacman --noconfirm -S grub efibootmgr os-prober
echo " "
echo -e "\e[32m# GRUB Instalation #\e[0m"
echo " "
read -p "Install GRUB 1-UEFI or 2-Lagacy? [1/2] " instagrub
if [[ $instagrub = 1 ]] ; then
  echo " "
  echo -e "\e[32m# Installing Grub For UEFI Bios #\e[0m"
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$hostname --recheck
elif [[ $instagrub = 2 ]] ; then
  echo "\e[32m# Installing Grub For Lagacy Bios #\e[0m"
  echo " "
  lsblk
  echo " "
  read -p "lagacy Disk: /dev/" grubins
  grub-install /dev/$grubins
fi
sudo sed -i "s/^#GRUB_DISABLE_OS_PROBER=false$/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
echo " "
grub-mkconfig -o /boot/grub/grub.cfg
echo  " "

#Customize git
git clone --depth=1 https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
cd Top-5-Bootloader-Themes
chmod +x install.sh
./install.sh
cd ..
rm -rf Top-5-Bootloader-Themes

#Multilib
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
echo " " >> /etc/pacman.conf

#Blackarch mirror Installation
curl -O https://blackarch.org/strap.sh
echo 5ea40d49ecd14c2e024deecf90605426db97ea0c strap.sh | sha1sum -c
chmod +x strap.sh
./strap.sh
rm -rf strap.sh

#Chaotic-Aur
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "[chaotic-aur]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
echo " " >> /etc/pacman.conf

#Installing Packages
pacman -Sy --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk \
     ttf-jetbrains-mono ttf-joypixels ttf-font-awesome rsync \
     sxiv mpv ffmpeg imagemagick bluez bluez-utils pamixer waybar \
     fzf man-db libconfig xdg-user-dirs sddm dunst connman nano \
     zip unzip unrar p7zip xdotool papirus-icon-theme mpd neofetch yay \
     dosfstools ntfs-3g git sxhkd zsh pipewire pipewire-pulse base-devel \
     emacs-nox firefox dash ncmpcpp cowsay vim wpa_supplicant btop gnome-browser-connector \
     slurp polkit-gnome gvfs lxappearance networkmanager network-manager-applet \
     gnome-terminal gdm eog evince gnome-control-center gnome-disk-utility nautilus \

#Enabling Services And Adding User
read -p "Sys setup 1-Connman 2-nmctl? [1/2] " netmgr
if [[ $netmgr = 1 ]] ; then
  systemctl enable connman.service
elif [[ $netmgr = 2 ]] ; then
  systemctl enable NetworkManger.service
fi
echo " "

read -p "Sys setup 1-sddm 2-gdm? [1/2] " wmgr
if [[ $wmgr = 1 ]] ; then
  systemctl enable sddm.service
elif [[ $wmgr = 2 ]] ; then
  systemctl enable gdm.service
fi

rm /bin/sh
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo " "
echo -e "\e[32m# SETTING UP USER #\e[0m"
echo " "
read -p "Enter Username: " username
useradd -m -G wheel -s /bin/zsh $username
echo " "
echo -e "\e[32m# USER PASSWD #\e[0m"
echo " "
passwd $username
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 

#part3
printf '\033c'
sudo rm -rf /arch_install2.sh
cd $HOME

#Setting Up Dots
echo "neofetch" >> .zshrc
echo "PROMPT='%2~ »%b '" >> .zshrc
chown $username:$username .zshrc

yay -S --noconfirm hyprland sddm-sugar-candy code

echo " "
echo -e "\e[32m#########################\e[0m"
echo -e "\e[32m# INSTALATION COMPLETED #\e[0m"
echo -e "\e[32m#########################\e[0m"
echo " "

exit
