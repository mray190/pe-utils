#!/bin/bash

# Copyright (c) 2019, Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

export DEVID_CLI_DIR=$(cd $(dirname $0) && pwd)
. "$DEVID_CLI_DIR/common.sh"

cli_help() {
  cli_name=${0##*/}
  echo "
  $cli_name - create pelion-edge developer identity
  Version: $(cat $DEVID_CLI_DIR/VERSION)
  Usage: $cli_name [options]

  Options:

    -h                            output usage information
    -v                            verbose logging
    -V                            output the version number
    -d                            generate identity using default values
    -m <lab_instance>             one of the following mbed-cloud lab instance (default: 'mbedcloud') -
                                  [ mds-integration-lab OR mbedcloudintegration,
                                    mds-systemtest OR mbedcloudstaging,
                                    mbedcloud OR us-east-1.mbedcloud,
                                    ap-northeast-1.mbedcloud ]
    -c <lwm2m_coap_url>           lwm2m coap server address (default: 'coaps://lwm2m.us-east-1.mbedcloud.com')
    -g <gw_server_url>            gateway services api address (default: 'https://gateways.us-east-1.mbedcloud.com')
    -s <api_server_url>           api server address (default: 'https://api.us-east-1.mbedcloud.com')
    -k <k8s_server_url>.          edge kubernetes server address (default: 'https://edge-k8s.us-east-1.mbedcloud.com')
    -p <serial_number_prefix>     serial number prefix (default: 'DEV0')
    -n <account_id>               account identifier (mandatory)
    -o <output_directory>         output directory of identity.json (default: './')
    -i <device_id>                edge-core's internal-id (mandatory)
    -w <hw_type>                  hardware version of the gateway, refer configurations section in
                                  $DEVID_CLI_DIR/radioProfile.template.json#L228 (default: 'rpi3bplus')
    -r <radio_config>             radio configuration of the gateway, refer configurations section in
                                  $DEVID_CLI_DIR/radioProfile.template.json#L228 (default: '00')
    -l <led_config>               status led configuration of the gateway (default: '01')

  Examples:

    Typical usage, use the default values to generate an identity file. This will create random uuids for deviceID and accountID.

        $cli_name -d

    Generate a default identity file but with integration lab cloud addresses

        $cli_name -d -m mbedcloudintegration

    Generate a default identity file but relace the hardware version and radio configuration to specified value

        $cli_name -d -w delledge3000 -r 01
"
}

[ ! -n "$1" ] && cli_help && exit 1
[ "$1" == "-v" ] && [ ! -n "$2" ] && cli_help && exit 1

OPTIND=1

while getopts 'hvVdm:c:g:s:k:p:n:o:i:w:r:l:' opt; do
    case "$opt" in
        h|-help)
            cli_help
            exit 0
            ;;
        v)
            VERBOSE=1
            ;;
        V)
            echo "$(cat $DEVID_CLI_DIR/VERSION)"
            exit 0
            ;;
        d)
            USE_DEFAULT=1
            CLOUD_LAB="us-east-1.mbedcloud"
            SERIAL_NUMBER_PREFIX="DEV0"
            RADIO_CONFIG="00"
            HW_VERSION="rpi3bplus"
            LED_CONFIG="01"
            OUTPUT_DIR="./"
            LwM2M_URL="coaps://lwm2m.us-east-1.mbedcloud.com"
            API_URL="https://api.us-east-1.mbedcloud.com"
            GW_URL="https://gateways.us-east-1.mbedcloud.com"
            k8s_URL="https://edge-k8s.us-east-1.mbedcloud.com"
            ;;
        m)
            CLOUD_LAB="$OPTARG"
            case "$CLOUD_LAB" in
                mds-integration-lab|mbedcloudintegration)
                    LwM2M_URL="coaps://mds-integration-lab.dev.mbed.com"
                    API_URL="https://lab-api.mbedcloudintegration.net"
                    GW_URL="https://gateways.mbedcloudintegration.net"
                    k8s_URL="https://edge-k8s.mbedcloudintegration.net"
                    ;;
                mds-systemtest|mbedcloudstaging)
                    LwM2M_URL="coaps://mds-systemtest.dev.mbed.com"
                    API_URL="https://api-os2.mbedcloudstaging.net"
                    GW_URL="https://gateways.mbedcloudstaging.net"
                    k8s_URL="https://edge-k8s.mbedcloudstaging.net"
                    ;;
                mbedcloud|us-east-1.mbedcloud)
                    LwM2M_URL="coaps://lwm2m.us-east-1.mbedcloud.com"
                    API_URL="https://api.us-east-1.mbedcloud.com"
                    GW_URL="https://gateways.us-east-1.mbedcloud.com"
                    k8s_URL="https://edge-k8s.us-east-1.mbedcloud.com"
                    ;;
                ap-northeast-1.mbedcloud)
                    LwM2M_URL="coaps://lwm2m.ap-northeast-1.mbedcloud.com"
                    API_URL="https://api.ap-northeast-1.mbedcloud.com"
                    GW_URL="https://gateways.ap-northeast-1.mbedcloud.com"
                    k8s_URL="https://edge-k8s.ap-northeast-1.mbedcloud.com"
                    ;;
                *)
                    cli_error "Unknown mbed-cloud lab instance - $CLOUD_LAB. Check help for expected values."
                    exit 1
                    ;;
            esac
            ;;
        c)
            LwM2M_URL="$OPTARG"
            ;;
        g)
            GW_URL="$OPTARG"
            ;;
        s)
            API_URL="$OPTARG"
            ;;
        k)
            k8s_URL="$OPTARG"
            ;;
        p)
            SERIAL_NUMBER_PREFIX="$OPTARG"
            ;;
        n)
            ACCOUNT_ID="$OPTARG"
            ;;
        o)
            OUTPUT_DIR="$OPTARG"
            ;;
        i)
            DEVICE_ID="$OPTARG"
            ;;
        w)
            HW_VERSION="$OPTARG"
            ;;
        r)
            RADIO_CONFIG="$OPTARG"
            ;;
        l)
            LED_CONFIG="$OPTARG"
            ;;
        *)
            cli_help
            exit 1
            ;;
    esac
done

shift "$(($OPTIND-1))"

generate_random_hex_number() {
    hexchars="0123456789ABCDEF"
    local hex_rand=$( for ((i = 1; i <= $1; i++)) ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/\1/g' )
    echo "$hex_rand"
}

SN_POSTFIX="$(generate_random_hex_number 6)"

if [ -z "$ACCOUNT_ID" ]; then
    cli_warn "-n <account_id> not specified! generating random uuid..."
    ACCOUNT_ID="$(generate_random_hex_number 32)"
fi

if [ -z "$DEVICE_ID" ]; then
    cli_warn "-i <device_id> not specified! generating random uuid..."
    DEVICE_ID="$(generate_random_hex_number 32)"
fi

cli_debug "Creating developer self-signed certificate."
tmpdir=$(mktemp -d)
. "$DEVID_CLI_DIR/generate_self_signed_certs.sh" $tmpdir

if [ $? -ne 0 ]; then
    cli_error "Failed to generate self signed certs!"
    exit 1
fi

cli_debug "Successfully generated self-signed certs at $tmpdir"

MAC_INDEX_3="$((1 + RANDOM % 250))"
MAC_INDEX_4="$((1 + RANDOM % 250))"
MAC_INDEX_5="$((1 + RANDOM % 250))"

echo "{
    \"serialNumber\": \"$SERIAL_NUMBER_PREFIX$SN_POSTFIX\",
    \"OU\": \"$ACCOUNT_ID\",
    \"deviceID\": \"$DEVICE_ID\",
    \"hardwareVersion\": \"$HW_VERSION\",
    \"radioConfig\": \"$RADIO_CONFIG\",
    \"ledConfig\": \"$LED_CONFIG\",
    \"category\": \"development\",
    \"ethernetMAC\": [
        0,
        165,
        9,
        $MAC_INDEX_3,
        $MAC_INDEX_4,
        $MAC_INDEX_5
    ],
    \"sixBMAC\": [
        0,
        165,
        9,
        0,
        1,
        $MAC_INDEX_3,
        $MAC_INDEX_4,
        $MAC_INDEX_5
    ],
    \"gatewayServicesAddress\": \"$GW_URL\",
    \"edgek8sServicesAddress\": \"$k8s_URL\",
    \"cloudAddress\": \"$API_URL\",
    \"ssl\": {
        \"client\": {
            \"key\": \"$(echo $(cat $tmpdir/device_private_key.pem | awk '{print}' ORS='\\n'))\",
            \"certificate\": \"$(echo $(cat $tmpdir/device_cert.pem | awk '{print}' ORS='\\n'))\"
        },
        \"server\": {
            \"key\": \"$(echo $(cat $tmpdir/device_private_key.pem | awk '{print}' ORS='\\n'))\",
            \"certificate\": \"$(echo $(cat $tmpdir/device_cert.pem | awk '{print}' ORS='\\n'))\"
        },
        \"ca\": {
            \"ca\": \"$(echo $(cat $tmpdir/root_cert.pem | awk '{print}' ORS='\\n'))\",
            \"intermediate\": \"$(echo $(cat $tmpdir/intermediate_cert.pem | awk '{print}' ORS='\\n'))\"
        }
    }
}" > $OUTPUT_DIR/identity.json

cli_debug "$(cat $OUTPUT_DIR/identity.json)"
cli_log 'Successfully generated identity.json'