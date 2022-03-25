# GitHUB Reference Environment Automation

This repository stores workflow definitions to produce reference environment for NVMe and
development via emulation provided by qemu, encapsulated in a docker container and with CIJOE for
instrumentation. The workflows are named as:

* ``dockerize.alpine-bash``, this is unrelated to the others, it just provides an Alpine Linux
  Docker image on DockerHub with Git and Bash installed, and Bash set as the default Shell instead
  of ``sh``. It is re-build daily.

* ``dockerize.xnvme-devtools``, this is unrelated to the others, it just provides an Debian
  Bullseye Docker image on DockerHub with the tools installed to build xNVMe

* ``dockerize.qemu-nvme``, produces a Docker-image with cijoe + qemu and publishes it on DockerHub

* ``run.cijoe-qemu-action``, provides an example of using the Docker-image via GitHUB actions

Descriptions and status of the workflows follow. The sections following describe the CI/CD
infrastructure needed to utilize the docker image on GitHUB / DigitalOcean infrastructure.
Specifically, self-hosted runners with support for nested-virtualization is a requirement for qemu
to run reasonable fast.

See the Appendix section for background information to skim through if the above does not make sense.

## WF: dockerize.qemu-nvme

[![Status](https://github.com/refenv/gh-automation/workflows/dockerize.qemu-nvme/badge.svg)](https://github.com/refenv/gh-automation/actions?query=workflow%3Adockerize.qemu-nvme)
[![Docker Pulls](https://img.shields.io/docker/pulls/refenv/qemu-nvme)](https://hub.docker.com/r/refenv/qemu-nvme)

This workflow takes about 16 minutes to complete, here is what it does:

* Retrieves the qemu source-code, specifically the ``zrwa`` branch on remote
  [birkelund](https://gitlab.com/birkelund/qemu.git) and builds it for x86 system emulation

* Produces a DockerImage, see the file ``qemu-nvme/Docker`` for details containing
  - [cijoe](https://github.com/refenv/cijoe) the core **cijoe** tools
  - [cijoe-pkg-example](https://github.com/refenv/cijoe-pkg-example): example packages useful for
    ng the plumbing end-to-end
  - [cijoe-pkg-qemu](https://github.com/refenv/cijoe-pkg-qemu): qemu package wrapping qemu and
  provides cloud-init data, meta-data and qemu-arguments for NVMe device emulation
  - And the qemu itself build for x86 from the previously mentioned remote

* Deploys the DockerImage to DockerHub
  - See here: https://hub.docker.com/repository/docker/refenv/qemu-nvme/

## WF: run.cijoe-qemu-action

[![Status](https://github.com/refenv/gh-automation/workflows/run.cijoe-qemu-action/badge.svg)](https://github.com/refenv/gh-automation/actions?query=workflow%3Arun.cijoe-qemu-action)

This workflow takes about 3 minutes to complete.

This workflow shows how to utitlize the custom GitHub Action for cijoe/qemu, here is what it does:

* Runs in a privileged docker (the one generated by ``dockerize.qemu-nvme``
* Invokes the cijoe-qemu wrappers to provision a qemu-guest using the given cloud-init image
* Starts the provisioned qemu-guest
* Runs commands inside the qemu-guest via **cijoe** 'cij.cmd'
* Runs **cijoe** lans using the qemu-guest as test-target

## WF: dockerize.Alpine-Bash

[![Status](https://github.com/refenv/gh-automation/workflows/dockerize.alpine-bash/badge.svg)](https://github.com/refenv/gh-automation/actions?query=workflow%3Adockerize.alpine-bash)
[![Docker Pulls](https://img.shields.io/docker/pulls/refenv/alpine-bash)](https://hub.docker.com/r/refenv/alpine-bash)

This workflow is run nightly, it produces a docker image based on ``alpine:latest`` with nothing
but ``Bash`` and ``git`` added to it. This is done to have the latest Alpine Linux available for
consumption by GitHUB CI actions which use Bash as the default shell and typically use ``git`` for
checking out the source.

## WF: dockerize.xnvme-devtools

[![Status](https://github.com/refenv/gh-automation/workflows/dockerize.xnvme-devtools/badge.svg)](https://github.com/refenv/gh-automation/actions?query=workflow%3Adockerize.xnvme-devtools)
[![Docker Pulls](https://img.shields.io/docker/pulls/refenv/xnvme-devtools)](https://hub.docker.com/r/refenv/xnvme-devtools)

Assuming you have the xNVMe source-repository on the your Docker-host, then add it as a volume for
the docker-container to access like so:

    docker run -it -u 1000 -v ~/git/xnvme:/home/developer/xnvme refenv/xnvme-devtools

Where ``~/git/xnvme`` is the path to the xNVMe repository on the Docker-host.
Inside the docker-container you should now be able to:

    cd xnvme
    make

Or, to run e.g. the source-formater:

    cd xnvme
    make source-format

## WF: dockerize.xnvme-devtools-ci

[![Status](https://github.com/refenv/gh-automation/workflows/dockerize.xnvme-devtools-ci/badge.svg)](https://github.com/refenv/gh-automation/actions?query=workflow%3Adockerize.xnvme-devtools-ci)
[![Docker Pulls](https://img.shields.io/docker/pulls/refenv/xnvme-devtools-ci)](https://hub.docker.com/r/refenv/xnvme-devtools-ci)

This Docker container is intended to be used by CI / GitHUB Actions. Similar to
``dockerize.Alpine-Bash`` but with all the same tools available as ``dockerize.xnvme-devtools``.

# Self-hosted runners

The GitHub Hosted Runners does not support nested virtualization, we need that to have hw-supported
acceleration for qemu, without it, it is too slow to be useful. The solution is thus to utilize
self-hosted runners instead, in other words, we need support for:

* Running docker containers with "--privileged"
* Nested virtualization, enabling NVMe device emulation via QEMU

The following section describes how to set up such as runner on Digital Ocean, this is just one of
many ways of obtaining a self-hosted runner meeting the before-mentioned requirements.

### Hosting runners on Digital Ocean

From the DO plans d the following looks great:

* Shared CPU, General Purpose: 8 GB Memory / 160 GB Disk / FRA1 - 40$/month

For OS then Ubuntu Focal / 20.04, seems work best with cloud-init.

Prepare the droplet via cloud-init:

    #cloud-config
    apt:
      sources:
        docker.list:
          source: deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable
          keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
    package_update: true
    package_upgrade: true
    packages:
    - apt-transport-https
    - ca-certificates
    - containerd.io
    - curl
    - docker-ce
    - docker-ce-cli
    - git
    - gnupg-agent
    - htop
    - libnuma-dev
    - nvme-cli
    - pciutils
    - software-properties-common
    runcmd:
      - ["mkdir", "/opt/ghar"]
      - ["curl", "-o", "/tmp/ghar.tar.gz", "-L", "https://github.com/actions/runner/releases/download/v2.287.1/actions-runner-linux-x64-2.287.1.tar.gz"]
      - ["tar", "xzf", "/tmp/ghar.tar.gz", "-C", "/opt/ghar"]

Give it time to finish / settle. Then do manual configuration-step, logging into
the droplet, declare some secret sauce:

    export GITHUB_ORG=<YOUR_ORG>
    export GITHUB_PROJECT=<YOUR_PROJECT>
    export GITHUB_GHAR_TOKEN=<GET_THIS_FROM_PROJECT_SETTINGS_ACTIONS>

Then use it to the GitHUB Actions Runner:

    RUNNER_ALLOW_RUNASROOT=1 /opt/ghar/config.sh --url https://github.com/$GITHUB_ORG/$GITHUB_PROJECT --token ${GITHUB_GHAR_TOKEN}

    pushd /opt/ghar || exit 1
    /opt/ghar/svc.sh install
    /opt/ghar/svc.sh start
    /opt/ghar/svc.sh status
    popd || exit 1

# Appendix

* [cijoe](https://cijoe.readthedocs.io/en/la)
  - [cijoe-pkg-qemu](https://github.com/refenv/cijoe-pkg-qemu)
* [cloud-init](https://cloudinit.readthedocs.io/en/la)
  - User-data: https://cloudinit.readthedocs.io/en/latopics/format.html
  - Meta-data: https://cloudinit.readthedocs.io/en/latopics/instancedata.html
  - cloud-init enabled bsd-images: http://bsd-cloud-image.org/
* [qemu](https://www.qemu.org/)
* [docker](https://www.docker.com)
  - [DockerHub](https://hub.docker.com/)
* [GitHub Actions](https://github.com/features/actions)
  - [Custom Actions](https://docs.github.com/en/actions/creating-actions/about-custom-actions)
  - [Runners self-hosted](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
  - [Runners github-hosted](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
