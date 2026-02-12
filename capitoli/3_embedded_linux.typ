#import "@preview/unofficial-uninsubria-thesis:0.1.0": sourcecode

= Sistema operativo embedded Linux

== Architettura hardware del sistema

Il sistema embedded sviluppato per il controllo della temperatura si basa su
un'architettura hardware progettata da AMEL, costituita da due componenti
principali:

- *Host-board Ganador (revisione 4)*: rappresenta la scheda portante del
  sistema e integra le seguenti periferiche:
  - memoria SD, utilizzata come dispositivo di storage principale;
  - interfaccia Ethernet per la connettività di rete;
  - interfaccia seriale per la comunicazione con dispositivi esterni;
  - display touchscreen per l'interazione con l'utente.

- *System-on-Module Vulcano-A5*: costituisce il modulo di elaborazione
centrale e comprende:
  - processore Atmel ARM9 AT91SAM9X35 a 400 MHz;
  - 128 MB di memoria DDR2 SDRAM;
  - 256 MB di memoria NAND Flash;
  - interfaccia SODIMM200;
  - controller Ethernet MAC 10/100 Mbps;
  - due porte USB 2.0 Host e una porta USB 2.0 Host/Device;
  - tre interfacce USART;
  - controller TFT LCD con supporto TTL/LVDS.

== Realizzazione del sistema operativo

Per la gestione del sistema embedded è stato adottato il sistema operativo
Linux @linux, noto per la sua flessibilità e per la possibilità di
personalizzazione del kernel. Data la limitatezza delle risorse hardware
disponibili, è stato necessario procedere alla costruzione di un kernel
su misura, includendo esclusivamente i moduli essenziali per il
funzionamento del sistema.

Per la compilazione incrociata (cross-compilation) e la creazione del
filesystem è stato impiegato Buildroot @buildroot. Questo strumento
consiste in una raccolta di Makefile che automatizzano le seguenti operazioni:

1. installazione e compilazione delle librerie necessarie;
2. gestione delle dipendenze tra i pacchetti;
3. creazione del filesystem completo;
4. generazione di un'immagine pronta per essere trasferita sulla scheda SD
del dispositivo target.

L'integrazione dell'interfaccia grafica sviluppata con la libreria LVGL ha
richiesto la creazione di un pacchetto personalizzato all'interno di
Buildroot, come descritto nelle sezioni successive.

La sequenza di avvio del sistema segue il seguente flusso:
1. il bootloader del chip attiva AT91bootstrap @at91bootstrap;
2. AT91bootstrap avvia il bootloader secondario Barebox @barebox;
3. Barebox carica il kernel Linux in memoria e ne avvia l'esecuzione.

== Personalizzazione di Buildroot

L'aggiunta di nuovi pacchetti software a Buildroot richiede la definizione di
una struttura specifica all'interno della directory `package`. In
particolare, per ciascun pacchetto è necessario creare:

- un file `Config.in`, che descrive le opzioni di configurazione e le
dipendenze del pacchetto;
- un file `.mk`, che contiene le istruzioni per il download, la compilazione
e l'installazione del software.

Questi file consentono a Buildroot di risolvere automaticamente le dipendenze,
scaricare i sorgenti e installare il pacchetto nel filesystem del dispositivo
target.

=== Il pacchetto `amel-common-control`

Il pacchetto `amel-common-control` rappresenta una libreria di supporto
condivisa tra i vari componenti del sistema. La configurazione di Buildroot
per questo pacchetto è riportata nel Codice sorgente 3.1.

#figure(
  caption: [Configurazione Buildroot per il pacchetto amel-common-control],
  sourcecode()[```sh
  AMEL_COMMON_CONTROL_VERSION = v0.9
  AMEL_COMMON_CONTROL_SITE =
  git@git.amelchem.com:mpapaccioli/common-control.git
  AMEL_COMMON_CONTROL_SITE_METHOD = git

  define AMEL_COMMON_CONTROL_BUILD_CMDS
    $(TARGET_MAKE_ENV) TOOLS=$(TARGET_CROSS) STAGE=$(STAGING_DIR) \
    cmake -S $(@D) -B $(@D)/build -D CMAKE_BUILD_TYPE=Release -D  \
    CMAKE_INSTALL_PREFIX=/usr                      \
    -DCMAKE_TOOLCHAIN_FILE=$(@D)/user_cross_compile_setup.cmake   \
    -DBUILD_SHARED_LIBS=ON
    $(TARGET_MAKE_ENV) cmake --build $(@D)/build
    make -C $(@D) source/init.sh source/run.sh
  endef

  define AMEL_COMMON_CONTROL_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/amel
    $(INSTALL) -m 0755 $(@D)/source/init.sh $(TARGET_DIR)/opt/amel/init.sh
    $(INSTALL) -m 0755 $(@D)/source/run.sh $(TARGET_DIR)/opt/amel/run.sh
  endef

  $(eval $(generic-package))
  ```],
)

=== Il pacchetto `amel-temp-control`

Il pacchetto `amel-temp-control` contiene l'applicazione con interfaccia
grafica sviluppata mediante la libreria LVGL. La sua configurazione Buildroot
è illustrata nel Codice sorgente 3.2.

#figure(
  caption: [Configurazione Buildroot per il pacchetto amel-temp-control],
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

Il processo di compilazione e installazione del pacchetto si articola nelle
seguenti fasi:

1. *Clonazione dei sorgenti*: il repository `temp-control`, contenente il
codice sorgente dell'interfaccia grafica, viene clonato al commit specificato.
Vengono inizializzati i sottomoduli Git e verificata la presenza della
dipendenza `libevdev`.

2. *Compilazione incrociata*: la libreria LVGL e l'applicazione grafica
vengono compilate utilizzando il toolchain ARM fornito da Buildroot.

3. *Installazione*: i file binari della libreria e l'eseguibile
dell'applicazione
vengono copiati nel filesystem della macchina target.

=== Il pacchetto `amel-pid`

Analogamente ai pacchetti precedenti, è stato creato il pacchetto
`amel-pid-control` per la compilazione e l'installazione della libreria
PID, implementata in linguaggio C++. La configurazione è riportata nel
Codice sorgente 3.3.

#figure(
  caption: [Configurazione Buildroot per il pacchetto amel-pid],
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

=== Configurazione dei servizi di rete

Per consentire la gestione remota del dispositivo embedded, sono stati
implementati i seguenti servizi di rete:

- *Server SSH*: è stato installato il server OpenSSH @openssh per
permettere l'accesso remoto al sistema. È stata modificata la configurazione
nel file `/etc/ssh/sshd_config` per abilitare l'autenticazione dell'utente
`root` tramite password.

- *Configurazione dell'interfaccia di rete*: lo script di inizializzazione
`/etc/init.d/S50network` è stato personalizzato per configurare l'interfaccia
`eth0` con un indirizzo IP statico all'avvio del sistema.

- *Rete virtuale e connettività Internet*: è stata creata una rete virtuale
che condivide la connessione Internet del PC host. Configurando il PC come
default gateway del sistema embedded, è stato possibile abilitare l'accesso
alla rete globale. È stato utilizzato il server DNS di Google (`8.8.8.8`)
per la risoluzione dei nomi di dominio.

L'accesso a Internet è risultato necessario per la configurazione del servizio
NTP (Network Time Protocol), descritto nella sezione successiva.

Al termine della configurazione di tutti i pacchetti, Buildroot assembla il
filesystem e l'immagine del kernel in un file `sdcard.img`, pronto per essere
scritto su una scheda SD e avviato sul dispositivo target.

=== Supporto per la porta seriale RS-232

Per abilitare la comunicazione seriale tramite la porta RS-232 presente sulla
host-board Ganador, è stato necessario includere il modulo kernel `cp210x`
per il controller USB-seriale Silicon Labs CP210x.

L'inclusione del modulo è stata effettuata tramite il menu di configurazione
di Buildroot, selezionando il percorso:
```
Kernel modules -> USB Serial Converter support ->
USB CP210x family of UART Bridge Controllers
```
accessibile mediante il comando `make linux-menuconfig`.

=== Sincronizzazione temporale con NTP

Per garantire la corretta sincronizzazione dell'orologio di sistema, essenziale
per la registrazione accurata dei dati di temperatura, è stato installato
il client `ntpd` per il Network Time Protocol @ntp tramite Buildroot.

== Personalizzazione delle patch per Barebox e Linux

Durante la fase di sviluppo, è stata necessaria la modifica dei codici
sorgenti
di Barebox @barebox e del kernel Linux @linux per ottimizzare le operazioni
di ricompilazione frequenti.

Le personalizzazioni effettuate sono state le seguenti:

- *Kernel Linux*: è stata creata una copia del repository del kernel Linux
mantenuto da AMel. All'interno di questo repository, il modulo `cp210x` è
stato abilitato di default modificando il file di configurazione
`/drivers/usb/serial/Kconfig`. Questa modifica evita la necessità di
riconfigurare manualmente il modulo ad ogni ricompilazione del kernel.

- *Bootloader Barebox*: è stato modificato l'ordine di ricerca dei dispositivi
all'avvio. In particolare, è stata data priorità al dispositivo `mmc2`
(interfaccia SD) rispetto alla memoria `nand` (memoria Flash interna). Questa
modifica consente un avvio più rapido del sistema quando il kernel è presente
sulla scheda SD.

