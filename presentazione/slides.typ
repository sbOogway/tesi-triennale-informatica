// Presentazione per discussione di laurea
// Utilizzare con: typst compile slides.typ --format pdf

#let accent-color = rgb("#1a5276")
#let slide-counter = counter("slide")
#let is-first-slide = state("is-first-slide", true)

#set page(
  paper: "presentation-16-9",
  margin: (x: 1.5cm, y: 1cm),
  footer: context [
    #align(center)[
      #grid(
        columns: (1fr, 2fr),
        gutter: 0cm,
        align(left)[
          #text(size: 10pt, fill: gray)[
            Slide #slide-counter.display()
          ]
        ],
        align(right)[
          #text(size: 10pt, fill: gray)[
            Mattia Papaccioli - Sviluppo di un sistema embedded per il controllo della temperatura in camera di collaudo
          ]
        ]
      )
    ]
  ]
)

#set text(size: 15pt)

#let slide(title, content) = {
  context {
    if is-first-slide.get() {
      is-first-slide.update(false)
    } else {
      pagebreak()
    }
  }
  
  // Logo in alto a destra
  place(top + right)[
    #pad(right: -1cm, top: -0.5cm)[
      #image("../images/uninsubria-logo.png", width: 3cm)
    ]
  ]
  
  context {
    slide-counter.step()
  }
  
  // v(5.5cm)
  
  text(size: 28pt, weight: "bold", fill: accent-color, title)
  
  v(2cm)
  
  content
}

// Slide 1: Titolo
#slide("Sviluppo di un sistema embedded per il controllo della temperatura in camera di collaudo")[
  #set text(size: 21pt)
  #align(left)[
    #v(1cm)
    
    #grid(
      columns: (auto, auto),
      gutter: 0.5cm,
      [*Tutor Universitario:*], [Prof. Carlo Dossi],
      [*Tutor Aziendale:*], [Edoardo Scaglia - AMEL s.r.l.],
      [*Candidato:*], [Mattia Papaccioli - 747053]
    )
  ]
]

// Slide 2: Il problema
#slide("Il contesto")[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1cm,
    [
      - Camera di collaudo presso AMEL s.r.l.
      - Test su carichi resistivi
      - Produzione di calore significativa
      - Necessità di raffreddamento controllato
      - Sistema precedente: manuale e impreciso
    ],
    [
      #rect(fill: accent-color.lighten(90%), inset: 0.5cm, radius: 0.3cm)[
        *Obiettivo:*
        
        Realizzare un sistema automatico di controllo temperatura con interfaccia user-friendly
      ]
    ]
  )
]

// Slide 3: La soluzione
#slide("La soluzione proposta")[
  #grid(
    columns: (1fr, 2fr),
    gutter: 0.8cm,
    [
      *Componenti:*
      
      - *Sensori:* DS18B20 su bus 1-Wire
      - *Controllo:* Algoritmo PID
      - *Attuatore:* Inverter + ventola
    ],
    [
      #image("../images/system-uml.drawio.png", width: 90%)
    ]
  )
]

// Slide 4: Hardware
#slide("Hardware utilizzato")[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1cm,
    [
      *Host-board Ganador:*
      - Memoria SD
      - Interfaccia Ethernet
      - Display touchscreen
      - Porta seriale RS-232
      
      *System-on-module Vulcano-A5:*
      - CPU ARM9 @ 400MHz
      - 128 MB DDR2 SDRAM
      - 256 MB NAND Flash
      - Controller LCD
    ],
    [
      #rect(fill: accent-color.lighten(90%), inset: 0.5cm, radius: 0.3cm)[
        *Periferiche:*
        
        - 2 sensori DS18B20
        - Inverter ACS310
        - Ventola di raffreddamento
        - Adattatore USB-Seriale
      ]
    ]
  )
]

// Slide 5: Architettura software
#slide("Architettura del sistema")[
  #align(center)[
    #text(size: 13pt)[
      #table(
        columns: (1fr, 1fr, 1fr),
        inset: 8pt,
        align: center,
        fill: (x, y) => if y == 0 { accent-color.lighten(80%) },
        [*temp-control*], [*common-control*], [*pid-control*],
        [Interfaccia LVGL], [Logging e utility], [Controllo PID],
        [Touchscreen], [Configurazione], [Sensori 1-Wire],
        [GUI utente], [Script init/run], [Comunicazione Modbus]
      )
    ]
  ]
  
  #v(0.4cm)
  
  *Comunicazione inter-processo:*
  - File condivisi in `/opt/amel/`
  - Segnali UNIX (`SIGUSR1`)
  - Temperatura target e corrente
]

// Slide 6: Modulo PID
#slide("Controllo PID")[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1cm,
    [
      *Componenti:*
      
      - *P* (Proporzionale): reazione all'errore attuale
      - *I* (Integrale): accumulo errore nel tempo
      - Setpoint: temperatura target
      
      *Implementazione:*
      
      - Timer monotonico per campionamento regolare
      - Massima priorità scheduler
      - Logging CSV per analisi
    ],
    [
      #rect(fill: accent-color.lighten(90%), inset: 0.5cm, radius: 0.3cm)[
        *Comunicazione:*
        
        Protocollo Modbus RTU
        
        Controllo inverter via RS-232
        
        Regolazione frequenza ventola
      ]
    ]
  )
]

// Slide 7: Modulo GUI
#slide("Interfaccia utente LVGL")[
  #grid(
    columns: (1fr, 2fr),
    gutter: 0.8cm,
    [
      *Caratteristiche:*
      - Display touchscreen
      - Temperatura target regolabile
      - Lettura sensori in tempo reale
      - Backend: libevdev + framebuffer
      
      *Sviluppo:*
      - Cross-compilazione ARM
      - Branch separate (dev/target)
      - CMake toolchain
    ],
    [
      #image("../images/lvgl-gui.png", width: 90%)
    ]
  )
]

// Slide 8: Embedded Linux
#slide("Sistema Embedded Linux")[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1cm,
    [
      *Buildroot:*
      
      - Kernel Linux personalizzato
      - Solo moduli essenziali
      - Rootfs ottimizzato
      - Cross-compilazione automatica
      
      *Boot sequence:*
      
      AT91bootstrap → Barebox → Linux
    ],
    [
      *Pacchetti custom:*
      
      - `amel-common-control`
      - `amel-temp-control`
      - `amel-pid-control`
      
      *Servizi:*
      
      - SSH server
      - Web server CGI
      - NTP client
    ]
  )
]

// Slide 9: Installazione
#slide("Installazione e tuning")[
  #grid(
    columns: (1fr, 2fr),
    gutter: 0.8cm,
    [
      *Configurazione inverter:*
      - Abilitazione controllo remoto
      - Comando start: 0x047f
      - Registri Modbus
      
      *Tuning PID:*
      - Approccio empirico
      - Test a 50°C
      - Parametro P: -3000
      - Parametro I: -15
    ],
    [
      #image("../images/g1.png", width: 100%)
    ]
  )
]

// Slide 10: Risultati
#slide("Risultati e bug risolti")[
  #grid(
    columns: (1fr, 2fr),
    gutter: 0.8cm,
    [
      *Problemi risolti:*
      - LVGL single-threaded → uso di timer
      - File descriptor esauriti → connessione Modbus persistente
      - Calibrazione touchscreen
    ],
    [
      #image("../images/g2.png", width: 100%)
    ]
  )
]

// Slide 11: Conclusioni
#slide("Conclusioni")[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1cm,
    [
      *Risultati raggiunti:*
      
      - Sistema funzionante in produzione
      - Controllo automatico temperatura
      - Interfaccia user-friendly
      - Accesso remoto via web
      
      *Lesson learned:*
      
      - Importanza testing sul campo
      - Gestione risorse embedded
      - Protocolli industriali
    ],
    [
      #rect(fill: accent-color.lighten(90%), inset: 0.5cm, radius: 0.3cm)[
        *Sviluppi futuri:*
        
        - Dashboard web avanzata
        - Logging su database
        - Notifiche alert
      ]
    ]
  )
]

// Slide 12: Ringraziamenti
#slide("Ringraziamenti")[
  #align(left)[
    #v(1cm)
    
    *AMEL s.r.l.* e Edoardo per il supporto tecnico
    
    #v(0.5cm)
    
    *Università degli Studi dell'Insubria*
    
    *Professore Carlo Dossi* per la supervisione accademica
    
    *Famiglia e amici*
    
    #v(1cm)
    
    #text(size: 24pt, weight: "bold", fill: accent-color)[
      Grazie per l'attenzione!
    ]
    
  ]
]
