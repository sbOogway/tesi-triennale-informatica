#import "@local/tesi-uninsubria:0.1.0": *
#import "glossary.typ": glossary-entries


#show: tesi-uninsubria.with(
  titolo: "Sviluppo di un sistema embedded per il controllo della temperatura in una camera di collaudo",
  autore: "Mattia Papaccioli",
  matricola: "747053",
  bibliography: bibliography("sources.bib"),
  codice_corso: "F004",
  relatore: "Carlo Dossi",
  tutor: "Edoardo Scaglia",
  azienda: "AMEL SRL",
  anno_accademico: "2025/2026",
  corso: "CORSO DI STUDIO TRIENNALE IN INFORMATICA",
  dipartimento: "DIPARTIMENTO DI SCIENZE TEORICHE E APPLICATE",

  glossary: glossary-entries, // displays the glossary terms defined in "glossary.typ"
  language: "it", // en, de
)

// Edit this content to your liking

#include "capitoli/introduzione.typ"
#include "capitoli/control.typ"
#include "capitoli/embedded_linux.typ"
#include "capitoli/conclusione.typ"

= Einleitung

#lorem(100)

#lorem(80)

#lorem(120)

= Erläuterungen

Im folgenden werden einige nützliche Elemente und Funktionen zum Erstellen von Typst-Dokumenten mit diesem Template erläutert.

== Ausdrücke und Abkürzungen

Verwende die `gls`-Funktion, um Ausdrücke aus dem Glossar einzufügen, die dann dorthin verlinkt werden. Ein Beispiel dafür ist:

Im diesem Kapitel wird eine #gls("Softwareschnittstelle") beschrieben. Man spricht in diesem Zusammenhang auch von einem #gls("API"). Die Schnittstelle nutzt Technologien wie das #gls("HTTP").

Das Template nutzt das `glossarium`-Package für solche Glossar-Referenzen. In der zugehörigen #link("https://typst.app/universe/package/glossarium/", "Dokumentation") werden noch weitere Varianten für derartige Querverweise gezeigt. Dort ist auch im Detail erläutert, wie das Glossar aufgebaut werden kann.


== Listen

Es gibt Aufzählungslisten oder nummerierte Listen:

- Dies
- ist eine
- Aufzählungsliste

+ Und
+ hier wird
+ alles nummeriert.

== Abbildungen und Tabellen

Abbildungen und Tabellen (mit entsprechenden Beschriftungen) werden wie folgt erstellt.

=== Abbildungen

#figure(caption: "Eine Abbildung", image(width: 4cm, "assets/ts.svg"))

=== Tabellen

#figure(
  caption: "Eine Tabelle",
  table(
    columns: (1fr, 50%, auto),
    inset: 10pt,
    align: horizon,
    table.header([], [*Area*], [*Parameters*]),

    text("cylinder.svg"),
    $ pi h (D^2 - d^2) / 4 $,
    [
      $h$: height \
      $D$: outer radius \
      $d$: inner radius
    ],

    text("tetrahedron.svg"), $ sqrt(2) / 12 a^3 $, [$a$: edge length],
  ),
)<table>

== Programm Quellcode

Quellcode mit entsprechender Formatierung wird wie folgt eingefügt:

#figure(
  caption: "Ein Stück Quellcode",
  sourcecode[```ts
  const ReactComponent = () => {
    return (
      <div>
        <h1>Hello World</h1>
      </div>
    );
  };

  export default ReactComponent;
  ```],
)


#figure(
  sourcecode(```python
  def hello_world():
      print("Hello, World!")
  ```),
)

== Verweise

Für Literaturverweise verwendet man die `cite`-Funktion oder die Kurzschreibweise mit dem \@-Zeichen:

Tabellen, Abbildungen und andere Elemente können mit einem Label in spitzen Klammern gekennzeichnet werden (die Tabelle oben hat z.B. das Label `<table>`). Sie kann dann mit `@table` referenziert werden. Das ergibt im konkreten Fall: @table

= Fazit

#lorem(50)

#lorem(120)

#lorem(80)

