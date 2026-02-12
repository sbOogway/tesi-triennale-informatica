= Introduzione

== Abstract

Il presente elaborato descrive la progettazione e lo sviluppo di un sistema
embedded per il controllo della temperatura all'interno di una camera di
collaudo, situata presso AMEL s.r.l. Tale ambiente viene utilizzato per
l'esecuzione di test su carichi resistivi, i quali generano una significativa
quantità di calore durante il funzionamento. Per garantire la correttezza e
la ripetibilità delle prove sperimentali, risulta dunque necessario mantenere
la temperatura ambientale entro limiti predefiniti, particolarmente durante
i periodi estivi.

=== Architettura del sistema di controllo

Il sistema proposto implementa un circuito di regolazione automatica basato su
un controllore PID (Proporzionale-Integrativo-Derivativo), il quale consente
di modulare la frequenza di rotazione di una ventola di raffreddamento. Il
funzionamento del sistema può essere descritto attraverso le seguenti
fasi operative:

1. *Rilevazione della temperatura*: un sensore dedicato misura la temperatura
ambiente presente all'interno della camera di collaudo;

2. *Calcolo dell'errore*: la temperatura rilevata viene confrontata con il
valore di riferimento (setpoint) per determinare lo scostamento istantaneo;

3. *Elaborazione del segnale di controllo*: l'algoritmo PID elabora l'errore
calcolando l'azione proporzionale, basata sull'errore attuale, e l'azione
integrativa, derivante dall'accumulo degli errori nel tempo. Il risultato di
tale elaborazione consiste in un segnale di tensione da inviare all'inverter;

4. *Attuazione del comando*: l'inverter riceve il segnale di tensione e lo
converte nella frequenza di alimentazione della ventola;

5. *Retroazione continua*: il sistema opera in modalità di retroazione
negativa, applicando ciclicamente le fasi precedenti per mantenere la
temperatura il più possibile vicina al valore target.

=== Interfacciamento hardware e comunicazione

La comunicazione bidirezionale tra il sistema embedded e l'inverter di
frequenza avviene attraverso il protocollo di comunicazione industriale
MODBUS RTU @libmodbus. Tale protocollo garantisce la trasmissione affidabile
dei dati su bus seriale, risultando particolarmente adatto per applicazioni
di controllo in tempo reale.

=== Interfaccia utente e sistema remoto

Per facilitare l'interazione con il sistema, è stata realizzata un'interfaccia
grafica utente (GUI) che consente di visualizzare lo stato attuale del
sistema e di modificare i parametri operativi, inclusa la temperatura target
desiderata. L'interfaccia viene presentata su un display touchscreen integrato
nel pannello di controllo, garantendo immediatezza d'uso anche per operatori
senza specifica formazione tecnica. La libreria grafica LVGL @LVGL è stata
adottata per lo sviluppo dell'interfaccia, in virtù della sua efficienza
nell'ambito dei sistemi embedded a risorse limitate.

Il sistema embedded è inoltre dotato di connettività Ethernet, che
ne consente l'integrazione all'interno della rete aziendale. Tramite
un'architettura client-server basata su web server, gli operatori autorizzati
possono accedere alle funzionalità di controllo anche da remoto, modificando
la temperatura target senza necessità di presenza fisica presso la camera
di collaudo. La comunicazione tra il sistema embedded e il web server avviene
attraverso un meccanismo di scrittura e lettura su file condivisi.

#figure(
  image("/images/system-uml.drawio.png"),
  caption: [Diagramma d'insieme del sistema di controllo temperatura],
) <system_diagram>

== Struttura del codice sorgente

Il software sviluppato per il sistema embedded è organizzato secondo
un'architettura modulare, suddivisa in tre componenti principali:

- *`common-control`*: modulo di supporto contenente funzioni di utilità
condivise, definizioni di costanti e strutture dati utilizzate per la
comunicazione tra i livelli applicativi;

- *`temp-control`*: modulo dedicato alla gestione dell'interfaccia grafica
e all'elaborazione degli input utente, implementato mediante la libreria LVGL;

- *`pid-control`*: modulo centrale responsabile dell'implementazione
dell'algoritmo PID, dell'acquisizione dati dal sensore di temperatura e
della comunicazione MODBUS RTU con l'inverter @libmodbus.

La suddivisione in moduli indipendenti è stata adottata per favorire
la manutenibilità del codice e la possibilità di estensione futura del
sistema. Tale approccio consente infatti di sostituire o modificare singoli
componenti senza necessità di interventi strutturali sull'intero progetto,
offrendo vantaggi significativi rispetto a una soluzione monolitica.
