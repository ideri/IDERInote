#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# IDERI note
# Bulk: no

import sys
try:
    import json
    import requests
    from requests.auth import HTTPBasicAuth
    from cmk.notification_plugins import utils
    from enum import (
        IntEnum,
        IntFlag,
    )
    from datetime import (
        datetime,
        timedelta,
    )
except Exception as ex:
    sys.exit("""Error importing python modules. - """ + ex)


# Priority enum
class Priority(IntEnum):
    INFORMATION = 0
    WARNING = 0x01
    ALERT = 0x02

# AddressingMode enum
class AddressingMode(IntEnum):
    UserOnly = 0
    UserAndComputer = 0x1000
    ComputerOnly = 0x2000

# Output detail mode for the notify.log
class LogLevel(IntFlag):
    Standard = 0x01
    Verbose = 0x02
    Debug = 0x04
    Trace = 0x08

context = None
logLevel = 1
message = {
    "TEXT": "",
    "STARTTIMEUTC": datetime.utcnow(),
    "ENDTIMEUTC": datetime.utcnow(),
    "LINKTARGET": "",
    "LINKTEXT": "",
    "NETWORKRANGEIDS": [],
    "PRIORITY": Priority.INFORMATION,
    "NOTIFYRECEIVE": False,
    "NOTIFYACKNOWLEDGE": False,
    "OPTNODELIVERYIFREVACK": False,
    "OPTNODELIVERYIFACKONOTHERCOMP": False,
    "OPTNODELIVERYIFLOGGEDINAFTERMSGSTART": False,
    "SHOWPOPUP": False,
    "SHOWTICKER": False,
    "SHOWFULLSCREEN": False,
    "SHOWFULLSCREENANDLOCK": False,
    "SHOWLINKMAXIMIZED": False,
    "ADDRESSINGMODE": AddressingMode.UserOnly,
    "SHOWONWINLOGON": False,
    "SHOWONWINLOGONONLY": False,
    "HOMEOFFICEUSERSEXCLUDE": False,
    "HOMEOFFICEUSERSONLY": False,
    "RECIPIENT": [],
    "EXCLUDE": [],
    "NETWORKRANGEEXCLUDE": False,
    "PUSH": False
}

tmpl_host_text = """[$NOTIFICATIONTYPE$]
Host $HOSTNAME$ is $HOSTSTATE$.

Host:     $HOSTNAME$ ($HOSTALIAS$)
IPv4:     $HOST_ADDRESS_4$
IPv6:     $HOST_ADDRESS_6$
Event:    $EVENT_TXT$

Output:   $HOSTOUTPUT$
"""

tmpl_service_text = """[$NOTIFICATIONTYPE$]
Service $SERVICEDESC$ on $HOSTNAME$ is $SERVICESTATE$.

Host:     $HOSTNAME$ ($HOSTALIAS$)
IPv4:     $HOST_ADDRESS_4$
IPv6:     $HOST_ADDRESS_6$
Service:  $SERVICEDESC$
Event:    $EVENT_TXT$

Output:   $SERVICEOUTPUT$
"""


def get_inote_message_text(context):
    """Composes the text for the IDERI note message.

    Args:
        context (dict): A dict returned by utils.collect_context() from cmk.notification_plugins holding the parameters passed from Checkmk.

    Returns:
        str: A string representing the text for the IDERI note message.
    """
    
    writeVerbose("Composing IDERI note message text...")
    
    # EVENT_TXT based on NOTIFICATIONTYPE
    notification_type = context["NOTIFICATIONTYPE"]
    if notification_type in ["PROBLEM", "RECOVERY"]:
        txt_info = "$PREVIOUS@HARDSHORTSTATE$ -> $@SHORTSTATE$"
    elif notification_type.startswith("FLAP"):
        if "START" in notification_type:
            txt_info = "Started Flapping"
        else:
            txt_info = "Stopped Flapping ($@SHORTSTATE$)"
    elif notification_type.startswith("DOWNTIME"):
        what = notification_type[8:].title()
        txt_info = "Downtime " + what + " ($@SHORTSTATE$)"
    elif notification_type == "ACKNOWLEDGEMENT":
        txt_info = "Acknowledged ($@SHORTSTATE$) by $@ACKAUTHOR$"
        txt_info += "Comment:  "
    elif notification_type == "CUSTOM":
        txt_info = "Custom Notification ($@SHORTSTATE$)"
    else:
        txt_info = notification_type  # Should never happen

    context["EVENT_TXT"] = utils.substitute_context(
        txt_info.replace("@", context["WHAT"]), context
    )

    # HOST or SERVICE
    if context["WHAT"] == "HOST":
        tmpl_text = tmpl_host_text
    else:
        tmpl_text = tmpl_service_text

    writeDebug("Composing message text done.")
    return utils.substitute_context(tmpl_text, context)

def writeVerbose(string):
    global logLevel
    if logLevel % LogLevel.Verbose == 0:
        print("VERBOSE: " + string)

def writeDebug(string):
    global logLevel
    if logLevel % LogLevel.Debug == 0:
        print("DEBUG: " + string)

def writeTrace(string):
    global logLevel
    if logLevel % LogLevel.Trace == 0:
        print("TRACE: " + string)

def send_inote_message(inote_api_url, inote_api_user, inote_api_pass, ignore_cert, inote_message):
    writeVerbose("Creating new IDERI note message...")

    # invert the bool for apiIgnoreSslVerification
    verifySsl = not ignore_cert

    # compose URL
    writeDebug('Composing the API url...')
    url = inote_api_url + "/v1/messages"
    
    # Start and Endtime to required format
    writeDebug('Formatting start and end times...')
    inote_message['STARTTIMEUTC'] = inote_message['STARTTIMEUTC'].strftime("%Y-%m-%dT%H:%M:%S")
    inote_message['ENDTIMEUTC'] = inote_message['ENDTIMEUTC'].strftime("%Y-%m-%dT%H:%M:%S")

    # Write message string to log
    writeTrace("Message object used:")
    writeTrace(json.dumps(inote_message, indent = 4))

    writeDebug('Calling API to create new message...')
    r = requests.post(url=url, verify=verifySsl, auth=HTTPBasicAuth(inote_api_user, inote_api_pass), json=inote_message, headers={'Connection':'close'})

    if r.status_code != 200:
        sys.stderr.write(
            "Failed to send IDERI note message. Status: {}, Response: {}\n".format(
                r.status_code, r.text
            )
        )
        return 1  # Temporary error to make Checkmk retry

    sys.stdout.write(
        "IDERI note message created."
    )
    return 0

def check_is_int(string, base=None):
    try:
        ok = int(string, base) if base else int(string)
        return True
    except Exception:
        return False

def parse_inote_message_params(context, message):
    """Parses the parameters passed from checkmk and modifies the message dict accoringly. Returns: message dict

    Args:
        context (dict): A dict returned by utils.collect_context() from cmk.notification_plugins holding the parameters passed from Checkmk.
        message (dict): A dict representing the IDERI note message.

    Returns:
        dict: A dict representiing the IDERI note message.
    """
    
    writeVerbose('Parsing parameters to message...')
    # parse message vars
    for key, val in context.items():
        if str(key).startswith("PARAMETER_INOTE_MSG_"):
            msgParamName = str(key).split("_")[-1]
            writeDebug('Trying parameter "' + key + '"...')
            # parse start + end
            if msgParamName == "DURATION":
                writeDebug('Calculating and setting start and end of message...')
                start = datetime.utcnow()
                end = start + timedelta(minutes=int(val))
                message['STARTTIMEUTC'] = start
                message['ENDTIMEUTC'] = end
            # parse Recipient and Exclude
            elif msgParamName == "RECIPIENT" or msgParamName == "EXCLUDE":
                writeDebug('Getting string list from value...')
                message[msgParamName] = [s.strip() for s in str.split(val,',')]
            # parse popup and fullscreen
            elif key == "PARAMETER_INOTE_MSG_POPUP_OR_FS_SELECTION":
                writeDebug('Setting message to ' + str(val).upper() + '...')
                message['SHOWPOPUP'] = True # No matter what is specified, SHOWPOPUP must always be set
                message[str(val).upper()] = True
            # parse addressing mode
            elif msgParamName == "ADDRESSINGMODE":
                writeDebug('Setting ADDRESSINGMODE to ' + str(val) + '...')
                message[msgParamName] = AddressingMode[str(val)]
            # parse other params
            elif str(msgParamName) in message: 
                if check_is_int(val):
                    writeDebug('Converting value to int...')
                    message[msgParamName] = int(val)
                elif val == 'True' or val == 'False':
                    writeDebug('Converting value to bool...')
                    message[msgParamName] = bool(val)
                else:
                    writeDebug('Leaving value as string...')
                    message[msgParamName] = val
    return message

def add_link_to_inote_message(context, inotemessage):
    """If the checkmk 'checkmkurl' is set, determine if a link can be added to
    the IDERI note message and do so if appropriate. Returns: message dict"""
    
    writeVerbose('Checking if a link to check_mk should be added...')
    if 'PARAMETER_CHECKMKURL' in context:
        if inotemessage['SHOWFULLSCREEN'] == False and inotemessage['SHOWFULLSCREENANDLOCK'] == False:
            if context['WHAT'] == 'HOST':
                writeDebug('Composing host url...')
                linkTarget = context['PARAMETER_CHECKMKURL'] + "/" + context['OMD_SITE'] + "/" + context['HOSTURL']
            elif context['WHAT'] == 'SERVICE':
                writeDebug('Composing service url...')
                linkTarget = context['PARAMETER_CHECKMKURL'] + "/" + context['OMD_SITE'] + "/" + context['SERVICEURL']
            if linkTarget != "":
                writeVerbose("Adding link to IDERI note message...")
                inotemessage['LINKTARGET'] = str(linkTarget)
                inotemessage['LINKTEXT'] = "Show in Checkmk"
    return inotemessage

def _get_inote_priority_from_hoststate(hoststate):
    writeDebug("Converting HOSTSTATE '" + hoststate + "' to IDERI note priority...")
    if hoststate == "UP":
        return Priority.INFORMATION
    elif hoststate == "DOWN":
        return Priority.ALERT
    elif hoststate == "UNREACHABLE":
        return Priority.WARNING
    return Priority.WARNING

def _get_inote_priority_from_servicestate(servicestate):
    writeDebug("Converting SERVICESTATE '" + servicestate + "' to IDERI note priority...")
    if servicestate == "OK":
        return Priority.INFORMATION
    elif servicestate == "WARNING":
        return Priority.WARNING
    elif servicestate == "CRITICAL":
        return Priority.ALERT
    elif servicestate == "UNKNOWN":
        return Priority.WARNING
    return Priority.WARNING

def get_inote_priority_from_state(context):
    """Returns the IDERI note priority for the message based on checkmk states.

    Args:
        context (dict): A dict returned by utils.collect_context() from cmk.notification_plugins holding the parameters passed from Checkmk.

    Returns:
        Priority: The priority for IDERI note message.
    """
    
    writeVerbose("Getting the IDERI note priority based on host or servicestate...")
    if context["WHAT"] == "HOST":
        return _get_inote_priority_from_hoststate(context["HOSTSTATE"])
    else:
        return _get_inote_priority_from_servicestate(context["SERVICESTATE"])



def main():
    global logLevel
    global context
    global message
    context = utils.collect_context()
    logLevel = LogLevel(int(context['PARAMETER_INOTE_PLUGIN_LOGLEVEL']))

    ## If log level DEBUG write NOTIFY_ env vars to notify.log
    writeTrace("Values passed to script (NOTIFY_ env variables):")
    for key, val in context.items():
        writeTrace(key + '=' + val)
    writeTrace('--- END NOTIFY_ VARIABLES ---')

    # Get the IDERI note API information
    api_url = context['PARAMETER_INOTE_API_URL']
    api_user = context['PARAMETER_INOTE_API_USERNAME']
    api_pass = context['PARAMETER_INOTE_API_USERPASS']
    api_connection_ignore_cert = context.get("PARAMETER_INOTE_API_INSECURECONNECTION", "False")

    # Fill the IDERI note message object with given values
    message = parse_inote_message_params(context, message)
    message = add_link_to_inote_message(context, message)
    message["TEXT"] = get_inote_message_text(context)
    message["PRIORITY"] = get_inote_priority_from_state(context)

    # Create the IDERI note message
    return send_inote_message(api_url, api_user, api_pass, bool(api_connection_ignore_cert), message)

if __name__ == "__main__":
    sys.exit(main())