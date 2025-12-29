#import "@local/uninsubria-thesis:0.1.0": sourcecode
= Moduli

== `common-control`
Il modulo `common-control` contiene funzioni helper comuni, header di configurazione globale e script per inizializzare e avviare l'intero sistema.

=== Comunicazione tra GUI e PID
Per fare in modo che i moduli `temp-control` e `pid-control` comunichino tra di loro e stato necessario sviluppare un sistema di segnali e scrittura e lettura su file.

Quando un operatore cambia la temperatura target dall'interfaccia sul display LCD essa viene scritta sul file `/opt/amel/target-temperature`.

Analogamente, il processo pid quando rileva una temperatura tramite i sensori DS18B20, scrive quest'ultima sul file `/opt/amel/current-temperature/sX`,
con x che rappresenta il numero del sensore sul bus. Subito dopo aver scritto, viene mandato un segnale a `temp-control`, che a sua volta legge il file e aggiorna
la temperatura del sensore spiegato successivamente.

=== `logging.h`
Per stampare a schermo in modo ordinato i messaggi dell'applicazione e stato implementata una semplice libreria in c che consente di loggare,
anche con strighe formattate, ai livelli `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` e `FATAL`.
Si puo decidere a che livello filtrare i messaggi e anche se scrivere su file nel syslog o sulla console.

Per evitare che piu log si sovrascrivino a vicenda viene utilizzato un meccanismo di mutex.
E stata aggiunta un opzione per decidere la precisione del timer per intervalli di tempo sotto al secondo, utile per debuggare la regolarita del controllo pid.

=== `bash` templating with c preprocessor
Per evitare duplicazioni di costanti all'interno del modulo, e stato utilizzato il preprocessore del linguaggio c in modo creativo.
Avendo definito le configurazioni in `include/config.h`, sono state utilizzate come input per dei template dal quale si ricavano gli script
di inizializzazione e di avvio dell'intero progetto, rispettivamente `init.sh`  e `run.sh`. Facendo compilare `gcc` con la flag `-E` possiamo
sfruttare il preprocessore senza effettuare compilazione, assemblaggio e linking.

In questo modo e necessario cambiare le variabili solamente nell'header di configurazione per averle aggiornate anche negli script.

=== Esecuzione del modulo
La prima volta che si avvia il dispositivo embedded e necessario 

== `temp-control`

Per controllare la temperatura della camera di collaudo, l'operatore imposta la temperatura target mediante un display touchscreen LCD "NOME DISPLAY".
L'interfaccia grafica è sviluppata utilizzando la libreria LVGL @LVGL e si è utilizzato un template @LVGL_LINUX contenente il porting su Linux fornito dagli sviluppatori della libreria.

Nell'interfaccia vengono mostrate temperatura target, temperatura attuale dei sensori collegati sul bus one-wire e due bottoni per aumentare e diminuire la temperatura
target.
// === Funzioni di callback nel ciclo principale della GUI LVGL

#figure(
  sourcecode[```c
  void set_target_temperature(float t)
  {
      LOG_DEBUG("debug callback -> %.1f\n", target_temperature);
      target_temperature += t;
      lv_label_set_text_fmt(target_temperature_label, target_temperature_format, target_temperature);
      write_float_to_file(TARGET_TEMPERATURE_FILE, target_temperature);
      kill(pid_control_pid, SIGUSR1);
  }

  static void increment_temperature(lv_event_t * e)
  {
      if(lv_event_get_code(e) != LV_EVENT_CLICKED) {
          return;
      }
      set_target_temperature(1);
  }

  static void decrement_temperature(lv_event_t * e)
  {
      if(lv_event_get_code(e) != LV_EVENT_CLICKED) {
          return;
      }
      set_target_temperature(-1);
  }
  ```],
  caption: "Funzioni di callback per i bottoni di incremento e decremento della temperatura target",
)

Quando viene premuto il pulsante per aumentare o diminuire la temperatura target, viene invocata una funzione di callback che si occupa di aggiornare la `label` con
la temperatura target sullo schermo e di scriverla nell'apposito file.

I backend utilizzati da LVGL per l'I/O sono libevdev e il framebuffer device. Sono stati scelti per la loro semplicità e il ridotto utilizzo di risorse.

Libevdev @libevdev è una libreria che gestisce gli eventi di input: riceve i tocchi dal touchscreen e li passa all'interfaccia grafica.

Il framebuffer device è semplicemente il file `/dev/fb0`, scritto dalla GUI, che contiene il colore di ciascun pixel dello schermo.

=== Compilazione della GUI

Per la compilazione dell'applicazione è necessaria una toolchain adatta all'architettura ARM. Nel nostro caso, ci affidiamo al compilatore e alle librerie fornite da Buildroot.

==== `cross_compile_setup.cmake`
#figure(
  caption: "cross_compile_setup.cmake",
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

Il comando `cmake -DCMAKE_TOOLCHAIN_FILE=./cross_compile_setup.cmake -B build -S .` genera i Makefile necessari per la cross-compilazione, che vengono
poi eseguiti con `make -C build -j`.

LVGL viene compilata come libreria condivisa, mentre l'applicazione come eseguibile.

#figure(
  image("/images/lvgl-gui.png", width: 10cm),
  caption: [Interfaccia grafica per il controllo della temperatura],
) <lvgl_gui>

=== Branches
Per organizzare efficientemente la repository sorgente, e stato realizzato un branching, creando una repository per lo sviluppo ed una per il dispositivo target.
Esse sono uguali completamente tranne per il file `lv_conf.h`.

Per la branch di sviluppo, esso usa come backend `x11` e contiene dei sanity check, utili in sviluppo ma limitanti in termini di performance.

Per la branch del dispositivo target sono stati disabilitati i sanity checks e utilizzata come backend il device `/dev/fb0`.

Per proteggere il file `lv_conf.h` e stato aggiunto un file `.gitattributes` contenente `lv_conf.h merge=ours`.

Questo speciale file di git, comunica al version control system che durante il merge delle branch di mantenere il file come si trova nella branch da cui si sta effettuando il merge, consentendo di mantenere separate le due configurazioni senza preoccuparsi di sovrascriverle accidentalmente.


== `pid-control`
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
            sprintf(s.id, "%02hx%02hx%02hx%02hx%02hx%02hx%02hx%02hx", id[0], id[1],
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

=== MODBUS RTU
Per comunicare con l'inverter che controlla la ventola di raffreddamento, è stato utilizzato il protocollo MODBUS RTU tramite l'apposita libreria `libmodbus`.

=== Controllo pid
Il controllo pid (Proporzionale, Integrale e Derivativo) e un sistema di retroazione negativa che permette di reagire ad un errore rispetto ad un valore target.

Esso viene utilizzato per mantenere la temperatura costante nella camera di collaudo. Prende in input la temperatura rilevate dai sensori e la temperatura desiderata
all'interno della stanza e restituisce in output la tensione con la quale comunichiamo all'inverter la frequenza della ventola di raffreddamento.

// Scrivere qui come abbiamo scelto i vari coefficienti PID

Non e stato utilizzato il coefficiente derivativo perche

==== Monotonic clock

Per campionare la temperatura nella stanza ad una frequenza costante, fondamentale per un corretto calcolo PID, e stato utilizzato l'header `<sys/timerfd.h>`
della `Standard C library`.
Queste chiamate di sistema creano e operano su un timer che consegna segnali di scadenza del timer ad intervalli regolari tramite un file descriptor.

==== Scheduler priority

E stata assegnata la massima priorita di scheduler al programma tramite l'header `<sched.h>` per evitare interrupt durante la misurazione e per cercare di
mantenere piu costante possibile la periodicita del campionamento.




=== Admin Control

=== Logging and Monitoring
