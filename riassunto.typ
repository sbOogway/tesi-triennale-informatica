#set document(title: "Sviluppo di un sistema embedded per il controllo della temperatura in una camera di collaudo")
#set page(paper: "a4", margin: (x: 2.5cm, y: 3cm))
#set text(font: "New Computer Modern", size: 11pt, lang: "it")
#set par(justify: true, leading: 0.8em)

#align(center)[
  #text(size: 14pt, weight: "bold")[
    Sviluppo di un sistema embedded \
    per il controllo della temperatura \
    in una camera di collaudo
  ]
  #v(0.3cm)
  #text(size: 10pt, style: "italic")[Mattia Papaccioli — Università degli Studi dell'Insubria — A.A. 2024/2025]
]

#v(0.6cm)

Il progetto descrive la progettazione e lo sviluppo di un sistema embedded per il controllo
automatico della temperatura all'interno di una camera di collaudo presso AMEL s.r.l.,
un'azienda che utilizza tale ambiente per testare carichi resistivi che generano calore
durante il funzionamento. L'obiettivo principale è mantenere la temperatura ambientale
entro limiti predefiniti, in particolare nei mesi estivi, garantendo la ripetibilità delle prove
sperimentali.

Il cuore del sistema è un controllore *PID* (Proporzionale-Integrativo-Derivativo) che,
acquisendo le misurazioni da sensori di temperatura *DS18B20* su bus One-Wire, calcola
l'errore rispetto al setpoint e produce un segnale di comando per un inverter di frequenza.
L'inverter, comunicando via protocollo industriale *MODBUS RTU* attraverso la libreria
_libmodbus_, regola la velocità di rotazione di una ventola di raffreddamento in retroazione
continua.

Il software è strutturato in tre moduli indipendenti: *common-control*, che fornisce
funzioni di utilità condivise, gestione dei log e script di inizializzazione; *temp-control*,
che implementa l'interfaccia grafica touchscreen tramite la libreria *LVGL*; e *pid-control*,
il nucleo computazionale che esegue l'algoritmo PID, legge i sensori e comanda l'inverter.
La comunicazione inter-modulare avviene tramite file condivisi e segnali Unix.

L'hardware si basa su una board *Ganador* con modulo *Vulcano-A5* (processore ARM9
Atmel a 400 MHz, 128 MB di RAM), su cui gira un sistema operativo Linux minimale
costruito con *Buildroot*. Il sistema è accessibile sia tramite display touchscreen locale sia
da remoto attraverso interfaccia web CGI e SSH.

La taratura empirica del PID è stata condotta direttamente sul sistema reale, portando il
sistema a regime con i valori $K_p = -3000$ e $K_i = -15$. I parametri assumono segno
negativo in quanto il sistema agisce per raffreddamento. La differenza di magnitudine tra
i due valori è tipica dei processi termici, dove la costante di tempo elevata richiede
un'azione integrale moderata per evitare instabilità.

Il sistema è inoltre dotato di un meccanismo di logging su file CSV che registra, ad ogni
ciclo di controllo, la temperatura target, le letture dei singoli sensori e l'output del
controllore, consentendo analisi successive delle prestazioni. L'integrità dei dati ricevuti
dai sensori è garantita da un controllo CRC-8 sul payload One-Wire, mentre la regolarità
del campionamento è assicurata da un timer basato su clock monotonico (_timerfd_) con
priorità di scheduling massima.
