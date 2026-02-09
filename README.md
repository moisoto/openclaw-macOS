# OpenClaw via Docker - macOS Guide

This guide is intended for macOS users who want to try OpenClaw
in a safe envionment via Docker.

Since the original `docker-setup.sh` doesn't work with the
bash version shipped in macOS, a new set of scripts has been
made for macOS. This document will explain how to use them.

## Cloning this repository

The first step for using OpenClaw is to download the repository from github.

This repo will also contain the original [OpenClaw repository](https://github.com/openclaw/openclaw)
as a submodule.

```shell
# Clone repository
git clone https://github.com/moisoto/openclaw-macOS.git

cd openclaw-macOS
```

## Setting up the docker image

To setup the docker image just run the `docker-setup.zsh` script:

```shell
./docker-setup.zsh
```

### About the Onboarding Process

This command will take you along an onboarding process and tell you
what to do.

Something like:

```
==> Onboarding (interactive)
When prompted:
  - Gateway bind: lan
  - Gateway auth: token
  - Gateway token: [your-token]
  - Tailscale exposure: Off
  - Install Gateway daemon: No
```

It will then warn you about security risks. Since this will run in
a container there's nothing to worry, pick _**Yes**_.

Now choose **Manual Onboarding mode** and follow the instructions.

Make sure to select a model and set it up.
I recommend using Anthropic with an API Key.

When asked to configure chat channels, please select at least one.
Telegram is recommended as you just need to open your app and chat with
_@BotFather_. Type `/newbot` inside the chat and follow the instructions.

**Finally:** for some reason the gateway will fail with error:
`gateway closed (1006 abnormal closure (no close frame)): no close reason`.
You will have to press CTRL-C and abort gateway container.

## Starting the Gateway

Now that the image is created, we need to start the gateway since we had
to abort the process.

Run the following script:

```shell
# Start OpenClaw Gateway
./docker-start

# Check gateway is running
docker ps --filter ancestor=openclaw:local
```

## Chatting with OpenClaw

Now that the gateway is up and running. We can start a chat session with OpenClaw.

To chat with OpenClaw use this script:

```shell
./chat.zsh
```

**Note:** To exit the chat type `/exit`.

## Stopping the Gatway

Since we have a way to run the gateway whenever we want, you can choose to stop it
if you wish:

```shell
# Stop OpenClaw Gateway
./docker-stop.zsh
```
