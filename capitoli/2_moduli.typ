#import "@local/uninsubria-thesis:0.1.0": sourcecode
= Architettura dei Moduli Software

== Modulo `common-control`

Il modulo `common-control` rappresenta il componente fondamentale
dell'architettura software, fornendo l'infrastruttura condivisa necessaria
per il coordinamento degli altri moduli. Questo modulo contiene un insieme
di funzioni di utilità, header di configurazione globale e script di sistema
essenziali per l'inizializzazione e l'avvio coordinato dell'intero sistema.

L'architettura prevede l'utilizzo della directory di sistema `/opt/amel/`
come repository centrale per tutti gli script, i file di configurazione e i
dati condivisi tra i differenti moduli, garantendo una gestione centralizzata
e standardizzata delle risorse di sistema.

=== Sistema di Comunicazione Inter-modulo

Per garantire un efficace coordinamento tra i moduli `temp-control` e
`pid-control`, è stata implementata un'architettura di comunicazione basata
su meccanismi di segnalazione e scrittura su file. Questo approccio combina
la semplicità dello scambio dati tramite file system con l'efficienza della
comunicazione asincrona tramite segnali di sistema.

Il flusso comunicativo segue un schema ben definito: quando un operatore
modifica la temperatura target attraverso l'interfaccia touchscreen, il nuovo
valore viene immediatamente persistito nel file `/opt/amel/target-temperature`,
rendendolo disponibile per il processo di controllo.

In modo simmetrico, il processo PID, periodicamente acuisce i dati dai
sensori di temperatura DS18B20 @DS18B20 e scrive i valori rilevati nei file
`/opt/amel/current-temperature/sX`, dove X rappresenta l'identificativo
univoco del sensore sul bus 1-Wire. Immediatamente dopo l'aggiornamento dei
file, il processo `pid-control` invia un segnale al modulo `temp-control`, il
quale provvede a leggere i dati aggiornati e a refreshare la visualizzazione
delle temperature sensoriali sull'interfaccia grafica.

=== Libreria di Logging `logging.h`

Per garantire un monitoraggio efficace e un'analisi approfondita del
comportamento del sistema, è stata implementata una libreria di logging
in C che offre funzionalità avanzate di registrazione eventi. La libreria
supporta una gerarchia completa di livelli di logging, inclusi `TRACE`,
`DEBUG`, `INFO`, `WARN`, `ERROR` e `FATAL`, permettendo una granularità
fine nella selezione dei messaggi da registrare.

Il sistema offre flessibilità configurabile nella gestione dell'output,
consentendo di scegliere tra scrittura su console, registrazione nel syslog
di sistema, o entrambe. È possibile definire dinamicamente il livello minimo
di filtro, ottimizzando il volume di informazioni registrate in base alle
esigenze operative.

La libreria implementa meccanismi di sincronizzazione tramite mutex per
prevenire race condition e garantire la consistenza dei log in ambienti
multi-threading. È stata inoltre introdotta un'opzione configurabile per la
precisione temporale dei timestamp, particolarmente utile durante le fasi di
debug per analizzare la regolarità e la precisione del ciclo di controllo PID.

=== Sistema di Templating Bash tramite Preprocessore C

Per eliminare ridondanze e garantire la consistenza configurativa attraverso
l'intero sistema, è stato implementato un approccio innovativo che sfrutta
il preprocessore del linguaggio C per la generazione di script Bash. Questa
soluzione consente di centralizzare tutte le definizioni di configurazione
nell'header `include/config.h`, utilizzandolo come sorgente unica di verità
per la generazione degli script di sistema.

Il processo di generazione avviene mediante l'utilizzo di GCC con la flag `-E`,
che attiva esclusivamente la fase di preprocessing, evitando le successive fasi
di compilazione, assemblaggio e linking. Gli script risultanti, `init.sh`
e `run.sh`, vengono generati automaticamente a partire dai template che
incorporano le costanti definite nell'header di configurazione.

Questo approccio offre significativi vantaggi in termini di manutenibilità:
qualsiasi modifica ai parametri di configurazione richiede l'intervento su un
unico file, con propagazione automatica delle modifiche a tutti gli script
derivati, eliminando così potenziali errori di inconsistenza e riducendo
significativamente lo sforzo di manutenzione.

=== Sequenza di Avvio del Sistema

La procedura di avvio del sistema è strutturata in due fasi distinte
per garantire una corretta inizializzazione e un avvio ordinato dei
componenti. Durante la prima esecuzione del dispositivo embedded, è necessario
eseguire lo script `/opt/amel/init.sh`, che provvede a creare le directory
di sistema necessarie per il funzionamento dei sensori di temperatura e a
configurare i meccanismi di controllo degli accessi.

Per l'avvio operativo del sistema, lo script `/opt/amel/run.sh` coordina il
lancio sequenziale dei componenti principali. La sequenza di avvio segue un
ordine preciso:

1. *Inizializzazione dell'interfaccia grafica*: Viene avviato prima il
processo principale di `temp-control`, che si pone in stato di attesa dei
segnali provenienti dal modulo di controllo PID.

2. *Avvio del controllore PID*: Successivamente viene lanciato il processo
`pid-control`, che esegue l'inizializzazione del bus 1-Wire, rileva il
numero di sensori disponibili e persiste questa informazione nel file
`/opt/amel/number-sensors`.

3. *Sincronizzazione dei moduli*: Una volta completata l'inizializzazione,
il processo `pid-control` invia un segnale di notifica a `temp-control`,
avviando così la fase operativa congiunta.

Durante il funzionamento, i due processi mantengono una comunicazione
costante attraverso segnali di sistema generati tramite il comando `kill`,
permettendo l'aggiornamento in tempo reale sia dei setpoint di temperatura
target che dei valori effettivi misurati.

== Modulo `temp-control`

Il modulo `temp-control` costituisce l'interfaccia primaria di interazione
tra l'operatore e il sistema di controllo climatico. Attraverso un display
touchscreen LCD dedicato, l'utente può monitorare lo stato del sistema
e regolare dinamicamente la temperatura target desiderata per la camera
di collaudo.

L'interfaccia grafica è stata sviluppata utilizzando la libreria LVGL @LVGL,
un framework versatile e ottimizzato per sistemi embedded. Per l'integrazione
con l'ecosistema Linux, è stato utilizzato il template @LVGL_LINUX, che
fornisce il porting ufficiale della libreria per ambienti Linux, garantendo
compatibilità e prestazioni ottimali sulla piattaforma target.


=== Interfaccia Utente Principale

#figure(
  image("/images/lvgl-gui.png", width: 10cm),
  caption: [Interfaccia grafica utente per il controllo della temperatura
  ambientale],
) <lvgl_gui>

L'interfaccia utente principale presenta un design pulito e funzionale,
ottimizzato per l'operatività in ambienti industriali. L'layout è organizzato
per garantire un'immediata comprensione dello stato del sistema e un controllo
intuitivo dei parametri operativi:

- *Visualizzazione del setpoint*: Viene mostrato in modo prominente il valore
della temperatura target attualmente configurata.

- *Monitoraggio sensoriale*: Vengono visualizzati in tempo reale i valori di
temperatura rilevati da tutti i sensori collegati sul bus 1-Wire, permettendo
un monitoraggio completo della distribuzione termica all'interno della camera
di collaudo.

- *Controlli di regolazione*: Due pulsanti dedicati permettono di incrementare
o decrementare la temperatura target con passo unitario, fornendo un controllo
preciso e immediato del setpoint desiderato.
// === Funzioni di callback nel ciclo principale della GUI LVGL

#figure(
  sourcecode[```c
  void set_target_temperature(float t)
  {
      LOG_DEBUG("debug callback -> %.1f\n", target_temperature);
      target_temperature += t;
      lv_label_set_text_fmt(target_temperature_label,
      target_temperature_format, target_temperature);
      write_float_to_file(TARGET_TEMPERATURE_FILE, target_temperature);
      kill(PID_control_PID, SIGUSR1);
  }

  static void increment_temperature(lv_event_t - e)
  {
      if(lv_event_get_code(e) != LV_EVENT_CLICKED) {
          return;
      }
      set_target_temperature(1);
  }

  static void decrement_temperature(lv_event_t - e)
  {
      if(lv_event_get_code(e) != LV_EVENT_CLICKED) {
          return;
      }
      set_target_temperature(-1);
  }
  ```],
  caption: "Funzioni di callback per i bottoni di incremento e decremento
  della temperatura target",
)

Quando l'operatore interagisce con i pulsanti di regolazione, il sistema
attiva una catena di operazioni coordinate che garantiscono l'immediatezza
della risposta e la consistenza dei dati. La pressione di un pulsante determina
l'esecuzione di una funzione di callback che provvede simultaneamente a:

1. Aggiornare l'etichetta visuale sul display per riflettere immediatamente
la modifica del setpoint;
2. Persistere il nuovo valore nel file di sistema dedicato, garantendo la
comunicazione al modulo PID;
3. Notificare il processo di controllo tramite segnale per attivare
l'adeguamento del sistema di raffreddamento.

Questo approccio garantisce una用户体验 fluida e un controllo reattivo
del sistema.

=== Sistema di Input/Output

L'infrastruttura I/O dell'interfaccia LVGL si basa su due componenti
fondamentali, selezionati per la loro efficienza e compatibilità con ambienti
embedded a risorse limitate:

- *Libevdev @libevdev*: Questa libreria specializzata gestisce l'acquisizione e
l'elaborazione degli eventi di input provenienti dal touchscreen. Il suo ruolo
consiste nel ricevere i segnali tattili, convertirli in eventi standardizzati
e trasmetterli al motore grafico LVGL per l'elaborazione.

- *Framebuffer device*: Il dispositivo `/dev/fb0` rappresenta l'interfaccia
hardware di output grafico. La GUI scrive direttamente su questo file system
device, il quale contiene la mappa dei pixel dello schermo, permettendo un
rendering diretto e ottimizzato dell'interfaccia visuale senza intermediari
software aggiuntivi.

=== Processo di Cross-compilazione

La compilazione dell'applicazione GUI per la piattaforma embedded richiede
l'utilizzo di una toolchain specializzata per l'architettura ARM. Il sistema
si avvale della toolchain fornita da Buildroot, che include compilatori,
linker e librerie ottimizzate per il target specifico.

==== Configurazione del Toolchain
#figure(
  caption: "cross_compile_setup.cmake - Configurazione del sistema di
  cross-compilazione",
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

Il processo di generazione del sistema di build viene avviato tramite
il comando:

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=./cross_compile_setup.cmake -B build -S .
```

Questo comando istruisce CMake a generare i Makefile necessari per
la cross-compilazione, specificando la toolchain ARM e le dipendenze
richieste. La successiva esecuzione di `make -C build -j` @cmake avvia il
processo di compilazione parallelo.

L'architettura del build prevede la compilazione di LVGL come libreria
condivisa dinamica, mentre l'applicazione principale viene generata come
eseguibile standalone. Questo approccio ottimizza l'utilizzo della memoria
e facilita gli aggiornamenti futuri dei componenti.



=== Strategia di Branching

Per ottimizzare il flusso di sviluppo e garantire la corretta separazione
tra ambiente di sviluppo e dispositivo target, è stata implementata una
strategia di branching basata su due repository parallele. Questa architettura
permette di mantenere distinti i profili di configurazione ottimizzati per
i differenti contesti operativi.

Le due repository sono strutturalmente identiche, ad eccezione del file di
configurazione `lv_conf.h`, che contiene i parametri specifici per ciascun
ambiente:

- *Branch di sviluppo*: Configurata con backend X11 per l'esecuzione su
workstation di sviluppo. Include controlli di validazione (sanity checks) che
facilitano il debug e la prevenzione di errori durante la fase di sviluppo,
ma che introducono un overhead di performance non accettabile in produzione.

- *Branch target*: Ottimizzata per il dispositivo embedded, con sanity
checks disabilitati per massimizzare le prestazioni. Utilizza come backend
il framebuffer device `/dev/fb0` per il rendering diretto sull'hardware target.

Per garantire l'integrità delle configurazioni specifiche, è stato
implementato un meccanismo di protezione del file `lv_conf.h` tramite il file
`.gitattributes` con la direttiva `lv_conf.h merge=ours`. Questa configurazione
speciale istruisce Git a mantenere la versione del file presente nella branch
di destinazione durante le operazioni di merge, prevenendo sovrascritture
accidentali e garantendo la persistenza delle configurazioni specifiche per
ogni ambiente.


== Modulo `pid-control`

=== Gestione dei Sensori di Temperatura

Il sistema di monitoraggio termico si basa su due sensori di temperatura
digitali DS18B20 @DS18B20, collegati in configurazione parallela su un singolo
bus di comunicazione 1-Wire. Questa architettura permette di massimizzare
l'efficienza cabling semplificando significativamente l'infrastruttura
hardware.

Il microcontrollore opera come master del bus 1-Wire, avviando periodicamente
sequenze di interrogazione per acquisire i dati di temperatura da ciascun
sensore. Il processo principale del controllore PID esegue ciclicamente le
operazioni di lettura dei sensori e calcola l'output di controllo basandosi
sulla differenza tra la temperatura misurata e il setpoint desiderato.

La procedura di inizializzazione dei sensori segue un approccio ottimizzato
per garantire robustezza ed efficienza:

1. *Enumerazione dei sensori*: Il sistema prima determina il numero esatto
di sensori presenti sul bus, allocando dinamicamente la memoria necessaria
per memorizzare gli identificativi univoci (UUID) di ciascun dispositivo.

2. *Acquisizione degli identificativi*: Successivamente, il sistema legge e
memorizza gli UUID di tutti i sensori rilevati, creando una mappa persistente
del bus.

Questa strategia, sebbene richieda un consumo di memoria leggermente superiore,
offre significativi vantaggi in termini di efficienza operativa. L'alternativa
di rilevare gli identificativi dei sensori ad ogni ciclo di lettura
comporterebbe chiamate ripetute alla funzione `DS18X20_find_sensor`, generando
un inutile consumo di cicli CPU e introducendo latenza nel processo di
acquisizione dati. L'approccio adottato esegue la procedura di discovery una
sola volta all'avvio, con un impatto trascurabile sulle performance globali
del sistema.

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

        sensors = malloc(sizeof(sensor) - sensors_count);

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

=== Comunicazione MODBUS RTU

Per l'interfacciamento con l'inverter che governa il funzionamento della
ventola di raffreddamento, è stata implementata una soluzione basata
sul protocollo di comunicazione industriale MODBUS RTU. Questo standard,
ampiamente diffuso negli ambienti automazione industriale, garantisce
affidabilità, interoperabilità e robustezza nella comunicazione seriale.

L'implementazione si avvale della libreria `libmodbus` @libmodbus, che fornisce
un'interfaccia C standardizzata per la gestione delle comunicazioni MODBUS,
semplificando significativamente lo sviluppo e garantendo la conformità
con le specifiche del protocollo.

=== Algoritmo di Controllo PID

Il sistema di controllo PID (Proporzionale-Integrale-Derivativo) rappresenta il
cuore logico del sistema di regolazione termica. Si tratta di un controller a
retroazione negativa che elabora continuamente l'errore tra il valore misurato
e il setpoint desiderato per generare un segnale di controllo ottimizzato.

Nel contesto specifico della camera di collaudo, l'algoritmo PID opera
mantenendo stabile la temperatura ambiente. Il controller riceve in input due
parametri fondamentali: la temperatura effettivamente rilevata dai sensori
e il setpoint target impostato dall'operatore. Sulla base di questi dati,
calcola il valore di tensione da trasmettere all'inverter, che a sua volta
modula la frequenza di rotazione della ventola di raffreddamento.

La sintonizzazione dei parametri PID è stata eseguita mediante metodologie
sperimentali che combinano l'analisi della risposta del sistema con criteri di
stabilità e prestazione. Il coefficiente proporzionale (P) è stato calibrato
per garantire una risposta rapida agli errori di temperatura, mentre il
termine integrale (I) è stato ottimizzato per eliminare l'errore stazionario
e garantire il raggiungimento del setpoint in condizioni steady-state.

Il termine derivativo (D) è stato volutamente escluso dalla configurazione
finale. Questa decisione si basa sull'analisi delle caratteristiche dinamiche
del sistema termico, che presenta una costante di tempo relativamente elevata
e una risposta intrinsecamente lenta. In tali condizioni, l'azione derivativa
introdurrebbe principalmente rumore di misurazione amplificato senza fornire
contributi significativi alla qualità del controllo, oltre a potenzialmente
causare instabilità nel comportamento del regolatore.

==== Gestione del Timing Basata su Monotonic Clock

La precisione temporale nel campionamento della temperatura riveste un ruolo
critico per il corretto funzionamento dell'algoritmo PID. Per garantire una
frequenza di campionamento costante e immune a variazioni sistemiche, è
stata implementata una soluzione basata sull'interfaccia `<sys/timerfd.h>`
della Standard C Library.

Questo approccio utilizza il sistema di monotonic clock del kernel Linux,
che fornisce una misura del tempo immune a modifiche manuali dell'orologio
di sistema. Le chiamate di sistema timerfd creano e gestiscono un timer
ad alta precisione che genera eventi di scadenza a intervalli regolari,
comunicati tramite un file descriptor.

Questo metodo offre significativi vantaggi rispetto alle soluzioni tradizionali
basate su sleep o busy-waiting:
- Precisione temporale consistente e riproducibile
- Minimo overhead CPU in attesa degli eventi temporali
- Immunità a variazioni dell'orologio di sistema
- Integrazione nativa con i meccanismi di I/O multiplexing del kernel

==== Ottimizzazione della Priorità di Scheduling

Per massimizzare la determinismo del sistema di controllo e garantire la
massima regolarità possibile nel ciclo di campionamento, è stato implementato
un meccanismo di ottimizzazione della priorità di scheduling. Mediante
l'utilizzo dell'header `<sched.h>`, al processo PID viene assegnata la
priorità più elevata disponibile nel sistema di scheduling real-time.

Questa configurazione garantisce che il processo di controllo abbia
precedenza sulla maggior parte delle altre attività di sistema, riducendo
significativamente la probabilità di preemption da parte di altri processi
e minimizzando la latenza nell'esecuzione del ciclo di controllo.

I benefici di questo approccio includono:
- Riduzione del jitter temporale nelle operazioni di campionamento
- Migliore prevedibilità dei tempi di risposta del controller
- Minore impatto delle attività di sistema sull'algoritmo PID
- Maggiore stabilità complessiva del sistema di controllo

Questa ottimizzazione è particolarmente critica considerando che il sistema
opera su una piattaforma embedded con risorse limitate e dove la regolarità
temporale del ciclo di controllo influenza direttamente la qualità della
regolazione termica.


=== Sistema di Amministrazione e Monitoraggio

Il modulo `pid-control` integra funzionalità avanzate di amministrazione e
monitoraggio che consentono una gestione completa del sistema operativo. Queste
capacità permettono non solo di supervisionare il funzionamento corrente,
ma anche di diagnosticare eventuali anomalie e ottimizzare le prestazioni
nel tempo.

Il sistema di logging, integrato con il modulo `common-control`, fornisce
una registrazione dettagliata di tutti gli eventi significativi, includendo
letture sensoriali, calcoli di controllo, comunicazioni con l'inverter e
stati di errore. Questi dati sono essenziali per l'analisi post-mortem e
per l'identificazione di trend di comportamento a lungo termine.

Sono inoltre implementati meccanismi di monitoraggio real-time che permettono
di verificare la salute del sistema, controllare la regolarità dei cicli di
campionamento e validare la correttezza delle comunicazioni MODBUS. Queste
funzionalità contribuiscono a garantire l'affidabilità e la robustezza
del sistema di controllo climatico.
