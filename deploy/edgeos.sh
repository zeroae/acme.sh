function restart_web_gui() {
    # https://community.ubnt.com/t5/EdgeMAX/GUI-restart-via-ssh/m-p/898366#M34391
    pid=$(ps -e | grep lighttpd | awk '{print $1;}')
    if [ "$pid" != "" ]; then kill $pid; fi
    /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
}

function atexit() {
    eval $(vyatta_exit_configure)
}

function edgeos_deploy() {
    _info 'EdgeOS: loading script template'
    source /opt/vyatta/etc/functions/script-template
    eval $(vyatta_configure)
    trap atexit EXIT

    edgeos_gui_deploy $*
    edgeos_vpn_deploy $*

    save
}

function edgeos_gui_deploy() {
    _cdomain="$1"
    _ckey="$2"
    _ccert="$3"
    _cca="$4"
    _cfullchain="$5"

    _info 'Creating Key+Cert PEM'
    # compute md5sum of existing PEM
    _ckey_cer=/config/auth/$_cdomain.pem
    cat $_ckey $_ccert > $_ckey_cer
    chmod 600 $_ckey_cer

    _info 'EdgeOS: setting service gui'

    $SBIN_PATH/my_set service gui ca-file $_cfullchain
    $SBIN_PATH/my_set service gui cert-file $_ckey_cer

    sg vyattacfg -c $SBIN_PATH/my_commit

    _info 'EdgeOS: restarting WebUI'
    restart_web_gui
}

function edgeos_vpn_deploy() {
   _cdomain="$1"
   _ckey="$2"
   _ccert="$3"
   _cca="$4"
   _cfullchain="$5"

   _peers=$($API showConfig custom-attribute acme.sh--${_cdomain}--peers value)
   if ( _contains "$_peers" "Configuration under specified path is empty" ||
       ! _startswith "$_peers" ' value ') ; then
       _err "custom-attribute acme.sh--${_cdomain}--peers is either empty or invalid"
       return 1
   else
       _peers=${_peers:6}
       _peers=${_peers//\"/}
   fi
   for peer in $_peers; do
       _mode=$($API showConfig vpn ipsec site-to-site peer ${peer} authentication mode)
       if ! _contains "$_mode" 'mode x509'; then
           _info "EdgeOS: skipping ${peer} authentication, mode is not x509"
           continue
       fi
       _info "EdgeOS: setting vpn ipsec site-to-site peer ${peer} authentication"
       edit vpn ipsec site-to-site peer ${peer} authentication x509
       $SBIN_PATH/my_set ca-cert-file $_cfullchain
       $SBIN_PATH/my_set cert-file $_ccert
       $SBIN_PATH/my_set key file $_ckey
   done

   sg vyattacfg -c $SBIN_PATH/my_commit

   _info "EdgeOS: restarting vpn"
   $BIN_PATH/vyatta-op-cmd-wrapper restart vpn
}
