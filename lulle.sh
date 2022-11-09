#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------
#github-action genshdoc
#
# @file Preinstall
# @brief Contains the steps necessary to configure and pacstrap the install to selected drive. 
echo -ne "
-------------------------------------------------------------------------
   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Setting up mirrors for optimal download
"
mount -o remount,size=5G /run/archiso/cowspace
pacman -Syy
pacman -S btrfs-progs reflector rsync --noconfirm
reflector -a 48 -c SE -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy

parted -s /dev/nvme0n1 mklabel gpt
parted -a optimal -s /dev/nvme0n1 mkpart primary fat32 1MiB 750MiB
parted -s /dev/nvme0n1 set 1 esp on
parted -a optimal -s /dev/nvme0n1 mkpart primary btrfs 750MiB 100%
mkfs.btrfs -f -L ArchRoot /dev/nvme0n1p2
mkfs.vfat -F 32 /dev/nvme0n1p1

mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60 /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@opt
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@.snapshots
umount /mnt
mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60,subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{var,opt,tmp,srv,.snapshots}
mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60,subvol=@var /dev/nvme0n1p2 /mnt/var
mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60,subvol=@opt /dev/nvme0n1p2 /mnt/opt
mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60,subvol=@tmp /dev/nvme0n1p2 /mnt/tmp
mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60,subvol=@srv /dev/nvme0n1p2 /mnt/srv
mount -o compress-force=lzo,space_cache=v2,noatime,discard=async,autodefrag,ssd,commit=60,subvol=@.snapshots /dev/nvme0n1p2 /mnt/.snapshots
mkdir -p /mnt/boot/efi
mount -o noatime /dev/nvme0n1p1 /mnt/boot/efi

pacstrap /mnt base base-devel linux linux-firmware linux-headers amd-ucode btrfs-progs lzo lz4 dhcpcd nano --noconfirm

genfstab -L /mnt >> /mnt/etc/fstab

###PACMAN CONFIG###
#Enable some options in pacman.conf
sed "s,\#\VerbosePkgLists,VerbosePkgLists,g" -i /mnt/etc/pacman.conf
sed "s,\#\ParallelDownloads = 5,ParallelDownloads = 5,g" -i /mnt/etc/pacman.conf
sed "s,\#\Color,Color,g" -i /mnt/etc/pacman.conf

sed "s,BINARIES=(),BINARIES=(btrfs),g" -i /mnt/etc/mkinitcpio.conf
sed "s,\#\COMPRESSION=\"lz4\",COMPRESSION=\"lz4\",g" -i /mnt/etc/mkinitcpio.conf

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
arch-chroot /mnt locale-gen && arch-chroot /mnt hwclock --systohc
echo "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
echo "KEYMAP=sv-latin1" >> /mnt/etc/vconsole.conf
echo "PiEBoY" >> /mnt/etc/hostname
arch-chroot /mnt pacman -S wget nano btrfs-progs
arch-chroot /mnt pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
arch-chroot /mnt pacman-key --lsign-key F3B607488DB35A47
arch-chroot /mnt pacman -U --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-2-1-any.pkg.tar.zst' 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-13-1-any.pkg.tar.zst' 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-13-1-any.pkg.tar.zst' 'https://mirror.cachyos.org/repo/x86_64/cachyos/pacman-6.0.2-9-x86_64.pkg.tar.zst'
arch-chroot /mnt wget -N https://raw.githubusercontent.com/Lukas0120/lulz/main/etc/pacman.d/endeavouros-mirrorlist -O /etc/pacman.d/endeavouros-mirrorlist
arch-chroot /mnt wget -N https://raw.githubusercontent.com/Lukas0120/lulz/main/etc/pacman.conf -O /etc/pacman.conf
arch-chroot /mnt wget -N https://raw.githubusercontent.com/Lukas0120/lulz/main/etc/makepkg.conf -O /etc/makepkg.conf

arch-chroot /mnt pacman -Syy
arch-chroot /mnt pacman -Syu --noconfirm
arch-chroot /mnt pacman -S cmake extra-cmake-modules ninja gperftools python-setuptools bc bison flex jemalloc lzo lz4 zstd micro musl meson boost boost-libs cpupower llvm llvm-libs compiler-rt clang lld lldb polly libunwind openmp libc++ libc++abi htop neofetch paru yay cpio zsh zsh-completions nano-syntax-highlighting xorg-mkfontscale xorg-fonts-encodings xorg-font-util xorg-server xorg-server-devel xorg-xinit imagemagick w3m wget git curl ananicy-cpp-git cachyos-ananicy-rules cachyos-rate-mirrors reflector rsync zram-generator efibootmgr grub dkms nvidia-dkms nvidia-utils nvidia-settings mesa irqbalance --noconfirm --overwrite '*'

arch-chroot /mnt systemctl enable dhcpcd ananicy-cpp irqbalance

echo "blacklist k10temp" > /mnt/etc/modprobe.d/disable-k10temp.conf
echo "zenpower" > /mnt/etc/modules-load.d/zenpower.conf
sed "s,\#\ set linenumbers, set linenumbers,g" -i /mnt/etc/nanorc
sed "s,\#\ set positionlog, set positionlog,g" -i /mnt/etc/nanorc
sed "s,\#\ set constantshow, set constantshow,g" -i /mnt/etc/nanorc
sed "s,\#\ set titlecolor bold\,white\,blue, set titlecolor bold\,lightwhite,g" -i /mnt/etc/nanorc
sed "s,\#\ set promptcolor lightwhite\,grey, set promptcolor lightwhite\,lightblack,g" -i /mnt/etc/nanorc
sed "s,\#\ set errorcolor bold\,white\,red, set errorcolor bold\,lightwhite\,red,g" -i /mnt/etc/nanorc
sed "s,\#\ set spotlightcolor black\,lightyellow, set spotlightcolor black\,lime,g" -i /mnt/etc/nanorc
sed "s,\#\ set selectedcolor lightwhite\,magenta, set selectedcolor lightwhite\,magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set stripecolor \,yellow, set stripecolor yellow,g" -i /mnt/etc/nanorc
sed "s,\#\ set statuscolor bold\,white\,green, set statuscolor bold\,white,g" -i /mnt/etc/nanorc
sed "s,\#\ set scrollercolor cyan, set scrollercolor cyan,g" -i /mnt/etc/nanorc
sed "s,\#\ set numbercolor cyan, set numbercolor magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set keycolor cyan, set keycolor cyan,g" -i /mnt/etc/nanorc
sed "s,\#\ set functioncolor green, set functioncolor green,g" -i /mnt/etc/nanorc
sed "s,\#\ include \"/usr/share/nano/\*.nanorc\", include \"/usr/share/nano/\*.nanorc\",g" -i /mnt/etc/nanorc
echo "include /usr/share/nano-syntax-highlighting/*.nanorc" >> /mnt/etc/nanorc

cat << EOF >> /mnt/etc/sudoers
lulle ALL=(ALL:ALL) NOPASSWD: ALL
EOF

###FONTS###
#Set fonts
arch-chroot /mnt ln -s /usr/share/fontconfig/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /usr/share/fontconfig/conf.avail/10-hinting-full.conf /etc/fonts/conf.d
sed "s,\#export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",g" -i /mnt/etc/profile.d/freetype2.sh

arch-chroot /mnt pacman -S snapper grub-btrfs btrfs-assistant-git --noconfirm --overwrite '*'
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=PiEBoY --efi-directory=/boot/efi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt useradd -m -G wheel lulle
TMPFILE=$(mktemp)
echo "lulle":"pie" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
echo "root":"pie" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"

arch-chroot /mnt wget -N https://mirror.cachyos.org/llvm-bolt.tar.zst -O /home/lulle/llvm-bolt.tar.zst
arch-chroot /mnt unzstd /home/lulle/llvm-bolt.tar.zst
arch-chroot /mnt tar xvf /home/lulle/llvm-bolt.tar -C /home/lulle/
arch-chroot /mnt mv /home/lulle/llvm /home/lulle/clang
arch-chroot /mnt chown -hR lulle /home/lulle/clang
arch-chroot /mnt rm /home/lulle/llvm-bolt.tar.zst
arch-chroot /mnt rm /home/lulle/llvm-bolt.tar

arch-chroot /mnt git clone https://github.com/Lukas0120/lulz.git /home/lulle/lulz
arch-chroot /mnt chown -hR lulle /home/lulle/lulz


echo "export PATH=/home/lulle/clang/bin:${PATH}"  >>  /mnt/home/lulle/.bashrc
arch-chroot /mnt chown lulle /home/lulle/.bashrc
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
