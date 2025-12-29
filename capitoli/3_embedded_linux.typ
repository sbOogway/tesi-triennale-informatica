#import "@local/uninsubria-thesis:0.1.0": sourcecode

= Embedded Linux

== Hardware

La scheda utilizzata per il sistema embedded è sviluppata da AMEL e comprende:

- una host-board Ganador (rev. 4) che integra:
  - una memoria SD utilizzata come disco fisso;
  - un'interfaccia Ethernet;
  - un'interfaccia seriale;
  - un display touchscreen.

- un system-on-module Vulcano-A5 che integra:
  - una CPU Atmel ARM9 AT91SAM9X35 @ 400MHz;
  - 128 MB DDR2 SDRAM;
  - 256 MB NAND Flash;
  - SODIMM200 interface;
  - 10/100 Mbps Ethernet MAC Controller;
  - 2x USB 2.0 Host, 1x USB 2.0 Host/Device;
  - 3x USARTs;
  - TFT LCD Controller with TTL / LVDS support.


== Costruzione del sistema

Per orchestrare il sistema è stato utilizzato Linux @linux. È stato creato un
kernel personalizzato con soli i moduli essenziali per il funzionamento,
data la limitatezza delle risorse hardware. Lo strumento utilizzato per
completare l'opera è Buildroot @buildroot, che consiste essenzialmente in
una serie di Makefile per installare e cross-compilare tutte le librerie e i
pacchetti necessari alla costruzione e all'esecuzione del sistema. Inoltre,
si occupa di creare il filesystem e di prepararlo in un'immagine pronta per
essere scritta sulla scheda SD del sistema embedded.

Per aggiungere l'interfaccia grafica sviluppata con LVGL è stato necessario
creare un nuovo pacchetto in Buildroot.

All'avvio del sistema, il bootloader del chip attiva AT91bootstrap
@at91bootstrap, che a
sua volta avvia Barebox @barebox, il quale carica il kernel in memoria.

== Personalizzazione di buildroot

Per aggiungere un pacchetto a Buildroot è necessario inserire una nuova voce
nella cartella `package`, comprendente un file `Config.in` e un file `.mk`.

Questi due file contengono le istruzioni che consentono a Buildroot di
risolvere le dipendenze, scaricare e installare il pacchetto nel filesystem
del dispositivo target.

=== Il pacchetto `amel-common-control`
#figure(
  caption: `amel-common-control.mk`,
  sourcecode()[```sh
  AMEL_COMMON_CONTROL_VERSION = v0.9
  AMEL_COMMON_CONTROL_SITE =
  git@git.amelchem.com:mpapaccioli/common-control.git
  AMEL_COMMON_CONTROL_SITE_METHOD = git

  define AMEL_COMMON_CONTROL_BUILD_CMDS
	$(TARGET_MAKE_ENV) TOOLS=$(TARGET_CROSS) STAGE=$(STAGING_DIR) \
	cmake -S $(@D) -B $(@D)/build -D CMAKE_BUILD_TYPE=Release -D  \
	CMAKE_INSTALL_PREFIX=/usr				      \
	-DCMAKE_TOOLCHAIN_FILE=$(@D)/user_cross_compile_setup.cmake   \
	-DBUILD_SHARED_LIBS=ON
	$(TARGET_MAKE_ENV) cmake --build $(@D)/build
	make -C $(@D) source/init.sh source/run.sh
  endef

  define AMEL_COMMON_CONTROL_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) DESTDIR=$(TARGET_DIR) cmake --install $(@D)/build
	mkdir -p $(STAGING_DIR)/usr/include/common-control
	mkdir -p $(STAGING_DIR)/usr/lib

	cp -r $(@D)/build/libcommon-control.so* $(STAGING_DIR)/usr/lib/
	cp -r $(@D)/include/common-control.h
	$(STAGING_DIR)/usr/include/common-control
	cp -r $(@D)/include/logging.h $(STAGING_DIR)/usr/include/common-control

	$(INSTALL) -d $(TARGET_DIR)/opt/amel
	$(INSTALL) -m 0755 $(@D)/source/init.sh $(TARGET_DIR)/opt/amel/init.sh
	$(INSTALL) -m 0755 $(@D)/source/run.sh $(TARGET_DIR)/opt/amel/run.sh
  endef

  $(eval $(generic-package))
  ```],
)

=== Il pacchetto `amel-temp-control`
#figure(
  caption: "amel-temp-control.mk",
  sourcecode()[```bash
   AMEL_TEMP_CONTROL_VERSION = 44c17c6f2c492f1f3c7d8a6767df390c8d13eb9c
   AMEL_TEMP_CONTROL_SITE = git@git.amelchem.com:mpapaccioli/temp-control.git
   AMEL_TEMP_CONTROL_SITE_METHOD = git

   AMEL_TEMP_CONTROL_DEPENDENCIES = libevdev
   AMEL_TEMP_CONTROL_GIT_SUBMODULES = YES

   define AMEL_TEMP_CONTROL_BUILD_CMDS
  cmake -DCMAKE_TOOLCHAIN_FILE=$(@D)/user_cross_compile_setup.cmake \
    -B $(@D)/build -S $(@D)
  make -C $(@D)/build -j @cmake

   endef

   define AMEL_TEMP_CONTROL_INSTALL_TARGET_CMDS
  $(INSTALL) -d $(TARGET_DIR)/opt/amel-temp-control/
  cp $(@D)/build/bin/lvglsim $(TARGET_DIR)/opt/amel-temp-control/main
  cp -r $(@D)/build/lvgl/lib/* $(TARGET_DIR)/usr/lib

   endef

   $(eval $(generic-package))
  ```],
)

Inizialmente, viene clonata la repository temp-control, contenente la GUI,
al commit specificato, inizializzando i sottomoduli e verificando la presenza
della dipendenza `libevdev`.

Successivamente, vengono cross-compilate la libreria LVGL e l'applicazione
con interfaccia grafica utilizzando il compilatore ARM fornito da Buildroot.

Infine, i binari della libreria e l'eseguibile dell'applicazione vengono
installati sulla macchina target.

=== Il pacchetto `amel-pid`
#figure(
  caption: "amel-pid-control.mk",
  sourcecode[```bash
     AMEL_PID_VERSION = v0.0.3
     AMEL_PID_SITE = git@git.amelchem.com:mpapaccioli/pid.git
     AMEL_PID_SITE_METHOD = git

     AMEL_PID_DEPENDENCIES = libmodbus

     define AMEL_PID_BUILD_CMDS
  make -C $(@D) CC=$(TARGET_CC)
     endef

     define AMEL_PID_INSTALL_TARGET_CMDS
  $(INSTALL) -d $(TARGET_DIR)/opt/amel-pid/

  cp $(@D)/pid $(TARGET_DIR)/opt/amel-pid/pid

     endef

     $(eval $(generic-package))


  ```],
)


Analogamente, è stato creato il pacchetto `amel-pid-control` per
cross-compilare e installare la libreria PID sviluppata in C++.

=== Modifica pacchetti networking
È stata creata una rete virtuale ed è stato aggiunto un SSH server
@openssh per
consentire il collegamento remoto al dispositivo embedded.
È stato necessario modificare lo script in `/etc/init.d/S50network` per
configurare l'interfaccia di rete virtuale `eth0` con un indirizzo IP statico
all'avvio del sistema e
permettere il login all'utente `root` tramite password modificando il file
`/etc/ssh/sshd_config`.
Dopo aver ripetuto questo processo per tutti i pacchetti desiderati, il
filesystem e l'immagine del kernel vengono assemblati in un file `sdcard.img`
pronto per essere scritto su una scheda SD e avviato sul dispositivo embedded.
Inoltre, la rete virtuale è stata creata in modo da condividere l'accesso
a Internet e dopo aver impostato come default gateway il PC creatore della
rete bridge è possibile accedere alla rete globale dal sistema embedded.
È stato utilizzato il DNS server di Google `8.8.8.8`.
L'accesso a Internet è necessario per la configurazione di NTP @ntp, come
descritto in seguito.

=== Installazione del modulo c210x per la porta seriale
Per consentire la comunicazione seriale tramite la porta RS-232 della
host-board Ganador, è stato necessario includere il modulo kernel `c210x`
per il controller USB-seriale.
Il modulo è stato aggiunto tramite il menu di configurazione di Buildroot,
selezionandolo in `Kernel modules -> USB Serial Converter support -> USB
CP210x family of UART Bridge Controllers` dal comando `make linux-menuconfig`.

=== Il pacchetto NTP
Per garantire la corretta sincronizzazione dell'orologio di sistema è stato
necessario installare il client `ntpd` per il Network Time Protocol tramite
Buildroot.

== Custom patches a `barebox` e `linux`
A causa dei rebuild frequenti in fase di sviluppo, sono stati patchati i
codici sorgenti di `barebox` @barebox e `linux` @linux.

È stata effettuata una clonazione della repository del kernel Linux di
Amel ed è stato abilitato di default il modulo cp210x, modificando il file
`/drivers/usb/serial/Kconfig`.

Analogamente, è stato cambiato l'ordine nel bootloader Barebox,
prioritarizzando il device `mmc2` invece che `nand`.


