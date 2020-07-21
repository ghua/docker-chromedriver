FROM debian:stretch
MAINTAINER Rob Cherry

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USER_NAME=automation
ARG GROUP_NAME=automation
ARG HOME_DIR=/home/automation

# Set timezone
RUN echo "US/Eastern" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Create a default user
RUN groupadd --gid ${GROUP_ID} ${GROUP_NAME} && \
    useradd --uid ${USER_ID} --gid ${GROUP_ID} --home-dir ${HOME_DIR} --create-home --groups audio,video ${USER_NAME} && \
    mkdir --parents ${HOME_DIR}/reports && \
    chown --recursive ${USER_NAME}:${GROUP_NAME} ${HOME_DIR}


# Update the repositories
# Install dependencies
# Install utilities
# Install XVFB and TinyWM
# Install fonts
# Install Python
RUN apt-get -yqq update && \
    apt-get -yqq install gnupg2 && \
    apt-get -yqq install curl unzip && \
    apt-get -yqq install xvfb tinywm && \
    apt-get -yqq install fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic && \
    apt-get -yqq install python && \
    apt-get -yqq install x11vnc && \
    rm -rf /var/lib/apt/lists/*

# Install Supervisor
RUN curl -sS -o - https://bootstrap.pypa.io/ez_setup.py | python && \
    easy_install -q supervisor

# Install Chrome WebDriver
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

# Install Google Chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get -yqq update && \
    apt-get -yqq install google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Configure Supervisor
ADD ./etc/supervisord.conf /etc/
ADD ./etc/supervisor /etc/supervisor

RUN chmod a+x -Rf /etc/supervisor/bin

WORKDIR ${HOME_DIR}
USER ${USER_NAME}

# Default configuration
ENV DISPLAY :20.0
ENV SCREEN_GEOMETRY "1280x1024x24"
ENV CHROMEDRIVER_PORT 4444
ENV CHROMEDRIVER_WHITELISTED_IPS "127.0.0.1"
ENV CHROMEDRIVER_URL_BASE ''
ENV CHROMEDRIVER_EXTRA_ARGS ''
ENV X11VNC_PASSWORD 'secret'
ENV X11VNC_EXTRA_OPTIONS '-shared -forever -loop30 -geometry 1280x1024 -http_oneport'

EXPOSE 4444

VOLUME [ "/var/log/supervisor" ]

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
