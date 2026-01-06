function _log() {
    local header=$1
    shift
    local msg=$@
    echo -e "[$PROG][$header]: $msg"
}

function die() {
    local rc=$1
    shift
    local msg=$@
    local death_type=OK
    if [[ $rc -ne 0 ]] ; then
        local death_type="ERROR"
    fi
    echo -e "[$PROG][$death_type]: ${msg}" >&2
    exit $rc
}

function platform_check() {
    local mac_os=$(sw_vers -productVersion 2> /dev/null)
    if [[ -n $mac_os ]]; then
        die 1 ERROR "MacOS detected, unsupported platform"
    fi
}

function start_minikube() {
  if minikube status --format='{{.Host}}' 2>/dev/null | grep -q 'Running' ; then
      _log INFO "Minikube already running"
  else
      _log INFO "Starting minikube..."
      minikube start
  fi
}

function set_minikube_context() {
    kubectl config use-context minikube
}

function install_minikube() {
    if command -v minikube &> /dev/null ; then
        _log INFO "Minikube already installed"
        return 0
    fi
    _log INFO "Downloading & Installing Minikube"
    curl -LO --silent https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 &&
        sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm \
        minikube-linux-amd64
}

function helm_release_is_installed() {
    local release=$1
    local namespace=$2
    if helm status -n $namespace $release &> /dev/null ; then
        _log INFO "$release is already installed"
        return 0
    fi
    return 1
}

function maybe_add_helm_repo() {
    local repo_name=$1
    local repo_url=$2
    if ! helm repo list | grep -Eq "^${repo_name}\s"; then
        helm repo add "$repo_name" "$repo_url"
    fi
}

function helm_repo_update() {
    local repo_name=$1
    local repo_url=$2
    maybe_add_helm_repo $repo_name $repo_url
    helm repo add $repo_name $repo_url && \
        helm repo update 1> /dev/null
}

function helm_install() {
    local release=$1
    local chart=$2
    local namespace=$3
    helm upgrade --install $release $chart \
        -n $namespace \
        --create-namespace 1> /dev/null
}

function install_argocd() {
    local release=argocd
    local namespace=argocd
    local repo_url="https://argoproj.github.io/argo-helm"
    local chart="argo/argo-cd"
    helm_release_is_installed $release $namespace && return 0
    helm_repo_update $release $repo_url
    helm_install $release $chart $namespace
}

function install_external_secrets() {
    local release=external-secrets
    local namespace=external-secrets
    local repo_url="https://charts.external-secrets.io"
    local chart="external-secrets/external-secrets"
    helm_release_is_installed $release $namespace && return 0
    helm_repo_update $release $repo_url
    helm_install $release $chart $namespace
}

function install_minikube_addons() {
    install_external_secrets && \
        install_argocd
}

function assert_binaries() {
    local required_binaries=${@:-${REQUIRED_BINARIES}}
    local missing_binaries=""
    for cmd in $required_binaries ; do
        if ! command -v $cmd &> /dev/null ; then
            missing_binaries+="$cmd "
        fi
    done
    if [[ -n $missing_binaries ]] ; then
        printf "Command not found: %s\n" $missing_binaries
        return 1
    fi
    return 0
}

function build_image() {
    local image_and_tag=$1
    local path=${2:-.}
    local dockerfile=${3:-"Dockerfile"}
    pushd $path &> /dev/null
    minikube image build -t $image_and_tag -f $dockerfile . || \
        die 1 "Failed to build image: $image_and_tag"
    popd &> /dev/null
}

function build_app_images() {
    for app in $APPS ; do
        build_image ${app}:$TAG $APPS_PATH/$app
    done
}

function build_base_image() {
    build_image "python-base:latest" $APPS_PATH Dockerfile.python-base
}

function deploy_argocd_application() {
    _log INFO "Installing ArgoCD application"
    kubectl apply -f $APPS_PATH/application.yaml
}
