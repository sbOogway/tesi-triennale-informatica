#import "@preview/unofficial-uninsubria-thesis:0.1.0": sourcecode

= Manuale utente

Il presente capitolo fornisce le istruzioni dettagliate per la configurazione
e l'utilizzo del sistema di controllo temperatura. Tale manuale è strutturato
in quattro sezioni principali: la compilazione del sistema operativo mediante
Buildroot, la preparazione della scheda di memoria SD, la configurazione del
dispositivo embedded e, infine, le procedure di inizializzazione e avvio del
sistema.

== Compilazione del sistema operativo tramite Buildroot

La prima fase del processo di configurazione richiede la compilazione del
sistema operativo embedded. Questa operazione viene effettuata mediante
Buildroot, un framework open-source per la generazione di sistemi Linux
embedded.

=== Procedura di clonazione del repository

Inizialmente, è necessario ottenere il codice sorgente del progetto. Il
repository Git è ospitato presso il server dell'azienda ed è accessibile
tramite due modalità:

- *Modalità SSH* (consigliata per gli sviluppatori con chiavi configurate):
  `git clone git@git.amelchem.com:amel/buildroot.git`

- *Modalità HTTPS* (alternativa generale):
  `git clone https://git.amelchem.com/amel/buildroot.git`

Una volta completata la clonazione, è fondamentale posizionarsi sul branch
corretto denominato `Vulcano-papaccioli`. Questo branch contiene la
configurazione specifica per la board utilizzata nel progetto.

=== Processo di compilazione

Dopo aver effettuato il checkout sul branch corretto, si può avviare il
processo di compilazione mediante il comando `make`. Tale comando eseguirà
automaticamente la compilazione di tutti i componenti necessari, tra cui:

- Il kernel Linux ottimizzato per l'architettura target
- Il bootloader Barebox per la gestione dell'avvio
- Tutti i pacchetti e le dipendenze richieste dal sistema

*Considerazioni importanti sulla compilazione:*

1. *Durata:* la prima compilazione richiede circa un'ora, poiché Buildroot
   deve scaricare e compilare tutti i pacchetti dalla fonte.

2. *Spazio su disco:* sono necessari almeno 20 GB di spazio libero sul disco
   rigido per ospitare i sorgenti scaricati, i file oggetto intermedi e le
   immagini finali del sistema.

3. *Connessione di rete:* durante il processo è richiesta una connessione
   Internet stabile per il download dei pacchetti.

== Preparazione della scheda di memoria SD

Al termine della compilazione, Buildroot genera nella directory `output`
tutti i file necessari per il deployment del sistema. In particolare, il
file `output/images/sdcard.img` rappresenta l'immagine completa del sistema
operativo pronta per essere installata sulla scheda di memoria.

=== Procedura di scrittura dell'immagine

Per trasferire l'immagine sulla scheda SD è necessario utilizzare il comando
`dd`, che effettua una copia bit-per-bit del file. Tale approccio garantisce
la preservazione esatta di tutte le partizioni e i filesystem presenti
nell'immagine.

Il comando da eseguire è il seguente:

```bash
sudo dd if=output/images/sdcard.img of=/dev/mmcblk0 bs=4M status=progress
conv=fsync
```

Dove:
- `if` (input file) specifica il percorso dell'immagine sorgente
- `of` (output file) indica il dispositivo di destinazione (la scheda SD)
- `bs=4M` imposta la dimensione del blocco a 4 megabyte per ottimizzare la
  velocità di trasferimento
- `status=progress` visualizza l'avanzamento dell'operazione
- `conv=fsync` garantisce la sincronizzazione dei dati sul dispositivo prima
  della conclusione del comando

*Nota:* è necessario adattare i percorsi (`if`) e il nome del dispositivo
(`of`) in base alla configurazione specifica della macchina utilizzata. Per
identificare correttamente il dispositivo della scheda SD, si consiglia di
utilizzare il comando `lsblk` prima e dopo l'inserimento della scheda.

== Configurazione del dispositivo embedded

Una volta preparata la scheda di memoria, è possibile procedere con la
configurazione del dispositivo target.

=== Avvio del sistema

La procedura di avvio si articola nei seguenti passaggi:

1. *Inserimento della scheda:* estrarre con cautela la scheda SD dal computer
   e inserirla nello slot apposito presente sulla board Ganador.

2. *Alimentazione della board:* collegare l'alimentazione alla board per
   avviare il processo di boot.

3. *Attesa dell'avvio:* il sistema impiega circa un minuto per completare
   l'avvio. Durante questa fase vengono eseguite le seguenti operazioni:
   - Inizializzazione del kernel Linux
   - Montaggio dei filesystem
   - Generazione delle chiavi SSH (operazione che richiede circa 30 secondi)

Al termine di questo processo, il sistema è pronto per essere configurato
e utilizzato.

=== Modalità di connessione al dispositivo

Sono disponibili due modalità alternative per accedere al sistema embedded:

==== Connessione tramite porta seriale

La connessione seriale rappresenta il metodo più affidabile per l'accesso
iniziale al sistema, poiché non richiede la configurazione di rete.

*Requisiti hardware:*
- Adattatore USB-seriale compatibile con livelli logici RS-232
- Cavi di collegamento per i pin UART della board

*Configurazione software:*
Per la comunicazione seriale è necessario utilizzare un emulatore di
terminale.
Il software consigliato è `minicom`, disponibile sulla maggior parte delle
distribuzioni Linux.

*Procedura di connessione:*

1. Collegare l'adattatore USB-seriale al computer host
2. Connettere i pin dell'adattatore alla board Ganador secondo lo schema
   riportato nella @serial-port-pins
3. Identificare il nome del device seriale (tipicamente `/dev/ttyUSB0` su
   sistemi Linux) mediante il comando `dmesg | grep tty`
4. Avviare minicom specificando il device: `minicom -D /dev/ttyUSB0`

#figure(
  image("/images/serial-pinout.jpg"),
  caption: [Schema di collegamento dei pin per la comunicazione seriale],
) <serial-port-pins>

==== Connessione tramite SSH

La connessione SSH offre un accesso remoto più flessibile, particolarmente
utile quando il dispositivo è già configurato e integrato nell'ambiente
operativo.

Per stabilire la connessione, utilizzare il comando:

```bash
ssh root@10.42.0.2
```

Le credenziali di accesso predefinite sono:
- *Username:* `root`
- *Password:* `root`

*Personalizzazione delle credenziali e della rete:*

Qualora fosse necessario modificare la password di root o la configurazione
di rete prima della compilazione, è possibile intervenire direttamente sulla
configurazione di Buildroot.

La @buildroot-password mostra la modifica della password di root nel file
di configurazione `vulcanoa5_defconfig`, mentre la @buildroot-network
illustra la configurazione dell'interfaccia di rete.

#figure(
  caption: [Modifica della password di root in Buildroot],
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
) <buildroot-password>

#figure(
  caption: [Configurazione dell'interfaccia di rete in Buildroot],
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
) <buildroot-network>

== Inizializzazione e avvio del sistema

Dopo aver stabilito la connessione con il dispositivo, è necessario procedere
con la configurazione del software applicativo e l'avvio dei servizi.

=== Configurazione dell'ambiente

La directory di lavoro principale del sistema è `/opt/amel/`. È necessario
posizionarsi in tale directory per accedere agli script e ai file di
configurazione:

```bash
cd /opt/amel/
```

All'interno di questa directory è presente il file `config.env`, che contiene
le variabili d'ambiente necessarie per la personalizzazione del comportamento
del sistema. Tale file deve essere modificato in base alle esigenze
specifiche dell'installazione.

=== Calibrazione del touchscreen

Il sistema utilizza la libreria grafica LVGL per l'interfaccia utente. Per
garantire il corretto funzionamento del touchscreen è necessario effettuare
una procedura di calibrazione.

La calibrazione richiede la determinazione dei seguenti parametri, da
inserire nel file `config.env`:

- `LV_MIN_X`: valore minimo sull'asse X
- `LV_MIN_Y`: valore minimo sull'asse Y
- `LV_MAX_X`: valore massimo sull'asse X
- `LV_MAX_Y`: valore massimo sull'asse Y

*Procedura di calibrazione:*

1. Eseguire il comando `evtest /dev/input/event0` per monitorare gli eventi
   di input del touchscreen
2. Toccare successivamente i quattro angoli dello schermo
3. Annotare i valori minimi e massimi rilevati per ciascun asse
4. Inserire tali valori nel file `config.env`

=== Script di gestione del sistema

Il sistema fornisce tre script principali per la gestione dei servizi:

*1. Script di inizializzazione (`init.sh`)*

Questo script deve essere eseguito una sola volta, tipicamente dopo la prima
installazione o dopo una reimpostazione del sistema. Il suo compito è
creare la struttura di directory e i file necessari al funzionamento
dell'applicazione.

```bash
./init.sh
```

*2. Script di avvio (`run.sh`)*

Per avviare il sistema di controllo temperatura è sufficiente eseguire lo
script `run.sh`. Tale script si occupa di avviare in sequenza tutti i
processi necessari, inclusi il servizio di acquisizione dati, il controllore
PID e l'interfaccia grafica.

```bash
./run.sh
```

*3. Script di arresto (`kill.sh`)*

Per terminare correttamente l'esecuzione del sistema è necessario utilizzare
lo script `kill.sh`. Questo script provvede a interrompere in modo ordinato
tutti i processi avviati dallo script `run.sh`, garantendo la chiusura
corretta delle risorse e il salvataggio dei dati.

```bash
./kill.sh
```

=== Monitoraggio e logging

Il sistema mantiene una traccia dettagliata delle operazioni mediante file
di log, archiviati nella directory `/opt/amel/logs/`.

Tali log contengono:
- Messaggi di avvio e arresto dei processi
- Eventuali errori e warning
- Informazioni di debug relative al funzionamento del sistema

La consultazione dei log è fondamentale per il monitoraggio del sistema e
per l'individuazione di eventuali malfunzionamenti. È possibile visualizzare
i log in tempo reale mediante il comando `tail -f` oppure analizzarli
a posteriori con strumenti come `less` o `grep`.
