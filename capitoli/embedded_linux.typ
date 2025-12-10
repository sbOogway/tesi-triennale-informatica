#import "@local/tesi-uninsubria:0.1.0": sourcecode
= Embedded Linux

== Hardware

La scheda utilizzata per il sistema embedded è sviluppata da AMEL e comprende:

- una host-board Ganador (rev. 4);
- un system-on-module Vulcano-A5;
- una CPU ARM;
- una memoria SD utilizzata come disco fisso;
- un'interfaccia Ethernet;
- un'interfaccia seriale;
- un display touchscreen.

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

```bash

```

Analogamente, è stato creato il pacchetto `amel-pid-control` per cross-compilare e installare la libreria PID sviluppata in C++.

=== Modifica pacchetti networking

Dopo aver ripetuto questo processo per tutti i pacchetti desiderati, il filesystem e l'immagine del kernel vengono assemblati in un file `sdcard.img` pronto per essere scritto su una scheda SD e avviato sul dispositivo embedded.

== File I/O

== PID Control

== MODBUS RTU
