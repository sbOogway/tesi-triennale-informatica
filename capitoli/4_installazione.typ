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
Per esempio, ho modificato il callback per aggiornare la temperature nel modulo
`temp-control`: inizialmente anch'esso veniva aggiornamìto tramite il segnale del
eseguibile del `pid-control` ma dopo aver riscontrato un bug relativo alla natura
single threaded di `lvgl`, ho cambiato l'implementazione, utilizzando un timer 
fornito dalla libreria.

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
 lv_obj_t * create_card(lv_obj_t * parent, const char * header_text, lv_obj_t ** value_label_ptr, lv_color_t bg_color,
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


