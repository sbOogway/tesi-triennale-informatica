#import "@local/uninsubria-thesis:0.1.0": sourcecode
= Moduli


== `temp-control`

Per controllare la temperatura della camera di collaudo, l'operatore imposta la temperatura target mediante un display touchscreen "NOME DISPLAY". L'interfaccia grafica è sviluppata utilizzando la libreria LVGL @LVGL e si è utilizzato un template @LVGL_LINUX contenente il porting su Linux fornito dagli sviluppatori della libreria.

=== Funzioni di callback nel ciclo principale della GUI LVGL

#figure(
  sourcecode[```c
  // TODO CHANGEME READ THIS FROM A FILE
  static float target_temperature = read_temperature_file();
  lv_obj_t * screen;
  lv_obj_t * target_temperature_label;

  const int padding_button = 50;
  const int height_button  = 50;
  const int width_button   = 50;

  static void increment_temperature(lv_event_t * e)
  {
      if(lv_event_get_code(e) != LV_EVENT_CLICKED) {
          return;
      }
      target_temperature++;
      lv_label_set_text_fmt(
          target_temperature_label, "%.1f°C", target_temperature
      );
  }

  static void decrement_temperature(lv_event_t * e)
  {
      if(lv_event_get_code(e) != LV_EVENT_CLICKED) {
          return;
      }
      target_temperature--;
      lv_label_set_text_fmt(
          target_temperature_label, "%.1f°C", target_temperature
      );
  }
  ```],
  caption: "Funzioni di callback per i bottoni di incremento e decremento della temperatura target",
)

=== Albero dei widget nel ciclo principale
#figure(
  caption: "Creazione dei widget nell'interfaccia grafica",
  sourcecode[
    ```c
    screen = lv_scr_act();
    lv_obj_t * increment_temperature_button = lv_btn_create(screen);
    lv_obj_align(
        increment_temperature_button, LV_ALIGN_BOTTOM_RIGHT,
        -padding_button, -padding_button);
    lv_obj_set_height(increment_temperature_button, height_button);
    lv_obj_set_width(increment_temperature_button, width_button);
    lv_obj_add_event_cb(
        increment_temperature_button, increment_temperature,
        LV_EVENT_ALL, NULL
    );

    lv_obj_t * increment_temperature_label = lv_label_create(
        increment_temperature_button
    );
    lv_label_set_text(increment_temperature_label, "+");
    lv_obj_set_style_text_font(
        increment_temperature_label, &lv_font_montserrat_48, 0
    );
    lv_obj_center(increment_temperature_label);

    lv_obj_t * decrement_temperature_button = lv_btn_create(screen);
    lv_obj_align(
        decrement_temperature_button, LV_ALIGN_BOTTOM_LEFT,
        padding_button, -padding_button);
    lv_obj_set_height(decrement_temperature_button, height_button);
    lv_obj_set_width(decrement_temperature_button, width_button);
    lv_obj_add_event_cb(
        decrement_temperature_button, decrement_temperature,
        LV_EVENT_ALL, NULL
    );

    lv_obj_t * decrement_temperature_label = lv_label_create(
        decrement_temperature_button
        );
    lv_label_set_text(decrement_temperature_label, "-");
    lv_obj_set_style_text_font(
        decrement_temperature_label, &lv_font_montserrat_48, 0
    );
    lv_obj_center(decrement_temperature_label);

    target_temperature_label = lv_label_create(screen);
    lv_label_set_text_fmt(
        target_temperature_label, "%.1f°C", target_temperature
    );
    lv_obj_set_style_text_font(
        target_temperature_label, &lv_font_montserrat_48, 0
    );
    lv_obj_align(target_temperature_label, LV_ALIGN_CENTER, 0, 0);
    ```],
)
I backend utilizzati da LVGL per l'I/O sono libevdev e il framebuffer device. Sono stati scelti per la loro semplicità e il ridotto utilizzo di risorse.

Libevdev @libevdev è una libreria che gestisce gli eventi di input: riceve i tocchi dal touchscreen e li passa all'interfaccia grafica.

Il framebuffer device è semplicemente il file `/dev/fb0`, scritto dalla GUI, che contiene il colore di ciascun pixel dello schermo.

=== Compilazione della GUI

Per la compilazione dell'applicazione è necessaria una toolchain adatta all'architettura ARM. Nel nostro caso, ci affidiamo al compilatore e alle librerie fornite da Buildroot.

==== `cross_compile_setup.cmake`
#figure(
  caption: "cross_compile_setup.cmake",
  sourcecode(
    ```c
    set(CMAKE_SYSTEM_NAME Linux)
    set(CMAKE_SYSTEM_PROCESSOR arm)

    set(tools ~/buildroot/output/host/bin/arm-buildroot-linux-gnueabihf-)
    set(CMAKE_C_COMPILER ${tools}gcc)
    set(CMAKE_CXX_COMPILER ${tools}g++)

    set(EVDEV_INCLUDE_DIRS ~/buildroot/output/staging/usr/include/libevdev/)
    set(EVDEV_LIBRARIES ~/buildroot/output/staging/usr/lib/libevdev.so)

    set(BUILD_SHARED_LIBS ON)
    ```,
  ),
)

Il comando `cmake -DCMAKE_TOOLCHAIN_FILE=./cross_compile_setup.cmake -B build -S .` genera i Makefile necessari per la cross-compilazione, che vengono poi eseguiti con `make -C build -j`.

LVGL viene compilata come libreria condivisa, mentre l'applicazione come eseguibile.

#figure(
  image("/images/lvgl-gui.png", width: 10cm),
  caption: [Interfaccia grafica per il controllo della temperatura],
) <lvgl_gui>

=== Branches
Per organizzare efficientemente la repository sorgente, e stato realizzato un branching, creando una repository per lo sviluppo ed una per il dispositivo target.
Esse sono uguali completamente tranne per il file `lv_conf.h`. 

Per la branch di sviluppo, esso usa come backend `x11` e contiene dei sanity check, utili in sviluppo ma limitanti in termini di performance.

Per la branch del dispositivo target sono stati disabilitati i sanity checks e utilizzata come backend il device `/dev/fb0`.

Per proteggere il file `lv_conf.h` e stato aggiunto un file `.gitattributes` contenente `lv_conf.h merge=ours`.

Questo speciale file di git, comunica al version control system che durante il merge delle branch di mantenere il file come si trova nella branch da cui si sta effettuando il merge, consentendo di mantenere separate le due configurazioni senza preoccuparsi di sovrascriverle accidentalmente.


== `pid-control`
=== Sensore di temperatura
I sensori di temperatura utilizzati sono due DS18B20 collegati in parallelo su un bus 1-Wire.

Il microcontrollore si comporta da master sul bus e richiede periodicamente la temperatura ai sensori.

Il binario `pid` legge periodicamente e calcola il valore di output del controller PID in base alla temperatura misurata e al setpoint desiderato.

Inizialmente esso conta il numero di sensori sul bus, alloca la memoria necessaria per immagazinare gli uuid dei sensori e poi legge effetivamente quest'ultimi in memoria.

E stato preferito questo approccio per evitare complicazioni con `realloc` rispetto a leggere direttamente in un ciclo unico sia il numero di sensori che gli id. Questa procedura viene effettuate solamente una volta all'avvio e non ha un impatto significativo sulla performance dell'eseguibile.

Un approccio senza salvare gli id dei sensori porterebbe una chiamata alla funzione `DS18X20_find_sensor` ripetutamente e sarebbe uno spreco di cicli di cpu quindi sacrifichiamo un po di memoria per questo.

#figure(
  caption: `pid-main`,
  sourcecode[```c
    typedef struct
    {
      char id[16];
      int16_t temperature;
      uint8_t uint_id[OW_ROMCODE_SIZE];
    } sensor;

    // first we count the number of devices on the bus
    while (diff != OW_LAST_DEVICE)
    {
        sensors_count++;
        DS18X20_find_sensor(&diff, id);
    }

    // we malloc based on the number of sensors
    sensor *sensors = malloc(sizeof(sensor) * sensors_count);

    diff = OW_SEARCH_FIRST;
    int i = 0;
    // we store the sensor ids
    while (diff != OW_LAST_DEVICE)
    {
        DS18X20_find_sensor(&diff, id);
        sensor s;
        for (int i = 0; i < OW_ROMCODE_SIZE; i++)
        {
            s.uint_id[i] = id[i];
        }
        sensors[i] = s;
        i++;
    }

    while (1)
    {
        // now we read the sensor temperatures every second
        if (DS18X20_start_meas(DS18X20_POWER_EXTERN, NULL) != DS18X20_OK)
        {
            fprintf(stdout, "error in starting measurement\n");
            fflush(stdout);
            delay_ms(100);
            break;
        }
        for (int i = 0; i < sensors_count; i++)
        {
            sensor s = sensors[i];
            if (DS18X20_read_decicelsius(s.uint_id, &temp_dc) != DS18X20_OK)
            {
                fprintf(stdout, "error in reading sensor %s\n", s);
                fflush(stdout);
                delay_ms(100);
                continue;
            }
            fprintf(stdout, "sensor %s TEMP %3d.%01d C\n", s.id, temp_dc / 10, temp_dc > 0 ? temp_dc % 10 : -temp_dc % 10);
            fflush(stdout);
        }
        delay_ms(1000);
    }
  ```],
)

=== MODBUS RTU
Per comunicare con l'inverter che controlla la ventola di raffreddamento, è stato utilizzato il protocollo MODBUS RTU tramite l'apposita libreria `libmodbus`.

=== Controllo pid

== `common-control`
=== Comunicazione tra GUI e PID
Per fare in modo che l'interfaccia grafica e il processo di controllo pid comunichino e stato necessario comunicare attraverso dei file e utilizzando dei segnali.

Quando un operatore cambia la temperatura target dall'interfaccia sul display LCD essa viene scritta sul file `/opt/amel/target-temperature`.

Analogamente, il processo pid quando rileva una temperatura tramite i sensori DS18B20, scrive quest'ultima sul file `/opt/amel/current-temperature/sX`, con x che rappresenta il numero del sensore sul bus. 

=== Admin Control

=== Logging and Monitoring
