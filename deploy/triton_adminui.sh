#!/usr/bin/env sh

#A script for deploying the cert to your Triton Docker container

#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
triton_adminui_deploy() {
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

  _ckey_str=$(awk 'NF {sub(/\r/,""); printf "%s\\n",$0;}' $_ckey)
  _cfull_cert_str=$(awk 'NF {sub(/\r/,""); printf "%s\\n",$0;}' $_ccert $_cfullchain)

  # Obtain adminui UUID
  _admin_uuid=$(sdc-sapi /services | json -H --array uuid -c 'name == "adminui"')
  _debug _admin_uuid "$_admin_uuid"

  # Update SAPI/adminui
  _info "Updating adminui/SAPI..."
  echo "{\
    \"metadata\": {\
      \"ssl_certificate\": \"$_cfull_cert_str\",\
      \"ssl_key\": \"$_ckey_str\"\
    }\
  }" | sapiadm update $_admin_uuid

  # Print service status
  _debug svcs "$(sdc-login -l cloudapi 'svcs -x')"
  _debug certs "$(sdc-login -l cloudapi 'echo QUIT | openssl s_client -host 127.0.0.1 -port 443 -showcerts 2>&1')"

  return 0
}
