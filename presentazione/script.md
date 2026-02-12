# Script per la Presentazione di Laurea
## Controllo temperatura camera di collaudo
### Durata stimata: 12-13 minuti

---

## Slide 1: Titolo (30 secondi)

*"Buongiorno a tutti. Oggi vi presenterò il mio progetto di tesi triennale, sviluppato presso AMEL s.r.l."*

*"Il progetto riguarda lo sviluppo di un sistema embedded per il controllo automatico della temperatura in una camera di collaudo, utilizzando un algoritmo PID."*

---

## Slide 2: Il contesto (1 minuto)

*"Il contesto in cui si colloca il progetto è la camera di collaudo presso AMEL s.r.l. Qui vengono testati carichi resistivi che, durante il funzionamento, producono una quantità significativa di calore."*

*"Nei mesi più caldi, la temperatura all'interno della camera diventa critica, rendendo necessario un sistema di raffreddamento. Il sistema precedente era manuale e poco preciso."*

*"L'obiettivo era quindi realizzare un sistema automatico, in grado di mantenere una temperatura costante e configurabile tramite un'interfaccia user-friendly."*

---

## Slide 3: La soluzione proposta (1 minuto)

*"La soluzione proposta è un sistema di controllo in retroazione negativa. Vediamo il diagramma."*

*"I sensori DS18B20, collegati su un bus 1-Wire, rilevano la temperatura ambiente. Questo valore viene confrontato con la temperatura target desiderata."*

*"L'algoritmo PID calcola l'azione correttiva necessaria e la comunica all'inverter tramite protocollo Modbus RTU. L'inverter regola quindi la frequenza della ventola di raffreddamento."*

*"Il sistema fornisce inoltre un'interfaccia touchscreen per la regolazione locale e un accesso web per il controllo remoto."*

---

## Slide 4: Hardware utilizzato (1 minuto)

*"Dal punto di vista hardware, il sistema si basa su una scheda custom sviluppata da AMEL."*

*"La host-board Ganador fornisce le interfacce necessarie: memoria SD, Ethernet, display touchscreen e porta seriale."*

*"Il system-on-module Vulcano-A5 integra una CPU ARM9 a 400MHz con 128MB di RAM e 256MB di flash, risorse limitate ma sufficienti per il nostro scopo."*

*"Come periferiche abbiamo un sensore di temperatura DS18B20, un inverter ACS310 per il controllo della ventola, e un adattatore USB-seriale per la comunicazione Modbus."*

---

## Slide 5: Architettura del sistema (1.5 minuti)

*"L'architettura software è modulare, composta da tre componenti principali."*

*"Il modulo temp-control gestisce l'interfaccia grafica LVGL sul touchscreen. Il modulo pid-control si occupa del controllo PID, della lettura dei sensori e della comunicazione Modbus. Il modulo common-control fornisce funzioni di logging e utility condivise."*

*"La comunicazione tra i moduli avviene tramite file condivisi nella directory /opt/amel/. Quando la temperatura target viene modificata dall'utente, viene scritta su file e successivamente viene letta dal processo PID. Analogamente, quando il PID rileva una nuova temperatura, la scrive su file."*

*"Questo approccio garantisce modularità e permette di sostituire singoli componenti senza modificare l'intero sistema."*

---

## Slide 6: Controllo PID (1.5 minuti)

*"Il cuore del sistema è il controllore PID. PID sta per Proporzionale, Integrale e Derivativo."*

*"La componente proporzionale reagisce all'errore attuale tra temperatura misurata e target. La componente integrale accumula l'errore nel tempo, eliminando lo steady-state error. Nel nostro caso abbiamo utilizzato solo P e I."*

*"Per garantire un campionamento regolare, fondamentale per il PID, ho utilizzato un timer monotonico con sys/timerfd. Inoltre, il processo ha la massima priorità scheduler per minimizzare i ritardi."*

*"La comunicazione con l'inverter avviene tramite protocollo Modbus RTU su porta seriale RS-232. Il PID calcola la tensione da applicare, che l'inverter converte in frequenza per la ventola."*

---

## Slide 7: Interfaccia utente LVGL (1.5 minuti)

*"Per l'interfaccia utente ho utilizzato la libreria LVGL, Light and Versatile Graphics Library."*

*"Come vedete dallo screenshot, l'interfaccia mostra la temperatura target, le temperature rilevate dai sensori, e fornisce due pulsanti per aumentare o diminuire il setpoint."*

*"Per l'input utilizzo libevdev per gestire gli eventi touchscreen, mentre per l'output scrivo direttamente sul framebuffer /dev/fb0. Questo approccio è leggero e adatto a sistemi embedded con risorse limitate."*

*"Per lo sviluppo ho utilizzato due branch Git separate: una per lo sviluppo su PC con backend X11, e una per il target con backend framebuffer."*

---

## Slide 8: Sistema Embedded Linux (1.5 minuti)

*"Il sistema opera su un Linux embedded costruito con Buildroot."*

*"Buildroot è uno strumento che automatizza la cross-compilazione del kernel, delle librerie e del root filesystem. Dato le limitate risorse hardware, ho incluso solo i moduli essenziali."*

*"La sequenza di boot è: AT91bootstrap, poi Barebox come bootloader, infine il kernel Linux."*

*"Ho creato tre pacchetti custom per Buildroot: amel-common-control, amel-temp-control e amel-pid-control. Oltre a questi, il sistema include SSH per l'accesso remoto, un web server CGI e NTP per la sincronizzazione dell'orologio."*

---

## Slide 9: Installazione e tuning (1.5 minuti)

*"Passiamo alla fase di installazione sul campo. Prima di tutto è stato necessario configurare l'inverter per accettare comandi da remoto, abilitando il controllo via Modbus."*

*"Per il tuning dei parametri PID ho seguito un approccio empirico. Abbiamo riscaldato la camera a 50 gradi con un carico resistivo, poi abbiamo iniziato a testare i parametri."*

*"Partendo solo con il termine proporzionale, abbiamo portato il sistema vicino al setpoint di 40 gradi, raggiungendo una stabilità intorno ai 43 gradi."*

*"Successivamente abbiamo aggiunto il termine integrale per eliminare l'errore residuo. I parametri finali sono P uguale a meno 3000 e I uguale a meno 15, con segno negativo perché stiamo raffreddando."*

*"Come vedete nel grafico, il sistema raggiunge e mantiene il setpoint desiderato."*

---

## Slide 10: Risultati e bug risolti (1.5 minuti)

*"Durante l'installazione ho riscontrato e risolto diversi bug che non erano emersi in fase di sviluppo."*

*"Il primo problema era relativo a LVGL, che è single-threaded. Inizialmente aggiornavo le label tramite segnali, ma questo causava race condition. Ho risolto utilizzando i timer interni della libreria."*

*"Il secondo bug era più subdolo: la connessione Modbus veniva aperta a ogni ciclo PID, e dopo circa 1024 iterazioni il sistema crashava per esaurimento dei file descriptor. Ho risolto mantenendo la connessione aperta in permanenza."*

*"Questi problemi dimostrano l'importanza del testing sul campo con tutto il sistema integrato."*

---

## Slide 11: Conclusioni (1 minuto)

*"In conclusione, il progetto ha raggiunto tutti gli obiettivi prefissati."*

*"Abbiamo un sistema funzionante in produzione presso AMEL, che controlla automaticamente la temperatura con un'interfaccia user-friendly e accesso remoto via web."*

*"Da questo progetto ho imparato molto: l'importanza del testing sul campo, la gestione delle risorse in sistemi embedded, e l'applicazione pratica di protocolli industriali come Modbus."*

*"Come sviluppi futuri si potrebbe implementare una dashboard web più avanzata, un sistema di logging su database, e notifiche automatiche in caso di anomalie."*

---

## Slide 12: Ringraziamenti (30 secondi)

*"Per concludere, vorrei ringraziare AMEL s.r.l. e in particolare Edoardo per il supporto tecnico durante lo sviluppo."*

*"Ringrazio l'Università degli Studi dell'Insubria e il professor Dossi per l'opportunità e la supervisione."*

*"Infine, un grazie speciale alla mia famiglia per il sostegno durante tutto il percorso di studi."*

*"Grazie per l'attenzione."*

---

## Note per il presentatore

- **Velocità**: Mantenere un ritmo costante, né troppo veloce né troppo lento
- **Contatto visivo**: Guardare la commissione, non le slide
- **Grafici**: Indicare con il puntatore i punti salienti dei grafici
- **Domande**: Se una domanda richiede una risposta lunga, proporre di approfondirla alla fine
- **Backup**: Aver pronto il sistema per una dimostrazione live se richiesta

## Timing per slide

1. Titolo: 30s
2. Contesto: 1min
3. Soluzione: 1min
4. Hardware: 1min
5. Architettura: 1.5min
6. PID: 1.5min
7. GUI: 1.5min
8. Embedded Linux: 1.5min
9. Installazione: 1.5min
10. Risultati: 1.5min
11. Conclusioni: 1min
12. Ringraziamenti: 30s

**Totale: ~13 minuti**

Lasciare margine per imprevisti e domande brevi.
