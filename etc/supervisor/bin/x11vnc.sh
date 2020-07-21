#!/bin/bash

if [[ -z "${X11VNC_PASSWORD}" ]]; then
  X11_VNC_OPTIONS="${X11VNC_EXTRA_OPTIONS}"
else
  X11_VNC_OPTIONS="-passwd ${X11VNC_PASSWORD} ${X11VNC_EXTRA_OPTIONS}"
fi

/usr/bin/x11vnc ${X11_VNC_OPTIONS}
