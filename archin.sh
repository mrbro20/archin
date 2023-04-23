# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to Mrbro's arch installer script"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
lsblk
echo "Choose drive for Partitioning: /dev/"
read drive
cfdisk /dev/$drive
read -p "Did You Partitioned For Installation? [y/n]" ask
if [[ $ask = n ]] ; then
  cfdisk /dev/$drive
fi

echo "linux partition: /dev/"
read partition
mkfs.ext4 /dev/$partition 
read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]] ; then
  lsblk
  echo "EFI partition: /dev/"
  read efipartition
  mkfs.vfat -F 32 /dev/$efipartition
fi
mount /dev/$partition /mnt
read -p "Do you have cache partition? [y/n]" answer
if [[ $answer = y ]] ; then
  lsblk
  echo "Enter cache partition: /dev/"
  read cachepartition
  mkdir /cache
  mount /dev/$cachepartition /cache
  pacstrap -c /mnt --cachedir=/cache/pkg base base-devel linux-lts linux-firmware
  umount -l /cache
  mount /dev/$cachepartition /mnt/var/cache/pacman/ 
else
  pacstrap /mnt base base-devel linux-lts linux-firmware
fi
genfstab -U /mnt >> /mnt/etc/fstab 
sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh 
chmod +x /mnt/arch_install2.sh 
arch-chroot /mnt ./arch_install2.sh 
exit

#part2
printf '\033c'
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "Enter New Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
echo "Set Root Passwd: "
passwd
pacman --noconfirm -S grub efibootmgr os-prober
lsblk
echo "Enter EFI partition: /dev/" 
read efipartition
mkdir /boot/efi
mount /dev/$efipartition /boot/efi 
read -p "Do you Want to Install GRUB on UEFI? [y/n]" instagrub
if [[ $instagrub = y ]] ; then
  echo "Installing Grub For UEFI Bios"
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$hostname --recheck
else
  echo "Installing Grub For Lagacy Bios"
  grub-install /dev/$efipartition
fi
sudo sed -i "s/^#GRUB_DISABLE_OS_PROBER=false$/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#Customize git
git clone --depth=1 https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
cd Top-5-Bootloader-Themes
chmod +x install.sh
./install.sh
cd ..
rm -rf Top-5-Bootloader-Themes

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
echo "[chaotic-aur]" > /etc/pacman.conf
echo "Include = /etc/pacman.d/chaotic-mirrorlist" > /etc/pacman.conf
echo "  " > /etc/pacman.conf

#Multilib
echo "[multilib]" > /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" > /etc/pacman.conf

pacman -Syu

pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk \
     ttf-jetbrains-mono ttf-joypixels ttf-font-awesome rsync \
     sxiv mpv ffmpeg imagemagick bluez bluez-utils pamixer \
     fzf man-db unclutter xclip maim libconfig xdg-user-dirs \
     zip unzip unrar p7zip xdotool papirus-icon-theme mpd base-devel \
     dosfstools ntfs-3g git sxhkd zsh pipewire pipewire-pulse \
     emacs-nox arc-gtk-theme rsync firefox dash ncmpcpp cowsay \
     xcompmgr libnotify dunst slock jq aria2 dhcpcd connman \
     wpa_supplicant zsh-syntax-highlighting yay \

systemctl enable connman.service 
rm /bin/sh
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo "Enter New Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
echo "Set Passwd for user"
passwd $username
echo "Pre-Installation Finished"
cd /home/$username/
echo "PROMPT='%2~ »%b '" > .zshrc
chown $username:$username .zshrc

ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 

#part3
printf '\033c'
cd $HOME


ln -s ~/.config/shell/profile .zprofile
rm ~/.zshrc ~/.zsh_history
exit
