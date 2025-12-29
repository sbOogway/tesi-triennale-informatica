= Introduzione

== Abstract
La camera di collaudo, situata presso AMEL s.r.l., è utilizzata per
testare carichi resistivi. Questi producono calore, rendendo necessario il
raffreddamento dell'ambiente, soprattutto nei mesi più caldi.

Il sistema embedded controlla la frequenza di una ventola di raffreddamento
mediante un controllo PID:

+ La temperatura ambiente viene letta tramite un sensore.
+ Questa viene utilizzata come ingresso del sistema PID.
+ L'algoritmo PID calcola la tensione da inviare a un inverter, il quale
determina la frequenza della ventola in base all'errore attuale (azione
proporzionale) e a quello accumulato (azione integrativa).
+ Questo sistema di retroazione negativa viene applicato continuamente per
mantenere costante la temperatura ambiente.

La comunicazione tra l'inverter e il sistema embedded avviene tramite il
protocollo MODBUS RTU @libmodbus.

Il sistema embedded fornisce inoltre un'interfaccia per regolare la temperatura
target dell'ambiente mediante un display touchscreen. La GUI è sviluppata
utilizzando la libreria LVGL @LVGL.

Il sistema embedded è collegato alla rete aziendale tramite Ethernet;
attraverso un web server sarà possibile regolare la temperatura target
anche da remoto.

La comunicazione tra il sistema embedded e il web server avviene mediante
scrittura su file o IPC (Inter-Process Communication).

È ancora da valutare l'impiego di un database per registrare la temperatura
nel tempo. In tal caso, il web server gestirà l'interazione con esso.

#figure(
  image("/images/system-uml.drawio.png"),
  caption: [Diagramma che illustra il sistema],
) <system_diagram>


== Struttura del codice sorgente

Il codice sorgente del progetto è pubblicato su GitHub @root. Il codice
sorgente è composto da più moduli:

- `common-control`: contiene funzioni helper comuni di aiuto e definizioni
 per la comunicazione tra interfaccia grafica e backend.
- `temp-control`: responsabile per la GUI scritta in LVGL.
- `pid-control`: responsabile per il controllo PID, la rilevazione della
 temperatura e la comunicazione MODBUS RTU @libmodbus.

È stato intrapreso questo approccio per garantire modularità del codice,
consentendo in futuro di poter rimpiazzare ciascun modulo con relativa
facilità, rispetto a un approccio monolitico.
