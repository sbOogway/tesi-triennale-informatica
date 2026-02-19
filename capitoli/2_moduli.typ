#import "@preview/unofficial-uninsubria-thesis:0.1.0": sourcecode

= Moduli del sistema

Il sistema di controllo della temperatura è stato progettato seguendo
un'architettura modulare che permette una chiara separazione delle
responsabilità tra i diversi componenti software. Tale approccio facilita
la manutenibilità del codice e consente di aggiornare singoli moduli senza
compromettere il funzionamento dell'intero sistema. I due moduli principali
sono `temp-control` e `pid-control`, coordinati dal modulo di supporto
`common-control`.

== Il modulo `common-control`

Il modulo `common-control` rappresenta il nucleo di supporto dell'intero
sistema. Esso svolge tre funzioni fondamentali: fornisce funzioni di
utilità condivise tra gli altri moduli, definisce le configurazioni globali
attraverso file header, e gestisce gli script per l'inizializzazione e
l'avvio del sistema.

La struttura delle directory del sistema è organizzata come segue: tutti
gli script eseguibili e i file di configurazione risiedono nella directory di
sistema `/opt/amel/`. Questa scelta garantisce un'ubicazione standardizzata
e protetta per i componenti del sistema di controllo.

=== Meccanismi di comunicazione inter-modulare

Per garantire lo scambio di dati tra i moduli `temp-control` e `pid-control`
è stato necessario implementare un sistema di comunicazione che combina
l'uso dei segnali Unix con operazioni di lettura e scrittura su file.

Il flusso di comunicazione avviene secondo questa sequenza:
1. L'operatore modifica la temperatura target attraverso l'interfaccia grafica
sul display LCD
2. Il modulo `temp-control` scrive il nuovo valore nel file
`/opt/amel/target-temperature`
3. Il processo `pid-control`, eseguendo ciclicamente la lettura dei
sensori di temperatura DS18B20 @DS18B20, memorizza le misurazioni nei file
`/opt/amel/current-temperature/sX`, dove `X` indica il numero identificativo
del sensore sul bus
4. Dopo ogni scrittura, `pid-control` invia un segnale Unix al processo
`temp-control`
5. Il modulo `temp-control`, alla ricezione del segnale, legge i file
e aggiorna l'interfaccia grafica

Questo approccio ibrido consente una comunicazione affidabile anche in
presenza di operazioni bloccanti, poiché i segnali notificano immediatamente
la disponibilità di nuovi dati.

=== La libreria `logging.h`

Per garantire una gestione ordinata dei messaggi di sistema è stata
sviluppata una libreria di logging in linguaggio C. Questa libreria supporta
la formattazione delle stringhe e la classificazione dei messaggi secondo
sei livelli di gravità: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` e `FATAL`.

Le caratteristiche principali della libreria sono:
- Filtro selettivo dei messaggi in base al livello di gravità configurato
- Possibilità di scrittura su file di sistema log o su console
- Meccanismo di sincronizzazione tramite mutex per prevenire sovrapposizioni
di output durante accessi concorrenti
- Configurazione della precisione temporale, con risoluzione fino al
microsecondo, utile per il debugging della regolarità del controllo PID

L'utilizzo dei mutex è fondamentale per garantire l'integrità dei messaggi
di log quando più processi tentano di scrivere contemporaneamente sullo
stesso file di output.

=== Template Bash con preprocessore C

Per eliminare la duplicazione delle costanti di configurazione è stato
adottato un approccio innovativo che sfrutta il preprocessore del linguaggio
C per la generazione di script Bash.

Il procedimento si articola nelle seguenti fasi:
1. Le configurazioni globali vengono definite nel file header
`include/config.h`
2. Queste definizioni vengono utilizzate come input per template di script
3. Gli script generati sono `init.sh` per l'inizializzazione del sistema e
`run.sh` per l'avvio dei moduli
4. Il preprocessore C viene invocato attraverso il compilatore GCC con la
flag `-E`, che esegue solamente la fase di preprocessing senza compilazione,
assemblaggio o linking

Questa metodologia presenta il vantaggio significativo di mantenere tutte
le costanti di configurazione in un unico punto: modificando il file header
`config.h`, tutti gli script vengono automaticamente aggiornati con i valori
corretti, eliminando rischi di inconsistenza.

=== Procedura di esecuzione del sistema

L'avvio del sistema embedded richiede l'esecuzione sequenziale di script
dedicati, ciascuno con una funzione specifica.

Al primo avvio del dispositivo è necessario eseguire lo script
`/opt/amel/init.sh`. Questo script svolge le seguenti operazioni:
- Creazione delle directory necessarie per la gestione dei sensori di
temperatura
- Configurazione del controllo degli accessi ai file di sistema

Per l'avvio operativo del sistema viene utilizzato lo script
`/opt/amel/run.sh`, che orchestra l'esecuzione dei moduli principali:
1. Viene avviato per primo il processo principale di `temp-control`, che si
mette in attesa del segnale di sincronizzazione
2. Successivamente viene lanciato `pid-control`, il quale inizializza il bus
One-Wire e rileva il numero di sensori connessi
3. Il numero di sensori rilevato viene memorizzato nel file
`/opt/amel/number-sensors`
4. Una volta completata l'inizializzazione, `pid-control` invia il segnale
di sincronizzazione a `temp-control`
5. Entrambi i processi entrano in esecuzione normale, scambiandosi
aggiornamenti
sulla temperatura target e corrente attraverso segnali Unix generati con il
comando `kill`

=== Interfaccia web tramite CGI

Per consentire il monitoraggio e il controllo remoto del sistema è
stata implementata un'interfaccia web basata su CGI (Common Gateway
Interface). Questa soluzione permette di accedere alle funzionalità del
sistema attraverso un browser web standard.

Le funzionalità dell'interfaccia web includono:
- Visualizzazione in tempo reale della temperatura attuale rilevata dai sensori
- Modifica della temperatura target mediante pulsanti di incremento e
decremento
- Hosting diretto sul dispositivo embedded, senza necessità di infrastrutture
esterne

La comunicazione tra il server web e i moduli del sistema avviene attraverso le
stesse primitive di file system utilizzate per la comunicazione inter-modulare,
garantendo coerenza nell'accesso ai dati.


== Il modulo `temp-control`

Il modulo `temp-control` gestisce l'interfaccia utente del sistema
attraverso un display touchscreen LCD. Questo modulo consente all'operatore
di visualizzare i parametri di funzionamento e di impostare la temperatura
desiderata nella camera di collaudo.

L'interfaccia grafica è stata sviluppata utilizzando la libreria LVGL @LVGL
(Light and Versatile Graphics Library), scelta per le sue caratteristiche di
leggerezza e adattabilità ai sistemi embedded. Il punto di partenza è stato
un template @LVGL_LINUX che fornisce il porting della libreria su sistemi
operativi Linux, messo a disposizione dagli sviluppatori stessi della libreria.

=== Schermata principale

#figure(
  image("/images/lvgl-gui.png", width: 10cm),
  caption: [Interfaccia grafica per il controllo della temperatura],
) <lvgl_gui>

L'interfaccia principale presenta le seguenti informazioni:
- La temperatura target impostata dall'operatore
- La temperatura attuale rilevata dal sensore sul bus One-Wire
- Uno slider per impostare la temperatura target oppure la velocita della
ventola
- Uno switch per selezionare la modalita di controllo automatico oppure
manuale della ventola.

La disposizione degli elementi è stata progettata per garantire la massima
leggibilità e usabilita.


=== Backend per l'input/output

Il modulo utilizza due backend fondamentali per la gestione dell'input/output:
- Libevdev per la gestione degli eventi di input dal touchscreen
- Il framebuffer device per la visualizzazione grafica

Libevdev @libevdev è una libreria di astrazione per i dispositivi di
input del kernel Linux. Essa riceve gli eventi di tocco dal touchscreen
e li traduce in un formato comprensibile per l'interfaccia grafica LVGL,
gestendo automaticamente la calibrazione e la mappatura delle coordinate.

Il framebuffer device è rappresentato dal file speciale `/dev/fb0`. Questo
file contiene una rappresentazione della memoria video: scrivendo in questa
memoria, la libreria LVGL aggiorna direttamente i pixel visualizzati sullo
schermo LCD. Questo approccio garantisce bassa latenza e ridotto overhead
computazionale.

=== Configurazione della cross-compilazione

La compilazione dell'applicazione richiede una toolchain specifica per
l'architettura ARM del dispositivo target. Nel presente progetto si è
fatto affidamento sul compilatore GCC e sulle librerie fornite dal sistema
di build Buildroot.

==== Configurazione della toolchain

#figure(
  caption: "Configurazione della toolchain per la cross-compilazione
  (cross_compile_setup.cmake)",
  sourcecode(
    ```c
    set(CMAKE_SYSTEM_NAME Linux)
    set(CMAKE_SYSTEM_PROCESSOR arm)

    set(tools ~/buildroot/output/host/bin/arm-buildroot-linux-gnueabihf-)
    set(CMAKE_C_COMPILER ${tools}gcc)
    set(CMAKE_CXX_COMPILER ${tools}g++)

    set(EVDEV_INCLUDE_DIRS ~/buildroot/output/staging/usr/include/libevdev/)
    set(EVDEV_LIBRARIES ~/buildroot/output/staging/usr/lib/libevdev.so)

    set(BUILD_SHARED_LIBS ON)
    ```,
  ),
)

Il file di configurazione CMake definisce i seguenti parametri:
- Il sistema operativo di destinazione (Linux) e l'architettura del processore
(ARM)
- Il percorso del compilatore GCC e del compilatore C++ specifici per la
toolchain
- Le directory di inclusione e le librerie per libevdev
- La modalità di compilazione delle librerie condivise

La generazione dei makefile avviene tramite il comando:
`cmake -DCMAKE_TOOLCHAIN_FILE=./cross_compile_setup.cmake -B build -S .`

Successivamente, la compilazione vera e propria viene eseguita con:
`make -C build -j` @cmake

La libreria LVGL viene compilata come libreria condivisa (shared library),
mentre l'applicazione principale viene generata come eseguibile standalone.

=== Strategia di branching per lo sviluppo

Per organizzare efficientemente il codice sorgente durante le diverse fasi
del progetto è stata adottata una strategia di branching basata su due
repository principali: una dedicata allo sviluppo su PC e una destinata al
dispositivo embedded.

Le due repository presentano una differenza sostanziale nel file `lv_conf.h`,
che contiene la configurazione specifica della libreria LVGL:

- Branch di sviluppo: utilizza il backend `x11` per la visualizzazione su
desktop Linux e include controlli di coerenza (sanity check) utili durante
il debugging, ma penalizzanti in termini di performance
- Branch target: disabilita i sanity check e utilizza il backend `/dev/fb0`
per l'accesso diretto al framebuffer del dispositivo embedded

Per preservare le diverse configurazioni durante le operazioni di merge
è stato configurato il file `.gitattributes` con la direttiva `lv_conf.h
merge=ours`. Questa impostazione istruisce Git a mantenere sempre la versione
del file presente nella branch corrente durante le operazioni di fusione,
prevenendo sovrascritture accidentali delle configurazioni specifiche.

== Il modulo `pid-control`

Il modulo `pid-control` rappresenta il nucleo computazionale del sistema,
responsabile dell'acquisizione dei dati dai sensori, dell'elaborazione del
controllo PID e della comunicazione con l'attuatore (l'inverter della ventola).

=== Acquisizione dati dai sensori di temperatura

Il sensore di temperatura utilizzato e un dispositivo DS18B20 @DS18B20
su un bus 1-Wire.

Il microcontrollore agisce come master sul bus, interrogando periodicamente
il sensore per ottenere le misurazioni di temperatura. L'eseguibile PID esegue
ciclicamente le seguenti operazioni:
1. Lettura della temperatura dal sensore
2. Calcolo dell'output del controllore PID in base alla temperatura misurata
e al setpoint desiderato
3. Aggiornamento del comando per l'inverter

La procedura di inizializzazione dei sensore avviene in tre fasi distinte:
1. Conteggio del numero di sensori presenti sul bus
2. Allocazione della memoria necessaria per memorizzare gli identificatori
univoci (UUID) dei sensori
3. Lettura e memorizzazione degli UUID in strutture dati dedicate

Questo approccio a due fasi è preferibile rispetto a una lettura continua del
bus, in quanto evita chiamate ripetute alla funzione `DS18X20_find_sensor`,
riducendo l'overhead computazionale. La memoria allocata per gli UUID viene
mantenuta per tutta la durata dell'esecuzione del programma, rappresentando
un trade-off accettabile tra utilizzo di memoria e efficienza computazionale.

#figure(
  caption: `pid/src/main.c`,
  sourcecode[```c
    typedef struct
    {
        char id[16];
        int16_t temperature;
        uint8_t uint_id[OW_ROMCODE_SIZE];
    } sensor;

    void init_onewire_sensors()
    {
        uint8_t diff = OW_SEARCH_FIRST;

        while (diff != OW_LAST_DEVICE)
        {
            sensors_count++;
            DS18X20_find_sensor(&diff, id);
        }

        write_char_to_file(NUMBER_OF_SENSORS_FILE, sensors_count);
        LOG_INFO("Found %d sensors on the 1-wire bus", sensors_count);

        sensors = malloc(sizeof(sensor) * sensors_count);

        diff = OW_SEARCH_FIRST;
        int i = 0;
        while (diff != OW_LAST_DEVICE)
        {
            DS18X20_find_sensor(&diff, id);
            sensor s;
            for (int i = 0; i < OW_ROMCODE_SIZE; i++)
            {
                s.uint_id[i] = id[i];
            }
            sprintf(s.id, "%02hx%02hx%02hx%02hx%02hx%02hx%02hx%02hx",
            id[0], id[1],
                  id[2], id[3], id[4], id[5], id[6], id[7]);
            s.temperature = 0;
            sprintf(s.file, CURRENT_TEMPERATURE_FILE "/s%d", i);
            LOG_INFO("sensor %d id %s", i, s.id);
            sensors[i] = s;
            i++;
        }
    }
   ```],
)

==== Controllo di integrità CRC-8

Per garantire l'affidabilità dei dati trasmessi dal sensore
al microcontrollore è stato implementato un meccanismo di controllo di
integrità basato sull'algoritmo CRC-8 (Cyclic Redundancy Check a 8 bit).

L'algoritmo utilizza il polinomio 0x18, corrispondente alla rappresentazione
matematica $x^8 + x^5 + x^4 + x^0$. Questo polinomio generatore viene applicato
ai dati dello scratchpad del sensore per calcolare un valore di checksum.

Il processo di verifica si svolge come segue:
1. Il sensore trasmette i dati di temperatura insieme al valore CRC calcolato
2. Il microcontrollore ricalcola il CRC sui dati ricevuti
3. Se il valore calcolato corrisponde a quello ricevuto, i dati sono
considerati validi
4. In caso di discrepanza, la lettura viene scartata e può essere ritentata
nel ciclo successivo

Questo meccanismo è fondamentale per prevenire azioni di controllo basate
su dati corrotti, che potrebbero compromettere la stabilità del sistema.

=== Comunicazione MODBUS RTU

Per il comando dell'inverter che regola la velocità della ventola di
raffreddamento è stato adottato il protocollo di comunicazione MODBUS RTU
(Remote Terminal Unit). Questo protocollo seriale è uno standard industriale
per la comunicazione tra dispositivi elettronici.

L'implementazione del protocollo si avvale della libreria open source
`libmodbus` @libmodbus, che fornisce un'interfaccia di alto livello per la
gestione delle comunicazioni MODBUS. La libreria gestisce automaticamente:
- La codifica e decodifica dei frame di comunicazione
- Il calcolo del checksum
- La gestione degli errori di trasmissione
- Il timeout delle risposte

=== Algoritmo di controllo PID

Il controllore PID (Proporzionale, Integrale, Derivativo) è un sistema di
retroazione negativa ampiamente utilizzato nell'industria per il controllo
di processi. Il suo principio di funzionamento si basa sulla correzione
continua di un errore rispetto a un valore di riferimento desiderato.

Nel contesto del presente sistema, il controllore PID svolge le seguenti
funzioni:
1. Acquisisce in ingresso la temperatura misurata dai sensori
2. Confronta il valore misurato con il setpoint di temperatura desiderato
3. Calcola l'errore come differenza tra setpoint e valore misurato
4. Elabora l'errore attraverso tre componenti:
  - Il termine proporzionale, che reagisce all'entità dell'errore istantaneo
  - Il termine integrale, che elimina l'errore residuo nel tempo
  - Il termine derivativo, che anticipa le variazioni future dell'errore
5. Produce in uscita un segnale di comando che viene convertito in tensione
per l'inverter
6. L'inverter regola di conseguenza la frequenza di rotazione della ventola
di raffreddamento

==== Gestione temporale con monotonic clock

Per garantire la corretta esecuzione dell'algoritmo PID è fondamentale
mantenere una frequenza di campionamento costante. La variabilità del
periodo di campionamento comprometterebbe l'efficacia dei calcoli integrale
e derivativo.

A questo scopo è stato utilizzato il meccanismo dei timer file descriptor
fornito dall'header `<sys/timerfd.h>` della Standard C Library. Questa API
del kernel Linux consente di:
1. Creare un timer che scade a intervalli regolari e predefiniti
2. Ricevere notifiche di scadenza attraverso un file descriptor
3. Utilizzare un clock monotonico, che non è influenzato da variazioni
dell'ora di sistema

L'utilizzo del monotonic clock garantisce che il periodo di campionamento
rimanga costante anche in presenza di aggiustamenti dell'orologio di sistema
o di sincronizzazioni NTP.

==== Gestione delle priorità dello scheduler

Per minimizzare le interferenze durante le operazioni critiche di misurazione
e controllo, al processo è stata assegnata la massima priorità di esecuzione
disponibile per lo scheduler del kernel Linux. Questa configurazione viene
impostata attraverso le funzioni definite nell'header `<sched.h>`.

Le ragioni di questa scelta sono:
- Prevenire l'interruzione del processo di campionamento da parte di processi
a priorità inferiore
- Ridurre la latenza nella risposta agli eventi del timer
- Mantenere la massima regolarità possibile nel periodo di campionamento

L'assegnazione della priorità massima richiede privilegi di amministratore
(root), coerentemente con il fatto che il modulo viene eseguito come servizio
di sistema.

=== Pannello di amministrazione

Il modulo include funzionalità per la configurazione e la manutenzione del
sistema, accessibili attraverso un'interfaccia dedicata. Queste funzioni
consentono di:
- Visualizzare lo stato operativo del sistema
- Modificare i parametri del controllore PID
- Eseguire operazioni diagnostiche sui sensori

=== Sistema di logging e monitoraggio

Per consentire l'analisi dell'andamento del controllo nel tempo e per
facilitare le operazioni di debugging è stata implementata una funzionalità
di logging su file in formato CSV (Comma Separated Values).

La procedura di logging si articola nelle seguenti fasi:
1. All'avvio del programma viene generato un file CSV con un nome basato sul
timestamp corrente, garantendo l'unicità del file
2. L'intestazione del file contiene i nomi delle colonne: tempo, temperatura
target, temperature dei singoli sensori, output del PID
3. Ad ogni ciclo di esecuzione del controllo, i valori correnti vengono
aggiunti come nuova riga del file
4. Il file può essere successivamente analizzato mediante strumenti software
o fogli di calcolo per valutare le prestazioni del sistema

Questo approccio di logging strutturato consente di:
- Ricostruire la cronologia delle operazioni del sistema
- Analizzare la risposta del controllore a variazioni del setpoint
- Identificare eventuali anomalie nel comportamento dei sensori
- Ottimizzare i parametri del PID mediante analisi dei dati storici
