#import "@local/uninsubria-thesis:0.1.0": sourcecode

= Sistema Embedded Basato su Linux

== Architettura Hardware

La piattaforma hardware impiegata per il sistema embedded è stata sviluppata
internamente da AMEL e si caratterizza per un'architettura modulare composta
da due schede principali che integrano tutte le funzionalità necessarie
per l'applicazione specifica.

=== Host-board Ganador (rev. 4)

La scheda host-board rappresenta l'infrastruttura di connettività e
interfacciamento del sistema, integrando:

- *Memoria di massa*: Scheda SD utilizzata come supporto di archiviazione
principale per il sistema operativo, le applicazioni e i dati di
configurazione.

- *Connettività di rete*: Interfaccia Ethernet 10/100 Mbps per il collegamento
alla rete aziendale e la comunicazione remota.

- *Interfaccia seriale*: Porta RS-232 per la comunicazione di sistema,
debugging e configurazione in fase di sviluppo e manutenzione.

- *Display interattivo*: Schermo touchscreen per l'interfaccia utente locale
e il controllo diretto del sistema da parte degli operatori.

=== System-on-Module Vulcano-A5

Il SoM Vulcano-A5 costituisce il cuore computazionale del sistema, integrando
in un formato compatto tutte le risorse di elaborazione necessarie:

- *Processore centrale*: CPU Atmel ARM9 AT91SAM9X35 operante a frequenza di
400MHz, ottimizzata per applicazioni embedded a basso consumo.

- *Sistema di memoria*: 128 MB di memoria DDR2 SDRAM per l'esecuzione delle
applicazioni e 256 MB di memoria flash NAND per la persistenza dei dati e
del firmware.

- *Interfacce di espansione*: Connettore SODIMM200 per l'espansione delle
funzionalità e l'integrazione con periferiche aggiuntive.

- *Controller di rete*: Controller Ethernet MAC integrato per la gestione
della comunicazione di rete nativa.

- *Interfacce USB*: Due porte USB 2.0 Host e una porta USB 2.0 Host/Device
per la connessione di periferiche esterne.

- *Comunicazione seriale*: Tre porte USART per la comunicazione con dispositivi
seriali e sensori.

- *Controller grafico*: Controller TFT LCD con supporto per interfacce TTL
e LVDS per la gestione del display a colori.


== Costruzione del Sistema Operativo

Per la gestione e l'orchestrazione delle risorse hardware è stato impiegato
il sistema operativo Linux @linux, configurato specificamente per le esigenze
dell'applicazione embedded. Data la natura limitata delle risorse hardware
disponibili, è stato realizzato un kernel personalizzato contenente
esclusivamente i moduli essenziali per il funzionamento del sistema,
ottimizzando così le prestazioni e riducendo l'impatto sulla memoria.

L'intero processo di costruzione del sistema è stato orchestrato mediante
Buildroot @buildroot, un framework specializzato per lo sviluppo di sistemi
embedded Linux. Buildroot fornisce un'infrastruttura completa basata su
Makefile che automatizza tutte le fasi critiche del processo:

- *Cross-compilazione*: Compilazione incrociata di tutte le librerie e
applicazioni per l'architettura ARM target
- *Gestione dipendenze*: Risoluzione automatica delle dipendenze tra pacchetti
- *Creazione del filesystem*: Generazione di un filesystem radice completo
e ottimizzato
- *Preparazione immagine*: Assemblaggio di un'immagine disco pronta per
essere scritta sulla scheda SD

Per integrare l'interfaccia grafica sviluppata con LVGL nell'ecosistema
Buildroot, è stato necessario creare un pacchetto personalizzato che
gestisca la compilazione e l'installazione della libreria grafica e delle
sue dipendenze.

=== Sequenza di Avvio del Sistema

Il processo di boot segue una sequenza strutturata che garantisce un avvio
ordinato e affidabile del sistema:

1. *Bootloader primario*: All'accensione del sistema, il bootloader primario
AT91bootstrap @at91bootstrap, residente nella memoria non volatile del SoC,
viene eseguito per primo, eseguendo le inizializzazioni hardware fondamentali.

2. *Bootloader secondario*: AT91bootstrap a sua volta lancia Barebox @barebox,
un bootloader secondario flessibile che fornisce funzionalità avanzate di
configurazione e debugging, oltre a gestire il caricamento del kernel Linux
in memoria.

3. *Avvio del kernel*: Barebox trasferisce il controllo al kernel Linux,
che prosegue con l'inizializzazione dei driver, il montaggio del filesystem
e l'avvio dei processi di sistema e delle applicazioni utente.

== Personalizzazione di Buildroot

L'estensibilità di Buildroot permette di integrare pacchetti personalizzati
nell'ecosistema di build mediante una procedura standardizzata. Per aggiungere
un nuovo pacchetto al sistema è necessario creare una directory dedicata
all'interno della cartella `package`, contenente due file fondamentali:

- *`Config.in`*: File di configurazione che definisce le opzioni compilative
del pacchetto, le dipendenze necessarie e le variabili di configurazione che
l'utente può modificare tramite l'interfaccia di configurazione di Buildroot.

- *`<nomepacchetto>.mk`*: Makefile che contiene le istruzioni specifiche
per il download, la compilazione, l'installazione e la pulizia del pacchetto.

Questi due componenti collaborano per fornire a Buildroot tutte le informazioni
necessarie per gestire il pacchetto nel ciclo di vita completo: risoluzione
delle dipendenze, download dei sorgenti, cross-compilazione per l'architettura
target e installazione nel filesystem finale del dispositivo embedded.

=== Pacchetto `amel-common-control`

Il pacchetto `amel-common-control` costituisce il fondamento condiviso del
sistema, fornendo le librerie comuni, gli header di configurazione e gli
script di sistema necessari al coordinamento dei diversi moduli applicativi.

#figure(
  caption: "File di configurazione per il pacchetto amel-common-control.mk",
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
	make -C $(@D)/source/init.sh source/run.sh
  endef

  define AMEL_COMMON_CONTROL_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) DESTDIR=$(TARGET_DIR) cmake --install $(@D)/build
	mkdir -p $(STAGING_DIR)/usr/include/common-control
	mkdir -p $(STAGING_DIR)/usr/lib

	cp -r $(@D)/build/libcommon-control.so- $(STAGING_DIR)/usr/lib/
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

Il processo di build prevede la configurazione tramite CMake con toolchain di
cross-compilazione, la compilazione della libreria condivisa e la generazione
degli script di sistema. La fase di installazione copia sia i file binari e
header nell'ambiente di staging per lo sviluppo, sia gli eseguibili e script
nella directory target del dispositivo finale.

=== Pacchetto `amel-temp-control`

Il pacchetto `amel-temp-control` gestisce l'interfaccia grafica utente
sviluppata con LVGL, fornendo il sistema di interazione tra l'operatore e
il controllo della temperatura.

#figure(
  caption: "File di configurazione per il pacchetto amel-temp-control.mk",
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
  cp -r $(@D)/build/lvgl/lib/- $(TARGET_DIR)/usr/lib

   endef

   $(eval $(generic-package))
  ```],
)

Il processo di costruzione del pacchetto segue una sequenza precisa:

1. *Acquisizione sorgenti*: Viene clonata la repository contenente il codice
sorgente dell'interfaccia grafica al commit specificato, con inizializzazione
automatica dei sottomoduli Git per includere le dipendenze di LVGL.

2. *Gestione dipendenze*: Buildroot verifica automaticamente la presenza
della dipendenza `libevdev`, necessaria per la gestione degli eventi di
input dal touchscreen.

3. *Cross-compilazione*: Vengono compilate sia la libreria LVGL che
l'applicazione principale utilizzando la toolchain ARM fornita da Buildroot,
garantendo l'ottimizzazione per l'architettura target.

4. *Installazione target*: Gli eseguibili compilati e le librerie necessarie
vengono installati nelle directory appropriate del filesystem target,
rendendo l'applicazione pronta per l'esecuzione sul dispositivo embedded.

=== Pacchetto `amel-pid`

Il pacchetto `amel-pid` gestisce la compilazione e l'installazione del
modulo di controllo PID, che rappresenta il cuore logico del sistema di
regolazione termica.

#figure(
  caption: "File di configurazione per il pacchetto amel-pid-control.mk",
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

Il pacchetto si basa su un processo di build più semplice rispetto agli
altri componenti, utilizzando direttamente il compilatore target fornito da
Buildroot. Le fasi principali includono:

1. *Download sorgenti*: Acquisizione del codice sorgente dalla repository
interna di AMEL.
2. *Verifica dipendenze*: Controllo automatico della disponibilità della
libreria `libmodbus` per la comunicazione MODBUS.
3. *Compilazione nativa*: Utilizzo del toolchain di Buildroot per la
cross-compilazione dell'eseguibile PID.
4. *Installazione sistema*: Copia dell'eseguibile compilato nella directory
dedicata sul filesystem target.

Questo approccio consente di integrare il modulo di controllo PID
nell'ecosistema Buildroot, garantendo la corretta gestione delle dipendenze
e l'integrazione con il resto del sistema software.

=== Configurazione della Rete e Accesso Remoto

Per garantire la piena gestibilità del sistema embedded, è stata implementata
un'infrastruttura di rete completa che include connettività remota e accesso
a risorse esterne.

La configurazione di rete prevede:

- *Interfaccia virtuale*: Creazione di un'interfaccia di rete virtuale `eth0`
configurata con indirizzo IP statico, garantendo un punto di accesso stabile
e prevedibile al dispositivo.

- *Accesso remoto sicuro*: Installazione e configurazione del server SSH
@openssh per consentire la connessione remota sicura al dispositivo. La
configurazione permette il login come utente `root` tramite autenticazione
password, semplificando le operazioni di amministrazione e manutenzione.

Le personalizzazioni necessarie sono state implementate mediante la modifica
degli script di sistema:
- Il file `/etc/init.d/S50network` è stato modificato per configurare
automaticamente l'interfaccia di rete con l'indirizzo IP statico durante
l'avvio.
- Il file `/etc/ssh/sshd_config` è stato adattato per permettere l'accesso
root tramite password.

=== Connettività Internet e Sincronizzazione Temporale

Per garantire l'accesso a risorse di rete esterne, è stata configurata una
rete bridge che permette al dispositivo embedded di condividere la connessione
Internet del PC host. La configurazione prevede:

- *Gateway di default*: Il PC che crea la rete bridge è configurato come
gateway predefinito per il dispositivo embedded.
- *DNS server*: È stato configurato il server DNS di Google `8.8.8.8`
per la risoluzione dei nomi di dominio.
- *Sincronizzazione temporale*: L'accesso a Internet è essenziale
per il corretto funzionamento del servizio NTP @ntp, che garantisce la
sincronizzazione dell'orologio di sistema con server di tempo accurati. Questa
funzionalità è fondamentale per l'integrità dei timestamp dei log e la
corretta funzionalità dei meccanismi di scheduling del sistema.

Una volta completate tutte le configurazioni dei pacchetti necessari,
Buildroot assembla il filesystem completo e l'immagine del kernel in un
unico file `sdcard.img`, pronto per essere scritto su scheda SD e avviato
sul dispositivo embedded.

=== Modulo Kernel CP210x per Comunicazione Seriale

Per abilitare la comunicazione seriale attraverso la porta RS-232 integrata
nella host-board Ganador, è stato necessario includere nel kernel il modulo
`cp210x` specifico per i controller USB-seriale Silicon Labs.

Questo driver è fondamentale per il corretto funzionamento dell'interfaccia
di comunicazione con l'inverter tramite protocollo MODBUS RTU. L'integrazione
del modulo è stata realizzata mediante il sistema di configurazione del
kernel di Buildroot:

- *Configurazione kernel*: Esecuzione del comando `make linux-menuconfig`
per accedere all'interfaccia di configurazione del kernel.
- *Selezione modulo*: Navigazione nel menu `Kernel modules -> USB Serial
Converter support -> USB CP210x family of UART Bridge Controllers` e
attivazione del modulo corrispondente.

Questo approccio garantisce che il modulo sia compilato come parte del
kernel personalizzato e caricato automaticamente all'avvio del sistema,
rendendo disponibile l'interfaccia seriale per le applicazioni utente senza
necessità di interventi manuali.

=== Servizio NTP per Sincronizzazione Temporale

Per garantire la precisione e l'affidabilità dell'orologio di sistema,
essenziale per il corretto funzionamento delle applicazioni e per l'integrità
dei log temporali, è stato incluso il pacchetto `ntpd` come client Network
Time Protocol.

Il servizio NTP @ntp viene automaticamente installato tramite Buildroot e
configurato per sincronizzare periodicamente l'orologio locale con server
di tempo accurati accessibili tramite Internet. Questa funzionalità è
particolarmente importante per:

- *Consistenza temporale*: Garantire che tutti gli eventi di sistema siano
timestampati in modo coerente.
- *Debugging e analisi*: Facilitare l'analisi dei log e la correlazione
degli eventi temporali.
- *Integrazione sistemica*: Assicurare la compatibilità con protocolli e
servizi che dipendono da un orologio di sistema accurato.

La configurazione predefinita utilizza server NTP pubblici, garantendo una
sincronizzazione affidabile senza richiedere infrastrutture temporali dedicate.

== Personalizzazioni del Kernel e Bootloader

Durante le fasi intensive di sviluppo e testing, la frequenza dei cicli di
rebuild del sistema ha reso necessarie alcune personalizzazioni specifiche
dei componenti fondamentali del sistema operativo, in particolare il kernel
Linux e il bootloader Barebox.

=== Patch del Kernel Linux

È stata creata una clonazione dedicata della repository del kernel Linux
personalizzata da AMEL, implementando le seguenti modifiche:

- *Abilitazione predefinita modulo CP210x*: Modifica del file
`/drivers/usb/serial/Kconfig` per abilitare il modulo del driver seriale
come configurazione predefinita. Questa modifica elimina la necessità
di riabilitare il manualmente il modulo ad ogni rebuild, accelerando
significativamente i cicli di sviluppo e testing.

=== Patch del Bootloader Barebox

Analogamente, è stato modificato il bootloader Barebox @barebox per
ottimizzare la sequenza di avvio:

- *Priorità dispositivo di boot*: Modifica dell'ordine di ricerca dei
dispositivi di avvio, dando priorità al dispositivo `mmc2` (scheda
SD) rispetto alla memoria flash NAND interna. Questa configurazione
è particolarmente utile durante le fasi di sviluppo, quando frequenti
aggiornamenti del sistema vengono eseguiti tramite scheda SD.

Queste personalizzazioni sono state implementate per migliorare l'efficienza
del flusso di sviluppo, riducendo i tempi di setup tra i cicli di build
e test, e garantendo una maggiore ripetibilità dei processi di avvio e
configurazione del sistema.


