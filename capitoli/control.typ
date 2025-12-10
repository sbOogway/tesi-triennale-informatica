#import "@local/uninsubria-thesis:0.1.0": sourcecode
= Control


== Graphical User Interface

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

== Compilazione della GUI

Per la compilazione dell'applicazione è necessaria una toolchain adatta all'architettura ARM. Nel nostro caso, ci affidiamo al compilatore e alle librerie fornite da Buildroot.

=== `cross_compile_setup.cmake`
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

== Admin Control

== Logging and Monitoring
