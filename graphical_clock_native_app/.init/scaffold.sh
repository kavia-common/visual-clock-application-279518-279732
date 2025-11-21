#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
mkdir -p "$WS/src" "$WS/build" "$WS/vendor" && cd "$WS"
# CMakeLists: require pkg-config and prefer gtk4, fallback to gtk+-4.0
cat > "$WS/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.16)
project(graphical_clock_native_app LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(PkgConfig REQUIRED)
# Preferred module name 'gtk4', fallback to 'gtk+-4.0'
pkg_check_modules(GTK4 QUIET gtk4)
if(NOT GTK4_FOUND)
  pkg_check_modules(GTK4 QUIET "gtk+-4.0")
endif()
if(NOT GTK4_FOUND)
  message(FATAL_ERROR "GTK4 not found via pkg-config (tried gtk4 and gtk+-4.0). Install libgtk-4-dev.")
endif()
add_executable(clock_app src/main.cpp)
if(DEFINED GTK4_INCLUDE_DIRS)
  target_include_directories(clock_app PRIVATE ${GTK4_INCLUDE_DIRS})
endif()
if(DEFINED GTK4_LIBRARIES)
  target_link_libraries(clock_app PRIVATE ${GTK4_LIBRARIES})
endif()
if(DEFINED GTK4_CFLAGS_OTHER)
  target_compile_options(clock_app PRIVATE ${GTK4_CFLAGS_OTHER})
endif()
# Allow tests to add targets later
CMAKE

# Minimal GTK4 GtkApplication app (keeps window open)
cat > "$WS/src/main.cpp" <<'CPP'
#include <gtk/gtk.h>
static void app_activate(GApplication *app, gpointer){
  GtkWidget *win = gtk_application_window_new(GTK_APPLICATION(app));
  gtk_window_set_default_size(GTK_WINDOW(win), 200, 200);
  gtk_window_set_title(GTK_WINDOW(win), "Graphical Clock - Dev");
  gtk_window_present(GTK_WINDOW(win));
}
int main(int argc, char **argv){
  GtkApplication *app = gtk_application_new("org.example.GraphicalClock", G_APPLICATION_FLAGS_NONE);
  g_signal_connect(app, "activate", G_CALLBACK(app_activate), NULL);
  int status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);
  return status;
}
CPP

# start_app.sh and stop_app.sh: robust backgrounding, PID capture, health check
cat > "$WS/start_app.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WS="$SCRIPT_DIR"
export DISPLAY="${DISPLAY:-:99}"
cd "$WS"
PID_FILE="$WS/clock_app.pid"
LOG="$WS/clock_app.log"
if [ -f "$PID_FILE" ]; then PID=$(cat "$PID_FILE" 2>/dev/null || true); if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then echo "Already running (PID $PID)"; exit 0; else rm -f "$PID_FILE"; fi; fi
if [ ! -x "$WS/build/clock_app" ]; then echo "ERROR: clock_app not built" >&2; exit 2; fi
# Start in background, detach stdin, capture PID reliably
setsid "$WS/build/clock_app" </dev/null >"$LOG" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"
# small health poll
for i in {1..10}; do if kill -0 "$PID" 2>/dev/null; then echo "Started pid=$PID"; exit 0; else sleep 0.5; fi; done
# if process died quickly, surface logs
echo "ERROR: process did not stay alive" >&2; tail -n 200 "$LOG" || true; exit 3
SH
chmod +x "$WS/start_app.sh"

cat > "$WS/stop_app.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WS="$SCRIPT_DIR"
PID_FILE="$WS/clock_app.pid"
LOG="$WS/clock_app.log"
if [ ! -f "$PID_FILE" ]; then exit 0; fi
PID=$(cat "$PID_FILE" 2>/dev/null || true)
if [ -z "$PID" ]; then rm -f "$PID_FILE"; exit 0; fi
kill "$PID" 2>/dev/null || true
# wait up to 5s for process to exit
for i in {1..10}; do if kill -0 "$PID" 2>/dev/null; then sleep 0.5; else break; fi; done
if kill -0 "$PID" 2>/dev/null; then echo "Process still running, forcing kill" >&2; kill -9 "$PID" 2>/dev/null || true; fi
rm -f "$PID_FILE" || true
SH
chmod +x "$WS/stop_app.sh"

# Done
