= Introduzione

== Abstract
La camera di collaudo, installata presso la sede di AMEL s.r.l., rappresenta
un'infrastruttura critica dedicata alla verifica e validazione di carichi
resistivi. Durante le operazioni di test, i carichi resistivi generano
una significativa quantità di energia termica, rendendo indispensabile
l'implementazione di un sistema di controllo climatico efficiente,
particolarmente durante i periodi estivi caratterizzati da elevate temperature
ambientali.

Il presente progetto descrive lo sviluppo e l'implementazione di un
sistema embedded progettato per regolare automaticamente la velocità
di una ventola di raffreddamento mediante un algoritmo di controllo PID
(Proporzionale-Integrale-Derivativo). Il funzionamento del sistema può
essere articolato nelle seguenti fasi operative:

*Monitoraggio della temperatura*: La temperatura ambientale viene acquisita
continuamente tramite sensori dedicati, fornendo il dato di ingresso
fondamentale per il sistema di controllo.

*Elaborazione PID*: L'algoritmo PID processa il segnale di temperatura,
calcolando la tensione ottimale da fornire all'inverter. Tale calcolo
considera sia l'errore istantaneo rispetto al setpoint (azione proporzionale)
sia l'accumulo storico degli errori (azione integrativa), garantendo una
risposta precisa e stabile.

*Controllo attuatore*: L'inverter riceve il segnale di controllo e modula la
frequenza di rotazione della ventola di raffreddamento, mantenendo costante
la temperatura ambiente desiderata attraverso un sistema di retroazione
negativa continua.

La comunicazione tra il sistema embedded e l'inverter avviene mediante il
protocollo industriale MODBUS RTU, implementato tramite la libreria libmodbus
@libmodbus, garantendo affidabilità e standardizzazione nello scambio dati.

Il sistema integra inoltre un'interfaccia utente grafica sviluppata con la
libreria LVGL @LVGL, accessibile tramite display touchscreen, che permette agli
operatori di regolare manualmente la temperatura target di funzionamento. Il
dispositivo è connesso alla rete aziendale tramite interfaccia Ethernet
e prevede l'implementazione di un web server per consentire il controllo
remoto dei parametri operativi.

La comunicazione inter-processo tra i componenti del sistema è realizzata
tramite meccanismi di scrittura su file e IPC (Inter-Process Communication),
garantendo un'architettura modulare e scalabile.

È in fase di valutazione l'introduzione di un sistema di database per la
registrazione storica dei dati di temperatura, con gestione delegata al web
server per l'archiviazione e l'analisi delle tendenze temporali.

#figure(
  image("/images/system-uml.drawio.png"),
  caption: [Architettura generale del sistema di controllo climatico],
) <system_diagram>


== Architettura modulare del sistema

Il codice sorgente del progetto è pubblicamente disponibile sulla piattaforma
GitHub @root e presenta un'architettura modulare progettata per massimizzare la
manutenibilità, l'estensibilità e la riusabilità del codice. Tale approccio
architetturale si discosta significativamente da soluzioni monolitiche,
offrendo vantaggi strategici in termini di sviluppo, test e manutenzione.

Il sistema è strutturato nei seguenti moduli principali:

*Modulo `common-control`*: Costituisce il fondamento condiviso dell'intero
sistema, fornendo un insieme di funzioni di utilità, definizioni
di configurazione globale e librerie comuni. Questo modulo facilita la
standardizzazione delle comunicazioni tra i differenti componenti del sistema,
in particolare tra l'interfaccia grafica e il backend di controllo.

*Modulo `temp-control`*: Si occupa della gestione completa dell'interfaccia
utente grafica, sviluppata mediante il framework LVGL. Questo modulo gestisce
l'interazione con l'operatore, la visualizzazione dei dati sensoriali e
l'impostazione dei parametri operativi, garantendo un'esperienza utente
intuitiva e responsiva.

*Modulo `pid-control`*: Implementa il nucleo logico del sistema di regolazione,
includendo l'algoritmo PID per il controllo della temperatura, l'acquisizione
dei dati sensoriali e la comunicazione con l'inverter tramite protocollo
MODBUS RTU @libmodbus.

La scelta di un'architettura modulare offre molteplici vantaggi: in primo
luogo, consente l'isolamento delle responsabilità, facilitando il debugging e
la manutenzione; in secondo luogo, permette la sostituzione o l'aggiornamento
di singoli moduli senza impattare sull'intero sistema; infine, supporta lo
sviluppo parallelo da parte di team diversi, accelerando i cicli di sviluppo
e testing.
