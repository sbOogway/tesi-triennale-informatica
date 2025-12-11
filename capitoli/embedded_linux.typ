#import "@local/uninsubria-thesis:0.1.0": sourcecode

= Embedded Linux

== Hardware

La scheda utilizzata per il sistema embedded è sviluppata da AMEL e comprende:

- una host-board Ganador (rev. 4) che integra:

  - una memoria SD utilizzata come disco fisso;
  - un'interfaccia Ethernet
  - un'interfaccia seriale
  - un display touchscreen

- un system-on-module Vulcano-A5 che integra:
  - una cpu Atmel ARM9 AT91SAM9X35 @ 400MHz
  - 128 MB DDR2 SDRAM
  - 256 MB NAND Flash
  - SODIMM200 interface
  - 10/100 Mbps Ethernet MAC Controller
  - 2x USB 2.0 Host, 1x USB 2.0 Host/Device
  - 3x USARTs
  - TFT LCD Controller with TTL / LVDS support




== Costruzione del sistema

Per orchestrare il sistema è stato utilizzato Linux. È stato creato un kernel personalizzato con soli i moduli essenziali per il funzionamento, data la limitatezza delle risorse hardware. Lo strumento utilizzato per completare l'opera è Buildroot @buildroot, che consiste essenzialmente in una serie di Makefile per installare e cross-compilare tutte le librerie e i pacchetti necessari alla costruzione e all'esecuzione del sistema. Inoltre, si occupa di creare il filesystem e di prepararlo in un'immagine pronta per essere scritta sulla scheda SD del sistema embedded.

Per aggiungere l'interfaccia grafica sviluppata con LVGL è stato necessario creare un nuovo pacchetto in Buildroot.

All'avvio del sistema, il bootloader del chip attiva AT91bootstrap, che a sua volta avvia Barebox, il quale carica il kernel in memoria.

== Personalizzazione di buildroot

Per aggiungere un pacchetto a Buildroot è necessario inserire una nuova voce nella cartella `package`, comprendente un file `Config.in` e un file `.mk`.

Questi due file contengono le istruzioni che consentono a Buildroot di risolvere le dipendenze, scaricare e installare il pacchetto nel filesystem del dispositivo target.

=== Il pacchetto amel-temp-control
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
  	make -C $(@D)/build -j

  endef

  define AMEL_TEMP_CONTROL_INSTALL_TARGET_CMDS
   	$(INSTALL) -d $(TARGET_DIR)/opt/amel-temp-control/
  	cp $(@D)/build/bin/lvglsim $(TARGET_DIR)/opt/amel-temp-control/main
  	cp -r $(@D)/build/lvgl/lib/* $(TARGET_DIR)/usr/lib

  endef

  $(eval $(generic-package))
  ```],
)

Inizialmente, viene clonata la repository temp-control, contenente la GUI, al commit specificato, inizializzando i sottomoduli e verificando la presenza della dipendenza `libevdev`.

Successivamente, vengono cross-compilate la libreria LVGL e l'applicazione con interfaccia grafica utilizzando il compilatore ARM fornito da Buildroot.

Infine, i binari della libreria e l'eseguibile dell'applicazione vengono installati sulla macchina target.

=== Il pacchetto amel-pid
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


Analogamente, è stato creato il pacchetto `amel-pid-control` per cross-compilare e installare la libreria PID sviluppata in C++.

=== Modifica pacchetti networking
E stata creata una rete virtuale ed e stato aggiunto un ssh server per consentire il collegamento remoto al dispositivo embedded.
E stato necessario modificare lo script in `/etc/init.d/S50network` per configurare l'interfaccia di rete virtuale `eth0` con un indirizzo IP statico all'avvio del sistema e
permettere il login all'utente `root` tramite password modificando il file `/etc/ssh/sshd_config`.
Dopo aver ripetuto questo processo per tutti i pacchetti desiderati, il filesystem e l'immagine del kernel vengono assemblati in un file `sdcard.img` pronto per essere scritto su una scheda SD e avviato sul dispositivo embedded.

=== Installazione del modulo c210x per la porta seriale
Per consentire la comunicazione seriale tramite la porta RS-232 della host-board Ganador, è stato necessario includere il modulo kernel `c210x` per il controller USB-seriale.
Il modulo e stato aggiunto tramite il menu di configurazione di Buildroot, selezionandolo in `Kernel modules -> USB Serial Converter support -> USB CP210x family of UART Bridge Controllers` dal comando `make linux-menuconfig`.
== File I/O

== PID Control
=== Sensore di temperatura
I sensori di temperatura utilizzati sono due DS18B20 collegati in parallelo su un bus 1-Wire.

Il microcontrollore si comporta da master sul bus e richiede periodicamente la temperatura ai sensori.

Il binario `pid` legge periodicamente e calcola il valore di output del controller PID in base alla temperatura misurata e al setpoint desiderato.

Inizialmente esso conta il numero di sensori sul bus, alloca la memoria necessaria per immagazinare gli uuid dei sensori e poi legge effetivamente quest'ultimi in memoria.

E stato preferito questo approccio per evitare complicazioni con `realloc` rispetto a leggere direttamente in un ciclo unico sia il numero di sensori che gli id. Questa procedura viene effettuate solamente una volta all'avvio e non ha un impatto significativo sulla performance dell'eseguibile.

Un approccio senza salvare gli id dei sensori porterebbe una chiamata alla funzione `DS18X20_find_sensor` ripetutamente e sarebbe uno spreco di cicli di cpu quindi sacrifichiamo un po di memoria per questo.

#figure(
  caption: `pid-main`,
  sourcecode[```c
    typedef struct
    {
      char id[16];
      int16_t temperature;
      uint8_t uint_id[OW_ROMCODE_SIZE];
    } sensor;

    // first we count the number of devices on the bus
    while (diff != OW_LAST_DEVICE)
    {
        sensors_count++;
        DS18X20_find_sensor(&diff, id);
    }

    // we malloc based on the number of sensors
    sensor *sensors = malloc(sizeof(sensor) * sensors_count);

    diff = OW_SEARCH_FIRST;
    int i = 0;
    // we store the sensor ids
    while (diff != OW_LAST_DEVICE)
    {
        DS18X20_find_sensor(&diff, id);
        sensor s;
        for (int i = 0; i < OW_ROMCODE_SIZE; i++)
        {
            s.uint_id[i] = id[i];
        }
        sensors[i] = s;
        i++;
    }

    while (1)
    {
        // now we read the sensor temperatures every second
        if (DS18X20_start_meas(DS18X20_POWER_EXTERN, NULL) != DS18X20_OK)
        {
            fprintf(stdout, "error in starting measurement\n");
            fflush(stdout);
            delay_ms(100);
            break;
        }
        for (int i = 0; i < sensors_count; i++)
        {
            sensor s = sensors[i];
            if (DS18X20_read_decicelsius(s.uint_id, &temp_dc) != DS18X20_OK)
            {
                fprintf(stdout, "error in reading sensor %s\n", s);
                fflush(stdout);
                delay_ms(100);
                continue;
            }
            fprintf(stdout, "sensor %s TEMP %3d.%01d C\n", s.id, temp_dc / 10, temp_dc > 0 ? temp_dc % 10 : -temp_dc % 10);
            fflush(stdout);
        }
        delay_ms(1000);
    }
  ```],
)

== MODBUS RTU
Per comunicare con l'inverter che controlla la ventola di raffreddamento, è stato utilizzato il protocollo MODBUS RTU tramite l'apposita libreria `libmodbus`.
