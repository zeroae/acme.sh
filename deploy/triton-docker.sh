#!/usr/bin/env sh

#A script for deploying the cert to your Triton Docker container

#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
triton_docker_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  _chainedcert=$(mktemp)
  cat _ccert _cfullchain > $_chainedcert
  _debug _chainedcert "$_chainedcert"

  sdcadm experimental install-docker-cert -k $_ckey -c $_chainedcert

  return 0
}
