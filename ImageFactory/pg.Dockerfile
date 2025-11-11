FROM debian:12-slim as base
LABEL maintainer="Tristan G <famgroenewoldt@gmail.com>" \
      version="1.0" \
      description="Messay PG Cluster Setup"
#
#                                 ████████
#                             ████░░░░░░░░██████                          ########################
#               ██████████  ██░░░░░░░░░░░░░░░░░░████                      # ____                 #
#           ████░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░██                    #| __ )  __ _ ___  ___ #
#         ██░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░██                  #|  _ \ / _` / __|/ _ \#
#       ██░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                #| |_) | (_| \__ \  __/#
#     ██░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░██                #|____/ \__,_|___/\___|#
#   ██░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██░░░░██                ########################
# ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░██░░░░░░░░░░░░░░██
# ██░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░░░░░░░░░██
#   ██  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░██
#       ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░██
#       ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
#         ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░██
#         ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░██
#           ██░░░░████░░░░░░░░████░░░░██    ██░░██  ████
#           ██░░░░██  ████████  ██░░░░██    ██░░░░██░░░░██
#           ██░░░░██            ██░░░░██      ██░░░░░░██
#           ██░░░░░░██          ██░░░░░░██      ██████
#           ██░░░░░░  ██        ██░░░░░░  ██
#             ████████            ████████


ENV DEBIAN_FRONTEND=noninteractive

# Install locales and set up en_US.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add PostgreSQL 17 repository
RUN apt-get install -y --no-install-recommends \
    gnupg curl ca-certificates lsb-release && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg && \
    apt-get update

# Install PostgreSQL 17 and PostGIS 3.5
RUN apt-get install -y --no-install-recommends \
    postgresql-17 \
    postgresql-server-dev-17 \
    postgresql-17-postgis-3 \
    postgresql-17-postgis-3-scripts \
    postgresql-plpython3-17 \
    postgis

# Install build dependencies
RUN apt-get install -y --no-install-recommends \
    build-essential \
    git \
    cmake \
    pkg-config \
    libssl-dev \
    libpq-dev \
    libreadline-dev \
    zlib1g-dev \
    flex \
    bison \
    libxml2-dev \
    libxslt-dev \
    ninja-build \
    wget cargo
ENV PATH="/root/.cargo/bin:/root/.local/bin:$PATH"
# Install Python 3.12 and pip from Debian repos for PL/Python compatibility
RUN apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-dev \
    python3-pip \
    python3.11-venv

# Set Python 3.11 as default (PostgreSQL 17 on Debian uses this)
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Install Python packages system-wide for PL/Python
COPY config/requirements.txt /tmp/requirements.txt
RUN pip3 install --break-system-packages --no-cache-dir -r /tmp/requirements.txt

# Ensure Python packages are in the correct location for PL/Python
ENV PYTHONPATH=/usr/local/lib/python3.11/dist-packages:/usr/lib/python3/dist-packages:$PYTHONPATH

# Clean up numpy source if it exists
RUN rm -rf /usr/local/lib/python*/dist-packages/numpy/source \
    /usr/lib/python*/dist-packages/numpy/source \
    /root/.local/lib/python*/site-packages/numpy/source

##
##                      ░▒▒░
##                     ▒▒▒▒▒▒
##            ░▒▒▒▒░ ░▒▒▒▒▒▒▒
##            ▓▓▒▒▒▒▒▒▒▒▒▒▒▒░
##            ▒▓▒▒▒▒▒▒░▒▒▒▒▒            ░ ▒░   ░▒   ▓  ░▓
##   ▓▓▓▓▒▓▓░  ▓▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒░         ▓░   ░▒░░░▓  ░▓░░░
##   ▓▓▒▓▒▓▓▓▓▓▓▓▓▒▓ ▓▒▒▒▒▒▒▒▒▒▒░         ▓░   ░▒   ▓  ░▓
##   ▓▓▓▓▓▓▒▒▓▓▓▓▓▒ ▓▓▓▓▓▓▓▓▓▒▓░          ▓░   ░▒   ▓  ░▓▓▓▓
##   ▓▓▓▓▓▓▒▒▓▓▓▓▓░▒▒▓▓▓▓▓▓▓▓
##    ▓▓▓▓▓▓▓▒▒▒▒░░▓▓▓▓▓▓▓▓                                           ░▒▒▒░
##     ░▓▓▓▓▓▓▓▓▒ ▒▒▒▓▓▓▓▓▓▒▒░                 ▓▓▓▓▓▓░            ▒▓▓▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓
## ▓▓▓░ ░▓▓▓▓▓▓▓ ▓▓▒▒▒▒▒▒▒▓▓▓▓▓▒▓░            ▒▓▓▓▓▓▓▓           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓
## ▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▒▒▒            ▓▓▓▓▓▓▓▓▓         ▒▓▓▓▓░      ▓▓▓▓▓      ▓▓▓▓▓
##  ▓▓▓▓▓▓▓▓▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           ▓▓▓▓▓░▓▓▓▓▓        ▒▓▓▓▓▓                 ▓▓▓▓▓
##   ▒▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓            ▓▓▓▓▓  ▓▓▓▓▓░        ▓▓▓▓▓▓▓▓▓░            ▓▓▓▓▓
##     ▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓▓                   ░▓▓▓▓▒   ▓▓▓▓▓         ░▓▓▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓▓▓▓
##  ▒▓▓░▓▓▓▓▒░▓▓▓▓▓▓▓▓▓▓▓▓                 ▓▓▓▓▓     ▓▓▓▓▓             ░▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓▓
##  ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓                ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                 ▓▓▓▓▓▒     ▓▓▓▓▓░
##  ▓▓▓▓▓▓▓ ░▓▓▓▓▓▓▓▓▓▓▓░                ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░    ▓▓▓▓▓▒      ▒▓▓▓▓▓     ▓▓▓▓▓
##   ▓▓▓▓▓▓ ▓▓▓▓▓▓                      ░▓▓▓▓▓        ░▓▓▓▓▓     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓
##    ░▓▓▓ ▒▓▓▓▓▓▓▓▓▓                   ▓▓▓▓▓          ▒▓▓▓▓▓     ▒▓▓▓▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓
##       ▓ ▓▓▓▓▓▓▓▓▓░                  ░░░░░░           ░░░░░░        ▒▓▓▓▓▓░          ░░░░░
##      ▓
##      ▒
##     ▓
##     ▒
##    ▓
##    ░
# Build Apache AGE
FROM base as age_builder
WORKDIR /tmp
RUN git clone https://github.com/apache/age.git
WORKDIR /tmp/age
RUN make PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config install


###                                                ░░
###                                                █░
###                                                ░░
###                                                ░░
###                                                ░░
###                                                ░░
###                                                ░░
###                                                ▒▒
###                                                ▓▓
###                                               ░▓▓▒
###                                               ▓▓▓▓
###                                                █▓
###                                                ▓▓                                     ░░▓
###                                                ▓▓                           ▒▓▓▓▓▓▓▓▓██░░
###                                                ▓▓                          ▓▓▓▓▓▓███▓░░░░
###                                                █▓                       ░▓▓▓▓█████░░░░░░░
###                                                █▓      ▓▒           ░▓▓█████▒███░░░░░░░░
###                                                █▓     █         ░▓▓████▓░░░░░░░░░░░░░░░░
###                                                █▓    █      ░▓▓▓███▓░░░░░░░░░░░░░░░░░░░░
###                                                █▓  ▓▒   ░▓▓████▒░░░░░░░░░░░░░░░░░░░░░░░░
###                  ▒█████▓▒░                     █▓ █ ░▓▓████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░
###                              ░░▓█████▓░      ░░▓▓█▓████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
###                                            ░▒▓█▓███▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
###                                              ░▓▓░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░
###                                             ▒▓░░░░░░░▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓░░░░
###                                          ░▓▓▓░░░░░░░░░░░░▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  █▓
###                                          ▓▓▓▓░░░░░░░░░░░░░░░░▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒
###                                         ░▓▒░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
###                                        ░█░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
###                                       █░       ░░    ░░░░░░░░░░░░░░░░░░░▒▓▒▒▒▒▓▒▒▒▒▒▒
###                                      █         ░░                ░░░░░░░░░▒▓▓▒▒▒▒▒▒▒▒
###                                    ░█          ░░                           ░░▒▒▒▒▒▒░
###                                   █░           ░░
###                                                ░░
###                                ██              ░░
###                               ▒▒█              ░░
###                                                ░░
###                                                ░░
###                                                ░░
###
# Build pgvector
FROM base as vector_builder
WORKDIR /tmp
RUN git clone https://github.com/pgvector/pgvector.git
WORKDIR /tmp/pgvector
RUN make PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config && \
    make PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config install




#
#                    ██████              ##############################################
#                  ██      ██            # ____             _    _      _             #
#                ██          ██          #|  _ \ _   _  ___| | _| | ___| |_           #
#                ██      ██  ██          #| | | | | | |/ __| |/ / |/ _ \ __|          #
#                ██        ░░░░██        #| |_| | |_| | (__|   <| |  __/ |_           #
#                  ██      ████          #|____/ \__,_|\___|_|\_\_|\___|\__|          #
#    ██              ██  ██              ##############################################
#  ██  ██        ████    ██
#  ██    ████████          ██
#  ██                        ██
#    ██              ██      ██
#    ██    ██      ██        ██
#      ██    ████████      ██
#      ██                  ██
#        ████          ████
#            ██████████
#
From base as ducklet
WORKDIR /tmp
ENV PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config
#ducklet is where we will clone the duck db git an make it
RUN git clone https://github.com/duckdb/pg_duckdb
WORKDIR /tmp/pg_duckdb
RUN make -j$(nproc)
RUN make install
#RUN GEN=ninja make install
# Final stage
#    ,     ,
#    (\____/)
#     (_oo_)
#       (O)
#     __||__    \)
#  []/______\[] /
#  / \______/ \/
# /    /__\
#(\   /____\
#___________.__              .__
 #\_   _____/|__| ____ _____  |  |
 # |    __)  |  |/    \\__  \ |  |
 # |     \   |  |   |  \/ __ \|  |__
 # \___  /   |__|___|  (____  /____/
 #     \/            \/     \/
FROM base as final

# Copy built extensions
COPY --from=vector_builder /usr/lib/postgresql/17/lib/vector.so /usr/lib/postgresql/17/lib/
COPY --from=vector_builder /usr/share/postgresql/17/extension/vector* /usr/share/postgresql/17/extension/
COPY --from=age_builder /usr/lib/postgresql/17/lib/age.so /usr/lib/postgresql/17/lib/
COPY --from=age_builder /usr/share/postgresql/17/extension/age* /usr/share/postgresql/17/extension/
COPY --from=ducklet /usr/lib/postgresql/17/lib/pg_duckdb.so /usr/lib/postgresql/17/lib/
COPY --from=ducklet /usr/share/postgresql/17/extension/ /usr/share/postgresql/17/extension/

# Install pgai 0.11.2
WORKDIR /tmp
RUN pip3 install --break-system-packages --no-cache-dir \
    numpy pandas scikit-learn transformers huggingface-hub
RUN git clone https://github.com/timescale/pgai.git --branch extension-0.11.2
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
ENV UV_NO_MANAGED_CHECK=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
RUN uv python install 3.11
ENV PATH=/root/.uv/versions/3.11/bin:/usr/local/bin:$PATH
ENV PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config
RUN chown -R postgres:postgres  /tmp/pgai

WORKDIR /tmp/pgai/projects/extension
USER postgres
RUN uv venv

#RUN . .venv/bin/activate && uv run build.py install
#RUN pip3 install --break-system-packages .
# Install pgai Python dependencies for PL/Python
#RUN mv output/ai--*.sql /usr/share/postgresql/17/extension/
#RUN find -type f -name "ai--*.sql" | xargs -I {} cp {} /usr/share/postgresql/17/extension/
#RUN find -type f -name "ai.control" | xargs -I {} cp {} /usr/share/postgresql/17/extension/

# Remove the problematic requirements-lock.txt to bypass hash checking
# All dependencies are already installed above

# Install pgai extension using make instead of build.py to avoid pip dependency issues
# Ensure numpy is accessible to PL/Python
RUN python3 -c "import numpy; print('NumPy location:', numpy.__file__)"

# Clean up and ensure we're not in numpy source directory
WORKDIR /var/lib/postgresql
#RUN rm -rf /tmp/pgai /tmp/pip-* /tmp/numpy*
USER root
# Setup PostgreSQL directories
RUN mkdir -p /var/run/postgresql /var/log/postgresql /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/run/postgresql /var/log/postgresql /var/lib/postgresql /etc/postgresql

# Copy configuration files
COPY config/postgresql.conf /etc/postgresql/postgresql.conf
COPY config/pg_hba.conf /etc/postgresql/pg_hba.conf
COPY config/verify_python.sql /etc/postgresql/verify_python.sql
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh  && \
    chown postgres:postgres /etc/postgresql/postgresql.conf /etc/postgresql/pg_hba.conf
USER postgres
# Verify extensions
RUN ls -la /usr/lib/postgresql/17/lib/age.so

WORKDIR /var/lib/postgresql

# Environment variables for PostgreSQL initialization
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres
ENV POSTGRES_PASSWORD=postgres
# POSTGRES_PASSWORD should be set at runtime

# Run entrypoint as root to handle directory creation, it will switch to postgres
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["postgres"]

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
    CMD ["/healthcheck.sh"]
USER root
EXPOSE 5432