= Conclusione

== L'importanza del testing integrato sul campo

L'esperienza maturata durante la fase di installazione e collaudo del sistema
ha evidenziato un aspetto fondamentale dello sviluppo embedded: la necessità
di effettuare prove di integrazione direttamente in ambiente operativo.

Questa considerazione si articola in tre punti chiave:

1. *Limiti dell'unit testing*: le tecniche di testing automatico su
singoli moduli, sebbene indispensabili, non sono sufficienti a garantire il
corretto funzionamento dell'intero sistema. Alcuni malfunzionamenti emergono
esclusivamente quando tutti i componenti operano in modo coordinato.

2. *Problematiche di integrazione*: le anomalie riscontrate durante
l'installazione hanno dimostrato come errori di comunicazione tra dispositivi,
interferenze elettromagnetiche o incompatibilità temporali non siano
riproducibili in ambiente di sviluppo isolato.

3. *Validazione completa*: solo attraverso test eseguiti con l'intera
infrastruttura operativa è stato possibile verificare il comportamento
reale del sistema, identificando criticità che altrimenti sarebbero rimaste
occulte fino alla messa in produzione.

Questa esperienza conferma la rilevanza delle metodologie di integration
testing e system testing nell'ambito dell'ingegneria dei sistemi embedded,
oltre alle pratiche di unit testing tradizionali.

== Competenze acquisite e riflessioni professionali

Il presente progetto di tesi ha costituito un'occasione significativa
di crescita professionale e personale, permettendo l'acquisizione di
competenze trasversali di rilevante interesse per il percorso di formazione.

=== Strumenti di sviluppo collaborativo

L'approfondimento del sistema di versionamento `git` ha rappresentato un
elemento formativo di particolare valore. L'apprendimento delle pratiche
di branching, merging e gestione delle release costituisce una competenza
fondamentale per l'attività professionale nel settore dello sviluppo software,
favorendo il lavoro in team e la tracciabilità delle modifiche.

=== Architetture embedded

Lo studio approfondito dei microcontrollori, ha permesso di acquisire
conoscenze
relative a:
- La programmazione a basso livello e la gestione delle risorse hardware
limitate
- L'interfacciamento con periferiche esterne attraverso bus di comunicazione
standard
- L'ottimizzazione del codice per sistemi con vincoli temporali real-time

Questo settore ha suscitato notevole interesse, aprendo prospettive di
approfondimento futuro nel campo dell'Internet of Things e dei sistemi
cyber-fisici.

=== Interdisciplinarità ingegneristica

Il progetto ha inoltre consentito di esplorare aspetti dell'ingegneria
elettrica, disciplina complementare ma distinta dall'informatica. In
particolare, si è acquisita consapevolezza delle problematiche relative a:
- La gestione dei carichi elettrici in ambiente industriale
- Le tecniche di protezione dei circuiti
- Le interferenze elettromagnetiche e le strategie di schermatura

Questa dimensione interdisciplinare si è rivelata essenziale per comprendere
l'interazione tra il software embedded e l'hardware fisico su cui opera.

=== Applicazione di protocolli industriali

L'implementazione pratica del protocollo Modbus ha permesso di sperimentare
direttamente le dinamiche della comunicazione industriale standardizzata. La
possibilità di controllare attuatori di potenza, come ventilatori
industriali, attraverso comandi software ha rappresentato un risultato
concreto e soddisfacente, confermando l'efficacia delle soluzioni progettate.

== Ringraziamenti

Desidero esprimere la mia gratitudine ad AMEL s.r.l. per avermi offerto
l'opportunità di sviluppare questo progetto in un contesto aziendale
stimolante e professionale.

Un ringraziamento particolare va a Edoardo Scaglia per il prezioso supporto
tecnico e la collaborazione costante durante tutte le fasi di sviluppo,
dalla progettazione alla messa in opera. Estendo i miei ringraziamenti a
tutti i colleghi dell'azienda per l'accoglienza ricevuta e per l'ambiente
di lavoro favorevole allo scambio di conoscenze.

Vorrei inoltre ringraziare i docenti del Corso di Laurea in
Informatica, in particolare il Professor Carlo Dossi per la supervisione
accademica e la disponibilità dimostrata durante il percorso di tesi. Un
sentito grazie anche ai compagni di corso, con cui le discussioni e il
confronto hanno arricchito significativamente la mia esperienza universitaria.

Infine, dedico un ringraziamento speciale alla mia famiglia per il sostegno
incondizionato e la pazienza dimostrata durante l'intero percorso di studi,
nonostante le difficoltà e le sfide affrontate.
