# GitHUB Reference Environment Automation

This repository stores workflow definitions to produce reference environment for NVMe test and
development via emulation provided by qemu, encapsulated in a docker container and with CIJOE for
test-instrumentation. The workflows are named as:

* ``refenv-dockerize``, produces a Docker-image with cijoe + qemu and publishes it on DockerHub
* ``refenv-actions``, provides an example of using the Docker-image via GitHUB actions
* ``refenv-testing``, provides an example of using the Docker-image "manually", note this is not
  recommended now that a GitHUB action is available, in case you want something that the GitHUB
  action does not support then consider changing the GitHUB action instead

Descriptions and status of the workflows follow. The sections following describe the CI/CD
infrastructure needed to utilize the docker image on GitHUB / DigitalOcean infrastructure.
Specifically, self-hosted runners with support for nested-virtualization is a requirement for qemu
to run reasonable fast.

## Refenv Dockerize

[![Status](https://github.com/refenv/actions/workflows/refenv.dockerize/badge.svg)](https://github.com/refenv/actions/actions?query=workflow%3Arefenv.dockerize)

Produce a Docker image containing:

* [cijoe](https://github.com/refenv/cijoe) the core **cijoe** tools
* [cijoe-pkg-example](https://github.com/refenv/cijoe-pkg-example): example packages useful for
  testing the plumbing end-to-end
* QEMU: specifically the ``zrwa`` branch on remote
  [birkelund](https://gitlab.com/birkelund/qemu.git)
* Along with a couple of scripts, found in this repos, bootstrapping the qemu-guest via Debian
  cloud-install

and push the Docker image to:

* https://hub.docker.com/repository/docker/refenv/qemu-nvme/

## Refenv Actions

[![Status](https://github.com/refenv/actions/workflows/refenv.actions/badge.svg)](https://github.com/refenv/actions/actions?query=workflow%3Arefenv.actions)

This workflow shows how to:

* Call the GitHUB Action instantiating a qemu-guest / VM with the given cloud-init image
* Run commands inside the qemu-guest/VM
* Run **cijoe** testplans using the qemu-guest/VM as test-target
* Emit **cijoe** testplan results and reports as workflow-artifacts

## Refenv Testing

[![Status](https://github.com/refenv/actions/workflows/refenv.testing/badge.svg)](https://github.com/refenv/actions/actions?query=workflow%3Arefenv.testing)

Demonstrate how to use the Docker image produced by the ``refenv.dockerize`` workflow, that is, to:

* Run tests inside the container, bootstrapping the qemu-guest and running **cijoe** using the
  qemu-guest as a **test-target**
* Collect the **cijoe** test-report as artifacts

# Self-hosted runners

We need support for:

* Running docker containers with "--privileged"
* Nested virtualization, enabling NVMe device emulation via QEMU

### Hosting runners on Digital Ocean

From the DO plans tested the following looks great:

* Shared CPU, Basic: 4 GB Memory / 80 GB Disk / FRA1 - 20$/month
* Dedicated CPU, General Purpose: 8 GB Memory / 160 GB Disk / FRA1 - 40$/month

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
      - ["curl", "-o", "/tmp/ghar.tar.gz", "-L", "https://github.com/actions/runner/releases/download/v2.267.1/actions-runner-linux-x64-2.267.1.tar.gz"]
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
