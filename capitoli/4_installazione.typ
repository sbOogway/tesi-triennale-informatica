#import "@preview/unofficial-uninsubria-thesis:0.1.0": sourcecode

= Installazione del sistema

== Configurazione della comunicazione con l'inverter

La comunicazione con l'inverter tramite protocollo MODBUS richiede una
configurazione preliminare del dispositivo. Questa operazione viene effettuata
attraverso il pannello di controllo integrato, dove è necessario abilitare
esplicitamente la modalità di comando remoto.

Una volta completata la configurazione dell'inverter, è possibile stabilire
la comunicazione utilizzando la libreria `libmodbus`. Il procedimento si
articola nei seguenti passaggi:

1. *Connessione al bus MODBUS*: stabilire il collegamento fisico e logico
con l'inverter attraverso l'interfaccia seriale configurata.

2. *Invio del comando di avvio*: scrivere nel registro della Control Word il
valore esadecimale `0x047F`, corrispondente al comando di start del motore.

L'interpretazione della documentazione tecnica fornita dal costruttore
dell'inverter ha presentato alcune difficoltà iniziali. Il manuale risultava
infatti poco chiaro in alcuni passaggi critici. Tuttavia, attraverso un
processo iterativo di analisi e sperimentazione pratica, è stato possibile
identificare correttamente la sequenza di operazioni necessarie per l'avvio
del sistema.

== Taratura dei parametri del controllore PID

La determinazione dei parametri ottimali per il controllore PID è stata
condotta seguendo un approccio empirico, comunemente definito metodo di
_tuning_ manuale. Questa metodologia prevede l'iterazione progressiva dei
parametri attraverso test sperimentali direttamente sul sistema reale.

=== Fase preparatoria

Prima di procedere con la taratura vera e propria, è stata necessaria una
fase di preparazione del sistema:

1. *Caricamento termico*: è stato posizionato un carico resistivo all'interno
della camera di collaudo per generare calore in modo controllato.

2. *Riscaldamento iniziale*: la temperatura interna è stata portata a
50°C, creando così le condizioni necessarie per testare il sistema di
raffreddamento.

3. *Monitoraggio della temperatura*: sono stati utilizzati due sensori in
parallelo:
  - Il sensore digitale DS18B20, precedentemente descritto, per l'acquisizione
  dei dati utilizzati dal controllore PID
  - Un termistore già presente nella camera, utilizzato come riferimento
  per la validazione delle misure

Come atteso, le letture dei due sensori presentavano una leggera discrepanza,
attribuibile alle diverse caratteristiche metrologiche e alle posizioni
di installazione.

=== Identificazione del parametro proporzionale

La taratura è iniziata con la determinazione del guadagno proporzionale
($K_p$). Il procedimento seguito è stato il seguente:

1. Impostazione di un valore iniziale per il parametro proporzionale

2. Osservazione della risposta del sistema al variare del setpoint

3. Iterazione del valore fino a ottenere una convergenza verso la temperatura
desiderata

Nel caso specifico, il setpoint di riferimento è stato fissato a 40°C. Il
sistema è riuscito a stabilizzarsi intorno ai 43°C, evidenziando un errore di
regime non nullo caratteristico di un controllo esclusivamente proporzionale.

È importante sottolineare che, trattandosi di un sistema di raffreddamento,
i parametri del controllore assumono valori negativi. In particolare, il valore
identificato per il parametro proporzionale è risultato essere $K_p = -3000$.

#figure(
  image("/images/g1.png"),
  caption: [Andamento della temperatura durante la fase di taratura del
  controllore PID]
) <PID_temperature>

=== Integrazione della componente integrale

Successivamente, è stato introdotto il parametro integrale ($K_i$) per
eliminare l'errore di regime osservato nella fase precedente. L'integrazione
di questo parametro consente al sistema di raggiungere asintoticamente il
setpoint desiderato.

Il procedimento di taratura ha previsto:

1. Aggiunta graduale del termine integrale a partire da valori ridotti

2. Monitoraggio continuo della risposta per evitare fenomeni di
sovraelongazione
eccessiva o instabilità

3. Ottimizzazione finale del parametro fino al raggiungimento di un compromesso
tra velocità di risposta e assenza di oscillazioni

Il valore finale identificato per il parametro integrale è risultato essere
$K_i = -15$. Si evidenzia la significativa differenza di magnitudine tra i
due parametri: il guadagno proporzionale è circa duecento volte superiore a
quello integrale. Questa caratteristica è tipica dei sistemi di controllo
termico, dove la costante di tempo del processo è elevata e richiede
un'azione integrale moderata per evitare instabilità.

#figure(
  image("/images/g2.png"),
  caption: [Contributo dei singoli termini del controllore PID: componente
  proporzionale (in alto) e componente integrale (in basso)]
) <PID_pi_terms>

Il secondo grafico illustra chiaramente il comportamento del controllore:
quando il sistema si avvicina al setpoint, il contributo proporzionale tende
a zero, mentre il termine integrale assume il ruolo principale nel mantenere
la temperatura stabile attraverso una correzione continua dell'errore cumulato
nel tempo.

== Risoluzione dei problemi riscontrati

Durante la fase di installazione e messa in servizio del sistema, sono
emerse diverse problematiche non previste nella fase di progettazione. Di
seguito vengono documentate le principali anomalie riscontrate e le relative
soluzioni implementate.

=== Gestione della concorrenza nel framework LVGL

La prima problematica significativa è emersa nel modulo di visualizzazione
`temp-control`, sviluppato con il framework LVGL. Inizialmente, l'aggiornamento
della temperatura visualizzata sul display era gestito attraverso un meccanismo
basato su segnali UNIX: il processo `pid-control` inviava un segnale `SIGUSR1`
al processo `temp-control` per notificare la disponibilità di un nuovo
valore di temperatura.

Tuttavia, questa implementazione ha generato un errore di runtime dovuto
alla natura single-threaded della libreria LVGL. Il framework non supporta
infatti l'aggiornamento di elementi grafici da parte di signal handler,
in quanto tali callback vengono eseguiti in un contesto asincrono che può
interferire con il ciclo principale di rendering.

La soluzione adottata ha previsto la sostituzione del meccanismo basato su
segnali con un approccio basato su timer. In particolare, è stata utilizzata
la funzione `lv_timer_create` fornita dalla libreria LVGL, che consente
di schedulare callback all'interno del contesto di esecuzione principale
del framework.

#figure(
  caption: [Commit di correzione: sostituzione del signal handler con timer
  LVGL (`git show cc35bb1`)],
  sourcecode[```diff
commit cc35bb1af8959f3dfb39b2dcc8c0a98021615001
Author: Mattia Papaccioli <mattiapapaccioli@gmail.com>
Date:   Fri Feb 6 12:04:58 2026 +0100

    fix: update labels with timer to avoid runtime error

diff --git a/src/main.c b/src/main.c
index 616e062..fcc48e4 100644
--- a/src/main.c
+++ b/src/main.c
@@ -154,6 +154,10 @@ const int padding_button = 50;
 const int height_button  = 50;
 const int width_button   = 50;

+static void update_current_temperature_cb(lv_timer_t* timer) {
+    update_current_temperature();
+}
+
 lv_obj_t * create_card(lv_obj_t * parent, const char * header_text, lv_obj_t
 ** value_label_ptr, lv_color_t bg_color,
                        const lv_img_dsc_t * icon_dsc)
@@ -341,11 +345,7 @@ int main(int argc, char ** argv)
     lv_img_set_src(decrement_icon, &minus);
     lv_obj_center(decrement_icon);

-    struct sigaction sa = {0};
-    sa.sa_handler = update_current_temperature;
-    sa.sa_flags   = SA_RESTART;
-    sigaction(SIGUSR1, &sa, NULL);
-    sigprocmask(SIG_UNBLOCK, &set, NULL);
+    lv_timer_create(update_current_temperature_cb, 1000, NULL);

     /* Enter the run loop of the selected backend */
     driver_backends_run_loop();

```]
)

Questa modifica garantisce che l'aggiornamento dell'interfaccia grafica
avvenga in modo sicuro e sincronizzato con il ciclo principale di LVGL,
eliminando il rischio di race condition e accessi concorrenti non protetti.

=== Gestione delle risorse nella comunicazione MODBUS

Una seconda problematica critica è stata identificata nel modulo
`pid-control`, specificatamente nella gestione della connessione MODBUS
con l'inverter. L'implementazione originale prevedeva l'apertura di una
nuova connessione attraverso la funzione `modbus_connect` ogni volta che
era necessario aggiornare la velocità della ventola.

Questo approccio, apparentemente innocuo, ha generato un errore grave nel
sistema: dopo circa 1024 iterazioni del ciclo di controllo, l'applicazione
terminava in modo anomalo. L'analisi del problema ha evidenziato che ogni
chiamata a `modbus_connect` allocava un nuovo file descriptor senza che questi
venissero opportunamente rilasciati, causando l'esaurimento delle risorse
disponibili (limite imposto dal parametro `ulimit` del sistema operativo).

La causa principale risiedeva nella mancata chiusura della connessione dopo
l'invio dei comandi. Nel tempo, il numero di file descriptor aperti cresceva
monotonicamente fino a raggiungere il limite massimo consentito dal kernel.

La soluzione implementata ha previsto una ristrutturazione significativa
dell'architettura di comunicazione:

1. *Connessione persistente*: la connessione MODBUS viene stabilita una sola
volta durante l'inizializzazione del modulo `pid-control`, all'interno della
funzione `main`

2. *Riutilizzo del contesto*: il puntatore `modbus_t *ctx` viene passato
alle funzioni di libreria che necessitano di comunicare con l'inverter,
evitando di creare nuove connessioni

3. *Rilascio delle risorse*: la connessione viene chiusa in modo esplicito
solo al termine dell'esecuzione del programma

#figure(
  caption: [Commit di correzione: gestione ottimizzata dei file descriptor
  (`git show f0bbc5`)],
  sourcecode[```diff
commit e8f11fc2cf56682c62a2d3c52088442434524a92
Author: Mattia Papaccioli <mattiapapaccioli@gmail.com>
Date:   Fri Feb 6 17:10:30 2026 +0100

    fix: open file descriptor once

    bug fix that caused too many open files.
    the file was open every time we sent a command to the inverter.
    only one time is necessary.
    dont trust blindly llm code ;).

diff --git a/src/lib/devices/acs_310_modbus.c
b/src/lib/devices/acs_310_modbus.c
index 863b4de..869ff01 100644
--- a/src/lib/devices/acs_310_modbus.c
+++ b/src/lib/devices/acs_310_modbus.c
@@ -84,11 +84,7 @@ void check_faults(modbus_t *ctx) {
 bool send_command(modbus_t *ctx, int register_addr, uint16_t command) {
     if (!ctx) return false;

-    if (modbus_connect(ctx) == -1) {
-        LOG_ERROR("Connection failed: %s\\n", modbus_strerror(errno));
-        modbus_free(ctx);
-        return false;
-    }
+

     int rc = modbus_write_register(ctx, register_addr, command);
     if (rc == -1) {
diff --git a/src/main.c b/src/main.c
index 08e2bf7..740dc78 100644
--- a/src/main.c
+++ b/src/main.c
@@ -14,6 +14,7 @@
 #include <sys/timerfd.h>
 #include <sched.h>
 #include <sys/stat.h>
+#include <errno.h>

 #include <common-control/common-control.h>
 #include <common-control/config.h>
@@ -225,6 +226,12 @@ int main()

     modbus_t *ctx = get_client();

+    if (modbus_connect(ctx) == -1) {
+        LOG_ERROR("Connection failed: %s\\n", modbus_strerror(errno));
+        modbus_free(ctx);
+        return false;
+    }
+
     log_init();
     log_set_level(LOG_DEBUG);
     log_set_output(LOG_OUTPUT_CONSOLE);


    ```]
)

Questa modifica architetturale ha non solo risolto il problema del crash
del sistema, ma ha inoltre migliorato le prestazioni complessive riducendo
l'overhead associato alla creazione ripetuta di connessioni di rete.
