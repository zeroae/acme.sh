#!/usr/bin/env sh

#A script for deploying the cert to your Triton Docker container

#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
triton_api_deploy() {
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
  cat $_ccert $_cfullchain > $_chainedcert
  _debug _chainedcert "$_chainedcert"

  CLOUDAPI=$(vmadm list |grep cloudapi0| awk '{ print $1}' )
  CLOUDAPI_PEM=/zones/${CLOUDAPI}/root/opt/smartdc/cloudapi/ssl/stud.pem
  _debug CLOUDAPI_PEM $CLOUDAPI_PEM

  # Write the PEM
  openssl rsa -in $_ckey -out $CLOUDAPI_PEM
  cat $_ccert >> $CLOUDAPI_PEM
  cat $_cfullchain >> $CLOUDAPI_PEM

  # Restart the Service
  for i in 8081 8082 8083 8084; do
      sdc-login -l cloudapi "svcadm restart cloudapi:cloudapi-$i"
      sleep 2
  done
  sdc-login -l cloudapi "svcadm restart stud"

  # Print service status
  _debug svcs "$(sdc-login -l cloudapi 'svcs -x')"
  _debug certs "$(sdc-login -l cloudapi 'echo QUIT | openssl s_client -host 127.0.0.1 -port 443 -showcerts')"

  return 0
}
