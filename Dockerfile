# syntax=docker/dockerfile:1.7

FROM quay.io/jupyterhub/k8s-singleuser-sample:4.3.3

USER root

COPY --chmod=755 install.sh /usr/local/bin/install-tools.sh

RUN /usr/local/bin/install-tools.sh && \
    rm -f /usr/local/bin/install-tools.sh

COPY --from=ghcr.io/spiffe/spire-agent:1.14.5 \
  /opt/spire/bin/spire-agent \
  /usr/local/bin/spire-agent

RUN chmod +x /usr/local/bin/spire-agent

COPY --chmod=755 ./labs/ /tmp/labs/

RUN python -m pip install jupyterlab-cell-flash
COPY --chmod=755 ./custom-css /home/jovyan/.jupyter/custom

USER jovyan

CMD ["sh", "-c", "exec jupyter lab --custom-css"]