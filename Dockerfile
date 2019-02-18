FROM alpine:3.9 as terraform-base
RUN mkdir -p /install
WORKDIR /install
RUN apk add curl wget unzip
ENV TERRAFORM_VERSION "0.11.11"
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform.zip
RUN unzip -o -d ./ /tmp/terraform.zip
RUN chmod +x "./terraform"

FROM python:3.5.6-stretch as ansible-base

# Set build directory and Ansible version
ENV ANSIBLE_VERSION 2.7.7
RUN mkdir -p /install
WORKDIR /install

RUN pip3 --no-cache-dir install --install-option="--prefix=/install" ansible==${ANSIBLE_VERSION}

FROM python:3.5.6-alpine3.9
# Fix python path
RUN ln -s /usr/local/bin/python3 /usr/bin/python3

# Copy Ansible and Terraform
COPY --from=ansible-base /install /usr/local/
COPY --from=terraform-base /install/terraform /usr/bin/

# Set paths
ENV PYTHONPATH /usr/local/lib/python3.5/site-packages
ENV ANSIBLE_LIBRARY /usr/local/lib/python3.5/site-packages/ansible/library
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_SSH_PIPELINING true

# Add Ansible paths
RUN set -x && \
    echo "~~~ Adding basic hosts"  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

WORKDIR /ansible/playbooks
#RUN apk add jq
#ENTRYPOINT ["ansible-playbook"]
#apk add jq && export GOOGLE_APPLICATION_CREDENTIALS=/.tfcreds
