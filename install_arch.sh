#!/bin/bash
purpleClaro="\033[1;35m"
azulClaro="\033[1;34m"
purple="\033[0;35m"
vermelho="\033[0;31m"
verde="\033[0;32m"
CHROOT="arch-chroot /mnt/"

#
# $username = username da conta
# $user_password = senha da conta
# $root_password = senha do root
# $host_name = nome do host do arch
#






logo() {
  local text="${1:?}"
  clear
  echo -e "$purple
  ████████╗██╗  ██╗███████╗    ██╗   ██╗ ██████╗ ██╗██████╗ ███████╗██╗  ██╗
  ╚══██╔══╝██║  ██║██╔════╝    ██║   ██║██╔═══██╗██║██╔══██╗╚══███╔╝██║ ██╔╝
     ██║   ███████║█████╗      ██║   ██║██║   ██║██║██║  ██║  ███╔╝ █████╔╝ 
     ██║   ██╔══██║██╔══╝      ╚██╗ ██╔╝██║   ██║██║██║  ██║ ███╔╝  ██╔═██╗ 
     ██║   ██║  ██║███████╗     ╚████╔╝ ╚██████╔╝██║██████╔╝███████╗██║  ██╗
     ╚═╝   ╚═╝  ╚═╝╚══════╝      ╚═══╝   ╚═════╝ ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝
  ${azulClaro}
  \n\n======[ ${text} ]=======\n\n"
  sleep 2
}

# 1
get_info(){
  logo "Informações necessárias"
  while true 
    do 
      read -rp "Nickname da conta:  " username
      echo 
      if [[ "${username}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
				then 
					break
			fi
      echo -e "$vermelho   Nome de usuario invalido, use somente letras minusculas"
    done
  while true
  do
    read -rsp "Senha do(a) usuario(a) $username :" user_password
    echo 
    echo
    read -rsp "Confirme a senha: " user_password_conf
    echo 
    echo
      if [ "$user_password" != "$user_password_conf" ]; then 
        echo -e "$vermelho  Sua senha não coincide! tente novamente"
      fi
    echo -e "$verde Senha correta! $azulClaro"
    break
  done
  while true
    read -rsp "Senha do ROOT: " root_password
    echo 
    echo
    read -rsp "Confirme a senha ROOT: " root_password_conf
    echo
    echo
    do
      if [ "$root_password" != "$root_password_conf" ]; then
        echo -e "$vermelho Senha não coincide! tente novamente"
      fi
    echo -e "$verde Senha correta! $azulClaro"
    break
  done
  while true
    read -rp "Insira o nome da maquina: " host_name
  do 
    if [[ "${host_name}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
				then 
					break 
			fi
    echo -e "$vermelho Nome da maquina é invalido! tente novamente"
    done
}


# 2
hardware_info(){
  logo "pegando informações do hardware"
  lsblk -d -e 7,11 -o NAME,SIZE,TYPE,MODEL
		echo -e "$azulClaro------------------------------"
		echo
    PS3="Escolha o disco(não é partição) que o arch linux sera instalado: "
	select drive in $(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk') 
		do
			if [ "$drive" ]; then
				break
			fi
		done
  logo "Criando as partições"
  sleep 10
  echo -e "$purple Crie uma partição EFI de 512mb, RAIZ e uma HOME"
  cfdisk "${drive}"
	clear
}

format_partitions() {
  lsblk "${drive}" -I 8 -o NAME,SIZE,FSTYPE,PARTTYPENAME
		echo -e "$azulClaro------------------------------"
		echo
			
			PS3="escolha a partição raiz que acabou de criar: "
	select partroot in $(fdisk -l "${drive}" | grep Linux | cut -d" " -f1) 
		do
			if [ "$partroot" ]; then
				printf " \n Formatando a partição RAIZ %s\n Espere..\n" "${partroot}"
				sleep 2
				mkfs.ext4 -L Arch "${partroot}" >/dev/null 2>&1
				mount "${partroot}" /mnt
				sleep 2
				break
			fi
		done

  logo "Escolha a partição EFI"
  lsblk "${drive}" -I 8 -o NAME,SIZE,FSTYPE,PARTTYPENAME
  	echo -e "$azulClaro------------------------------"
	echo

  PS3="Escolha a partição de boot: "
  select partboot in $(fdisk -l "${drive}" | grep EFI | cut -d" " -f1)
  do
    if [ "$partboot" ]; then
      printf " \n Formatando a partição de boot %s\n Espere...\n" "${partboot}"
      sleep 2
      mkfs.vfat "${partboot}" >/dev/null 2>&1
      mkdir -p /mnt/boot/efi
      mount "${partboot}" /mnt/boot/efi
      sleep 2
      break
    fi
  done


    logo "Escolha a partição HOME"
  lsblk "${drive}" -I 8 -o NAME,SIZE,FSTYPE,PARTTYPENAME
  echo -e "$azulClaro------------------------------"
	echo

  PS3="Escolha a partição de home: "
  select parthome in $(fdisk -l "${drive}" | grep Linux | cut -d" " -f1)
  do
    if [ "$partboot" ]; then
      printf " \n Formatando a partição de HOME %s\n Espere...\n" "${parthome}"
      sleep 2
      mkfs.ext4 "${parthome}" >/dev/null 2>&1
      mkdir -p /mnt/home
      mount "${parthome}" /mnt/home
      sleep 2
      break
    fi
  done
}

# 3
swap_part(){
  logo "Configurando a SWAP"

			PS3="Escolha a partição SWAP: "
	select swappart in $(fdisk -l | grep -E "swap" | cut -d" " -f1) "Não quero swap" "Criar arquivo swap"
		do
			if [ "$swappart" = "Criar arquivo swap" ]; then
				
				printf "\n Criando o arquivo swap...\n"
				sleep 2
				fallocate -l 4096M /mnt/swapfile
				chmod 600 /mnt/swapfile
				mkswap -L SWAP /mnt/swapfile >/dev/null
				printf " Montando Swap, espere...\n"
				swapon /mnt/swapfile
				sleep 2
				okie
				break
					
			elif [ "$swappart" = "Não quero swap" ]; then
					
				break
					
			elif [ "$swappart" ]; then
				
				echo
				printf " \nFormatando a swap, espere..\n"
				sleep 2
				mkswap -L SWAP "${swappart}" >/dev/null 2>&1
				printf " Montando Swap, espere...\n"
				swapon "${swappart}"
				sleep 2
				okie
				break
			fi
		done
}

# 4 
confirm_info() {
  echo -e "--------------------"
  echo -e  " Username:  ${purple} $username ${azulClaro}"
  echo -e  " Hostname:  ${purple} $host_name ${azulClaro}"
	
	if [ "$swappart" = "Criar arquivo swap" ]; then
		echo -e  " Swap:      ${purpleClaro}Sim criar arquivo swap de 4G${azulClaro}"
	elif [ "$swappart" = "Não quero swap" ]; then
		echo -e  " Swap:    ${purpleClaro} Não quero swap${azulClaro}"
	elif [ "$swappart" ]; then
		echo -e  " Swap:      Sim em ${purpleClaro} ${swappart}" 
	fi
		
		echo		
		echo -e  "Arch Linux será instalado no disco ${purpleClaro} ${drive} na partição ${purpleClaro} ${partroot}"
		
	while true; do
			read -rp " Deseja continuar? [s/N]: " sn
		case $sn in
			[Ss]* ) break;;
			[Nn]* ) exit;;
			* ) printf " Error: somente escrever 's' ou 'n'\n\n";;
		esac
	done
}
# 5
base_system() {
  logo "Instalando sistema base"

	sed -i 's/#Color/Color/; s/#ParallelDownloads = 5/ParallelDownloads = 5/; /^ParallelDownloads =/a ILoveCandy' /etc/pacman.conf
	pacstrap /mnt \
	         base \
	         base-devel \
	         linux-zen \
	         linux-firmware \
	         dhcpcd \
	         intel-ucode \
	         mkinitcpio \
	         reflector \
	         zsh \
	         git \
           grub \
           efibootmgr \
           efivar \
           curl 
  logo "Gerando o FSTAB"

		genfstab -U /mnt >> /mnt/etc/fstab
}
# 6
timezone(){
  logo "Configurando Timezone e Locales"
	$CHROOT ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	$CHROOT hwclock --systohc
	echo
	echo "pt_BR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	$CHROOT locale-gen
	echo "LANG=pt_BR.UTF-8" >> /mnt/etc/locale.conf
	echo "KEYMAP=br-abnt2" >> /mnt/etc/vconsole.conf
	export LANG=pt_BR.UTF-8
}
# 7
setup_internet(){
  logo "Configurando Internet"

	echo "${host_name}" >> /mnt/etc/hostname
	cat >> /mnt/etc/hosts <<- EOL		
		127.0.0.1   localhost
		::1         localhost
		127.0.1.1   ${host_name}.localdomain ${host_name}
	EOL
}
# 8 
setup_user() {
  logo "Usuario e senhas"

	echo "root:$root_password" | $CHROOT chpasswd
	$CHROOT useradd -m -g users -G wheel -s /usr/bin/zsh "${username}"
	echo "$username:$user_password" | $CHROOT chpasswd
	sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/; /^root ALL=(ALL:ALL) ALL/a '"${username}"' ALL=(ALL:ALL) ALL' /mnt/etc/sudoers
	echo "Defaults insults" >> /mnt/etc/sudoers
	echo  -e "${azulClaro} root: ${purpleClaro} ${root_password}" 
	echo -e "${azulClaro} ${username}: ${purpleClaro} ${user_password}"
}
# 9
mirrors(){
  logo "Atualizando os espelhos para uma nova instalação do arch"

	$CHROOT reflector --verbose --latest 5 --country 'Brazil' --age 6 --sort rate --save /etc/pacman.d/mirrorlist >/dev/null 2>&1
	$CHROOT pacman -Syy
}
#10 
finish(){

  logo "Instalando o grub"
  $CHROOT grub-install --target=x86_64-efi --efi-directory=/boot/efi/ --bootloader-id=Arch 
  sleep 2
  $CHROOT grub-mkconfig -o /boot/grub/grub.cfg

	logo "Editando pacman.conf e activando downloads paralelos, color e o easter egg ILoveCandy"
	sed -i 's/#Color/Color/; s/#ParallelDownloads = 5/ParallelDownloads = 5/; /^ParallelDownloads =/a ILoveCandy' /mnt/etc/pacman.conf
	logo "Desabilitando Journal logs.."
	sed -i 's/#Storage=auto/Storage=none/' /mnt/etc/systemd/journald.conf
	
    
  logo "Desabilitando modulos do kernel desnecessarios"
	cat >> /mnt/etc/modprobe.d/blacklist.conf <<- EOL
		blacklist iTCO_wdt
		blacklist mousedev
		blacklist mac_hid
		blacklist uvcvideo
	EOL
	
		
	$CHROOT pacman -S \
					  mesa-amber xorg-server xf86-video-intel xorg-xinput xorg-xrdb xorg-xsetroot xorg-xwininfo xorg-xkill \
					  --noconfirm
					  	
	$CHROOT pacman -S \
					  pipewire pipewire-pulse \
					  --noconfirm

  logo "Instalando codecs multimedia e utilidades"

	$CHROOT pacman -S \
                      ffmpeg ffmpegthumbnailer aom libde265 x265 x264 libmpeg2 xvidcore libtheora libvpx sdl \
                      jasper openjpeg2 libwebp webp-pixbuf-loader \
                      unarchiver lha lrzip lzip p7zip lbzip2 arj lzop cpio unrar unzip zip unarj xdg-utils \
                      --noconfirm

  logo "Instalando suporte para montar volumes e dispositivos multimedia extras"

	$CHROOT pacman -S \
					  libmtp gvfs-nfs gvfs gvfs-mtp \
					  dosfstools usbutils net-tools \
					  xdg-user-dirs gtk-engine-murrine \
					  --noconfirm

logo "Instalando a interface GNOME minimal"
	$CHROOT pacman -S \
  					xorg-server \ 
					xorg-xinit \
					xf86-input-synaptics \
					gnome-shell nautilus \
					gnome-terminal guake \
					gnome-tweak-tool \
					gnome-control-center \
					xdg-user-dirs \
					gdm networkmanager \
					gnome-keyring
  logo "Rice theme download"
  $CHROOT curl https://raw.githubusercontent.com/TheV0idxz/dotfiles/master/RiceInstaller -o /home/$username/RiceInstaller

  

   


}


get_info
hardware_info
format_partitions
grub_part
swap_part
confirm_info
base_system
timezone
setup_internet
setup_user
mirrors
finish 
