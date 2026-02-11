#import "@preview/unofficial-uninsubria-thesis:0.1.0": sourcecode

= Manuale utente

== Compilazione da `buildroot`
Innanzitutto e necessario cloneare la repo git
`git@git.amelchem.com:amel/buildroot.git`
con il comando `git clone git@git.amelchem.com:amel/buildroot.git` opppure
`git clone https://git.amelchem.com/amel/buildroot.git` e fare checkout
nel branch
`Vulcano-papaccioli`.
Successivamente bisogna far partire la compilazione di `buildroot` con il
comando `make`,
che comprende `linux`, `barebox` e tutto cio di necessario per il sistema
embedded.
La prima compilazione puo durare anche 1 ora a causa dei tanti pacchetti
da scaricare
ed installare. Sono necessari all'incirca 20GB di memoria disponibile sul
disco fisso.

== Flashing scheda sdcard
Dopo aver compilato, si popolera la cartella `output` di `buildroot` con i
file necessari.
Dobbiamo copiare bit per bit il file `output/images/sdcard.img` sulla memory
card con il comando
`sudo dd if=output/images/sdcard.img of=/dev/mmcblk0 bs=4M status=progress
conv=fsync`.
Cambia i path e i nomi in base alla tua macchina.

== Embedded
Estrai la scheda sd dal computer ed introducila nella board `Ganador` nello
slot apposito.
Aspetta 1 minuto circa per il sistema che si avvii e si installi (generazione
ssh keys 30 sec circa).
A questo punto abbiamo due opzioni per connetterci: tramite porta seriale o
`ssh`.

=== Porta seriale
Per connetterci tramite la porta seriale, abbiamo bisogno di un adattatore
seriale usb // inserisci qui nome adattatore i think rs322
e di un emulatore di console seriale, come per esemptio `minicom`.
Dopo aver collegato l' usb al computer e i pin dell adattatore come nella
figura seguente lanciamo `minicom` specificando il nome del device,
per esmpio in linux `/dev/ttyUSB0`.

#figure(
  image("/images/serial-pinout.jpg"),
  caption: [Immagine che mostra la connessione dei pin],
) <serial-port-pins>


=== `ssh`
Per connetterci tramite ssh usiamo semplicemente il comando `ssh
root@10.42.0.2`.
La password per `root` e `root`. Per cambiare password e configurazione di
rete dobbiamo modificare `buildroot`.

#figure(
  caption: `git show fc474df54681e9057202aac05b035762825c07f4`,
  sourcecode[```diff
commit fc474df54681e9057202aac05b035762825c07f4
Author: Mattia Papaccioli <mattiapapaccioli@gmail.com>
Date:   Mon Dec 8 14:39:56 2025 +0100

    vulcanoa5_defconfig: change root password

diff --git a/configs/vulcanoa5_defconfig b/configs/vulcanoa5_defconfig
index 7f9b3db1c1..2b66c41777 100644
--- a/configs/vulcanoa5_defconfig
+++ b/configs/vulcanoa5_defconfig
@@ -11,7 +11,7 @@ BR2_CCACHE_INITIAL_SETUP="--max-size=10G"
 BR2_TARGET_GENERIC_HOSTNAME="vulcanoa5"
 BR2_TARGET_GENERIC_PASSWD_SHA512=y
 BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_EUDEV=y
-BR2_TARGET_GENERIC_ROOT_PASSWD="$$6$$IzRpYk0B$$oBTolwsRP7IOx4jxgDuS9lv6NoFt5G/fODQqCVtP/OmJ5L25vcT8H62mWr.gxSihpwTLM.2nXn1zl.tTZyqXN0"
+BR2_TARGET_GENERIC_ROOT_PASSWD="root"
 BR2_ROOTFS_OVERLAY="board/amel/vulcano/fs-overlay"
 BR2_ROOTFS_POST_BUILD_SCRIPT="board/amel/vulcano/post-build-script"
 BR2_ROOTFS_POST_IMAGE_SCRIPT="board/amel/vulcano/post-image-script"
@@ -39,6 +39,7 @@ BR2_PACKAGE_OPENSSH_SANDBOX=y

 BR2_PACKAGE_AMEL_TEMP_CONTROL=y
 BR2_PACKAGE_AMEL_PID=y
+
 BR2_PACKAGE_XORG7=y
 BR2_PACKAGE_XSERVER_XORG_SERVER=y
 BR2_PACKAGE_XAPP_XINIT=y


  ```]


)

#figure(
  caption: `git show 7f0ab83b26eca8b584839a693734d12126465cdc`,
  sourcecode[```diff
commit 7f0ab83b26eca8b584839a693734d12126465cdc
Author: Mattia Papaccioli <92176188+sbOogway@users.noreply.github.com>
Date:   Tue Dec 23 19:55:32 2025 +0100

    package/ifupdown-scripts: adding interface configuration to connect
    to internet

diff --git a/package/ifupdown-scripts/S40network
b/package/ifupdown-scripts/S40network
index 7d23a89120..642c5013ac 100644
--- a/package/ifupdown-scripts/S40network
+++ b/package/ifupdown-scripts/S40network
@@ -26,8 +26,5 @@ case "$1" in
	exit 1
 esac

-ip a a 192.168.8.11/24 dev eth0
-ip link set eth0 up
-
 exit $?

diff --git a/package/ifupdown-scripts/ifupdown-scripts.mk
b/package/ifupdown-scripts/ifupdown-scripts.mk
index 5ef032142c..7397e2d034 100644
--- a/package/ifupdown-scripts/ifupdown-scripts.mk
+++ b/package/ifupdown-scripts/ifupdown-scripts.mk
@@ -14,6 +14,13 @@ define IFUPDOWN_SCRIPTS_LOCALHOST
		echo ; \
		echo "auto lo"; \
		echo "iface lo inet loopback"; \
+		echo ; \
+		echo "auto eth0";  \
+		echo "iface eth0 inet static"; \
+		echo "	  address 10.42.0.2"; \
+		echo "	  netmask 255.255.255.0"; \
+		echo "	  post-up ip route add default via 10.42.0.1"; \
+		echo "	  post-up echo \"nameserver 8.8.8.8\" >
/etc/resolv.conf"; \
	) >> $(TARGET_DIR)/etc/network/interfaces
 endef



  ```]
)

== Inizializzazione ed avviamento
Una volte effettuato l accesso al dispositivo, dobbiamo spostarci nella
cartella `/opt/amel/`. Da qui, possiamo impostare il file `config.env`,
dove sono presenti le variabili di ambiente per impostare il sistema.
Una volta impostate, e possibile effettuare l'inizializzazione avviando
lo script `init.sh`. Esso si occupa di creare i file e le cartelle necessari
per
