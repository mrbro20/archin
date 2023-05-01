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
read -p "Enter Root partition: /dev/" partition
mkfs.ext4 /dev/$partition 
echo " "
echo -e "\e[32m# MOUNT BOOT PARTITION #\e[0m"
echo " "
read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]] ; then
  echo " "
  lsblk 
  echo " "
  read -p "EFI partition: /dev/" efipartition
  mkfs.vfat -F 32 /dev/$efipartition
fi
mount /dev/$partition /mnt
clear

#Installing ArchLinux
echo -e "\e[32m#######################\e[0m"
echo -e "\e[32m# INSTALLING PACKAGES #\e[0m"
echo -e "\e[32m#######################\e[0m"
echo " "
read -p "Do you have cache partition? [y/n]" answer
if [[ $answer = y ]] ; then
  echo " "
  lsblk 
  echo " "
  read -p "Enter cache partition: /dev/" cachepartition
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
clear

#Setting Up System
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
read -p "Enter Hostname: " hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
echo " "
echo -e "\e[32m# SUDO PASSWD #\e[0m"
passwd

#Installing GRUB
echo " "
pacman --noconfirm -S grub efibootmgr os-prober
echo " "
echo -e "\e[32m# Mounting Partition for GRUB Instalation #\e[0m"
echo " "
lsblk 
echo " "
read -p "Enter EFI partition: /dev/" efipartition
mkdir /boot/efi
mount /dev/$efipartition /boot/efi 
echo " "
echo -e "\e[32m# GRUB Instalation #\e[0m"
echo " "
read -p "Install GRUB 1-UEFI or 2-Lagacy? [1/2] " instagrub
if [[ $instagrub = 1 ]] ; then
  echo " "
  echo -e "\e[32mInstalling Grub For UEFI Bios\e[0m"
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$hostname --recheck
elif [[ $instagrub = 2 ]] ; then
  echo "\e[32mInstalling Grub For Lagacy Bios\e[0m"
  grub-install /dev/$efipartition
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

pacman -Syyu --noconfirm

#Installing Packages
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk \
     ttf-jetbrains-mono ttf-joypixels ttf-font-awesome rsync \
     sxiv mpv ffmpeg imagemagick bluez bluez-utils pamixer waybar \
     fzf man-db libconfig xdg-user-dirs sddm dunst connman nano \
     zip unzip unrar p7zip xdotool papirus-icon-theme mpd swww yay \
     dosfstools ntfs-3g git sxhkd zsh pipewire pipewire-pulse base-devel \
     emacs-nox firefox dash ncmpcpp cowsay vim wpa_supplicant btop \
     slurp polkit-gnome gvfs lxappearance \

#Enabling Services And Adding User
systemctl enable connman.service 
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
passwd $username
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 

#part3
printf '\033c'
cd $HOME

#Setting Up Dots
echo "PROMPT='%2~ »%b '" >> .zshrc
chown $username:$username .zshrc

#yay Installation
yay -S --noconfirm hyprland-bin sddm-sugar-candy

#Gnome Installation


clear
echo -e "\e[32m#########################\e[0m"
echo -e "\e[32m# INSTALATION COMPLETED #\e[0m"
echo -e "\e[32m#########################\e[0m"
echo " "

exit
