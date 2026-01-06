#!/usr/bin/env bash

# Copyright (C) 2026 Ido Ozeri
# Author:     Ido Ozeri <ido.lateralus@gmail.com>
# Maintainer: Ido Ozeri <ido.lateralus@gmail.com>
# Purpose:    Deploy a demo application using Minikube and ArgoCD;

set -eo pipefail

# Variables
DIR=$(dirname $0)
PROG=$(basename $0)
REQUIRED_BINARIES="curl helm kubectl"
SCRIPT_FULLPATH=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
APPS_PATH=$SCRIPT_FULLPATH/../apps
APPS="audit-service items-service"
TAG="1.0.0"

# Functions
source helpers.sh

################## MAIN WORKFLOW ##################

_log INFO "Setting up Minikube"

assert_binaries
platform_check
install_minikube
start_minikube
set_minikube_context
install_minikube_addons
build_base_image
build_app_images
deploy_argocd_application

_log INFO "You're all set! Minikube and its pre-requisites have been installed"
