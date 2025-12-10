#import "@local/uninsubria-thesis:0.1.0": *
#import "glossary.typ": glossary-entries


#show: tesi-uninsubria.with(
  titolo: "Sviluppo di un sistema embedded per il controllo della temperatura in una camera di collaudo",
  autore: "Mattia Papaccioli",
  matricola: "747053",
  bibliography: bibliography("sources.bib"),
  codice-corso: "F004",
  relatore: "Carlo Dossi",
  tutor: "Edoardo Scaglia",
  azienda: "AMEL SRL",
  anno-accademico: "2025/2026",
  corso: "CORSO DI STUDIO TRIENNALE IN INFORMATICA",
  dipartimento: "DIPARTIMENTO DI SCIENZE TEORICHE E APPLICATE",

  glossary: glossary-entries, // displays the glossary terms defined in "glossary.typ"
  language: "it", // en, de
)


#include "capitoli/introduzione.typ"
#include "capitoli/control.typ"
#include "capitoli/embedded_linux.typ"
#include "capitoli/conclusione.typ"
