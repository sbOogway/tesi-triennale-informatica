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
