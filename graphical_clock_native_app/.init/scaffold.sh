#!/usr/bin/env bash
set -euo pipefail
# Idempotent scaffold for CMake GTK4 project using authoritative workspace
WKSP="/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app"
sudo mkdir -p "$WKSP" && sudo chown -R "$USER":"$USER" "$WKSP"
mkdir -p "$WKSP" && cd "$WKSP"
# persist authoritative workspace env for other scripts per policy
if [ ! -f /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh ]; then
  echo "export GRAPHICAL_CLOCK_WORKSPACE=\"$WKSP\"" | sudo tee /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh >/dev/null
  sudo chmod 644 /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh
fi
# Root CMakeLists
cat > CMakeLists.txt <<'CMA'
cmake_minimum_required(VERSION 3.16)
project(visual_clock LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
include(FetchContent)
# GTest via FetchContent for tests
FetchContent_Declare(googletest URL https://github.com/google/googletest/archive/refs/tags/release-1.14.0.zip)
FetchContent_MakeAvailable(googletest)
find_package(PkgConfig REQUIRED)
# try cmake module first, otherwise use pkg-config
if(NOT TARGET Gtk::Application)
  pkg_check_modules(GTK4 gtk4)
  if(GTK4_FOUND)
    add_library(GTK4_IMPORTED INTERFACE)
    target_include_directories(GTK4_IMPORTED INTERFACE ${GTK4_INCLUDE_DIRS})
    target_link_libraries(GTK4_IMPORTED INTERFACE ${GTK4_LIBRARIES} ${GTK4_LDFLAGS_OTHER})
    set(GTK4_TARGET GTK4_IMPORTED)
  else()
    message(FATAL_ERROR "GTK4 not found via CMake or pkg-config")
  endif()
else()
  set(GTK4_TARGET Gtk::Application)
endif()
add_executable(visual_clock src/main.cpp)
if(TARGET Gtk::Application)
  target_link_libraries(visual_clock PRIVATE Gtk::Application)
else()
  target_link_libraries(visual_clock PRIVATE ${GTK4_LIBRARIES})
  target_include_directories(visual_clock PRIVATE ${GTK4_INCLUDE_DIRS})
endif()
# optionally include tests
if(EXISTS ${CMAKE_SOURCE_DIR}/tests/CMakeLists.txt)
  add_subdirectory(tests)
endif()
CMA

# source and tests
mkdir -p src tests
cat > src/main.cpp <<'CPP'
#include <gtk/gtk.h>
static void activate(GtkApplication* app, gpointer user_data){
  GtkWidget *win = gtk_application_window_new(app);
  gtk_window_set_default_size(GTK_WINDOW(win), 200, 200);
  gtk_window_set_title(GTK_WINDOW(win), "Visual Clock - dev stub");
  gtk_widget_show(win);
}
int main(int argc, char **argv){
  GtkApplication *app = gtk_application_new("com.example.visualclock", G_APPLICATION_FLAGS_NONE);
  g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
  int status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);
  return status;
}
CPP

# tests/CMakeLists and sample test
cat > tests/CMakeLists.txt <<'CMA'
enable_testing()
add_executable(test_dummy test_dummy.cpp)
target_link_libraries(test_dummy PRIVATE GTest::gtest_main)
add_test(NAME san_test COMMAND test_dummy)
CMA

cat > tests/test_dummy.cpp <<'CPP'
#include <gtest/gtest.h>
TEST(Sanity, True) { EXPECT_TRUE(true); }
int main(int argc, char **argv){ ::testing::InitGoogleTest(&argc, argv); return RUN_ALL_TESTS(); }
CPP

# start.sh that uses authoritative workspace from /etc/profile.d
cat > start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# read authoritative workspace; fallback to embedded path
if [ -f /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh ]; then
  # shellcheck disable=SC1090
  source /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh
fi
: "${GRAPHICAL_CLOCK_WORKSPACE:=/home/kavia/workspace/code-generation/visual-clock-application-279518-279732/graphical_clock_native_app}"
WKSP="$GRAPHICAL_CLOCK_WORKSPACE"
export DISPLAY=:99
LOG="$WKSP/visual_clock.log"
PIDFILE="$WKSP/.visual_clock.pid"
mkdir -p "$WKSP"
: >"$LOG" || true
cd "$WKSP"
if [ -f "$PIDFILE" ]; then
  OLDPID=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$OLDPID" ] && ps -p "$OLDPID" >/dev/null 2>&1; then
    echo "visual_clock already running with PID $OLDPID" >&2; exit 1
  else
    rm -f "$PIDFILE"
  fi
fi
if [ ! -x "$WKSP/build/visual_clock" ]; then
  echo "Executable missing. Build first." >&2; exit 2
fi
if ! command -v xdpyinfo >/dev/null 2>&1 || ! xdpyinfo >/dev/null 2>&1; then echo "X server not responsive on DISPLAY=$DISPLAY" >&2; exit 3; fi
nohup "$WKSP/build/visual_clock" >>"$LOG" 2>&1 &
PID=$!
echo "$PID" > "$PIDFILE"
sleep 1
if ! ps -p "$PID" >/dev/null 2>&1; then echo "Failed to start visual_clock (pid $PID)" >&2; exit 4; fi
echo "$PID"
SH
chmod +x start.sh

# Ensure files are owned by user and report success (idempotent)
mkdir -p "$WKSP/build" # leave build dir for later steps
ls -la CMakeLists.txt src/main.cpp tests/test_dummy.cpp start.sh >/dev/null
echo "scaffold: completed"
