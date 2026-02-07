#import "@preview/unofficial-uninsubria-thesis:0.1.0": sourcecode

= Installazione del sistema

== Comunicazione con l'inverter
Per comunicare con l'inverter via modbus e necessario configurarlo per
accettare comandi da remoto tramite il display integrato.
Dopodiche, con modus, si scrive nel registro della word di controllo il
comando di start che corrisponde in esadecimale al valore 0x047f.
Il criptico manuale dell'inverter e stato difficile da decifrare ma dopo
varie riletture e tentativi siamo riusciti a farlo partire.

== Regolazione dei parametri del controllo PID
Per regolare i parametri del controllo PID e stato intrapreso un approccio
empirico. E stato necessario riscaldare la camera con un carico resistivo
fino a 50 gradi Celsius. Abbiamo utilizzato il sensore DS18B20 menzionato
in precedenza per misurare la temperatura digitalmente da utilizzare nel
calcolo del PID ed un termistore gia
presente nella camera come riferimento. Come previsto vi e stata un leggera
incongruenza tra i due sensori.
Dopodiche abbiamo iniziato a provare vari
valori per il parametro Proporzionale, fino al punto in cui il sistema si e
avvicinato al setpoint, nel nostro caso di 40 gradi Celsius ed ha iniziato
a mantenere una temperatura stabile, di circa 43 gradi Celsius. Nel nostro
caso visto che stiamo raffreddando,
abbiamo utilizzato dei parametri con segno negativo. La differenza di
magnitudine tra il parametro P (-3000) ed (-15) I e considerevole.


#figure(image("/images/g1.png"), caption: [Andamento della temperatura],
) <PID_temperature>

Successivamente abbiamo iniziato ad aumentare il parametro Integrale per
approcciare piu dolcemente ed accuratamente il setpoint. Una volta arrivati
al setpoint il contributo della parte proporzionale diventa nullo e il
componente integrale si occupa di mantenere il sistema stabile, come visibile
nel seguente grafico.

#figure(image("/images/g2.png"), caption: [Contributo dei vari parametri
del controllo pid], ) <PID_pi_terms>

== Risoluzione di bug
Durante l'installazione del sistema, come prevedibile, abbiamo incontrato vari
bug e trovato di conseguenza delle ottimizzazioni impensate durante la fase di
sviluppo.

=== `lvgl` e single threaded
Per esempio, ho modificato il callback per aggiornare la temperature nel modulo
`temp-control`: inizialmente anch'esso veniva aggiornamìto tramite il
segnale del
eseguibile del `pid-control` ma dopo aver riscontrato un bug relativo
alla natura
single threaded di `lvgl`, ho cambiato l'implementazione, utilizzando un timer
fornito dalla libreria.

#figure(
     caption: `git show cc35bb1`,
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
 {
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

=== Troppi file descriptor aperti
Un altro problema l ho trovato invece nel modulo `pid-control`,
specificatamente
nella comunicazione con l'inverter tramite `modbus`. Ingenuamente, il codice
effettuava una connessione a con `modbus` ogni volta che doveva settare
la velocita della ventola dell inverter e dopo 1024 iterazioni circa,
l' `ulimit` del sistema embedded, l'eseguibile crashava per i troppi file
descriptor
aperti.
Per risolvere il problema e stato necessario semplicemente connettersi
all'inverter
una sola volta nel `main` del modulo `pid-control` invece che ripetutamente
nella
libreria che ho scritto per l 'inverter.

figure(
     caption: `git show f0bbc5`,
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
-        LOG_ERROR("Connection failed: %s\n", modbus_strerror(errno));
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
+        LOG_ERROR("Connection failed: %s\n", modbus_strerror(errno));
+        modbus_free(ctx);
+        return false;
+    }
+
     log_init();
     log_set_level(LOG_DEBUG);
     log_set_output(LOG_OUTPUT_CONSOLE);


     ```]
)

