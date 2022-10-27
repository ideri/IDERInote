#!/usr/bin/env python3
# -*- encoding: utf-8; py-indent-offset: 4 -*-

## notify-via-IDERInote (WATO UI)
## This is the Checkmk WATO UI file describing the UI in Checkmk for IDERInote.py notification script.
## 
## Author: IDERI GmbH (Sebastian Mann)
## Homepage: https://www.ideri.com
## Repo URL: https://github.com/ideri/IDERInote-checkMk_plugins
## 
## History:
## (2022-10-27) 0.8: initial release
##              Tested with checkmk 2.0.0p25 + 2.1.0p14

from cmk.gui.i18n import _

from cmk.gui.valuespec import (
    Dictionary,
    Integer,
    CascadingDropdown,
    Password,
    TextInput,
    FixedValue,
    HTTPUrl,
)


register_notification_parameters(
    "IDERInote.py",
    Dictionary(
        title=_("Create notification with the following parameters"),
        optional_keys=[
            "inote_api_insecureconnection", 
            "inote_msg_popup_or_fs", 
            "inote_msg_showticker", 
            "inote_msg_exclude", 
            "inote_msg_notifyreceive", 
            "inote_msg_notifyacknowledge", 
            "inote_msg_showonwinlogononly", 
            "inote_msg_showonwinlogon", 
            "inote_msg_homeoffice_or_networkrange",
            "checkmkUrl",
        ],
        elements = 
        [
            (
                "inote_api_url",
                HTTPUrl(
                    title=_("The URL to the IDERI note API"),
                    help=_("The URL of the IDERI note API "
                           "(example: 'https://<servername>:<port>/IDERInote/api')."
                    ),
                    allow_empty=False,
                ),
            ),
            (
                "inote_api_insecureconnection",
                FixedValue(
                    value=True,
                    title=_("Allow insecure server connections when using SSL."),
                    totext=_("Ignore unverified HTTPS request warnings. Use with caution."),
                    help=_("Ignore unverified HTTPS request warnings. Use with caution."),
                ),
            ),
            (
                "inote_api_username",
                TextInput(
                    title=_("Username"),
                    placeholder=_("<domain>\<username>"),
                    help=_("The user name of the IDERI note API user."),
                    size=40,
                    allow_empty=False,
                ),
            ),
            (
                "inote_api_userpass",
                Password(
                    title=_("The password of the IDERI note API user."),
                    help=_("The password of the IDERI note API user."),
                    size=40,
                ),
            ),
            (
                "inote_msg_addressingmode",
                CascadingDropdown(
                    title=_("IDERI note AddressingMode:"),
                    help=_("Choose an IDERI note addressing mode."),
                    sorted=False,
                    choices=[
                        (
                            "UserOnly",
                            _("Send message to users only"),
                        ),
                        (
                            "UserAndComputer",
                            _("Send message to users and computers"),
                        ),
                        (
                            "ComputerOnly",
                            _("Send message to computers only"),
                        ),
                    ],
                ),
            ),
            (
                "inote_msg_duration",
                Integer(
                    title = _("Message duration (minutes)"),
                    help = _("The duration of the IDERI note message in minutes."),
                    size = 20,
                    default_value=0,
                    minvalue=0,
                ),
            ),
            (
                "inote_msg_recipient",
                TextInput(
                    title=_("IDERI note message recipients."),
                    placeholder=_("Comma separated list: '<dom>\<user>, <dom>\<group>, <dom>\<computer>$'"),
                    help=_("The recipients of the IDERI note message as a comma"
                           "separated string. Make sure to specify the "
                           "recipients with their domain (Example: "
                           "'note\homer.simpson, note\server01$, note\GRP-IT')"),
                    size=80,
                    allow_empty=False,
                ),
            ),
            (
                "inote_msg_exclude",
                TextInput(
                    title=_("IDERI note message excludes."),
                    placeholder=_("Comma separated list: '<dom>\<user>, <dom>\<group>, <dom>\<computer>$'"),
                    help=_("The excludes of the IDERI note message as a comma "
                           "separated string. Make sure to specify the "
                           "recipients with their domain (Example: "
                           "'note\homer.simpson, note\server01$, note\GRP-IT')"),
                    size=80,
                    allow_empty=False,
                ),
            ),
            (
                "inote_msg_popup_or_fs",
                Dictionary(
                    title="Show message in popup or fullscreen",
                    optional_keys=[],
                    elements=[
                        (
                            "selection",
                            CascadingDropdown(
                                title=_("Select how to display the message:"),
                                help=_("Select how to display the IDERI note message"),
                                sorted=False,
                                choices=[
                                    (
                                        "showpopup",
                                        _("Show in popup"),
                                    ),
                                    (
                                        "showfullscreen",
                                        _("Show in full screen"),
                                    ),
                                    (
                                        "showfullscreenandlock",
                                        _("Show in full screen and lock workstation"),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            (
                "inote_msg_showticker",
                FixedValue(
                    value=True,
                    title=_("Show message in the ticker"),
                    totext = _("True"),
                    help=_("Show the IDERI note message in the ticker."),
                ),
            ),
            (
                "inote_msg_notifyreceive",
                FixedValue(
                    value=True,
                    title=_("Notify IDERI note server when message is received."),
                    totext = _("True"),
                    help=_("Notify the IDERI note server when message is "
                           "received by the user."),
                ),
            ),
            (
                "inote_msg_notifyacknowledge",
                FixedValue(
                    value=True,
                    title=_("Notify IDERI note server when message is acknowledged."),
                    totext = _("True"),
                    help=_("Notify the IDERI note server when the message is "
                           "acknowledged by the user."),
                ),
            ),
            (
                "inote_msg_showonwinlogon",
                FixedValue(
                    value=True,
                    title=_("Show IDERI note message on the logon screen only."),
                    totext = _("True"),
                    help=_("Show IDERI note message on the logon screen. Note: "
                           "This will only work with an addressing mode "
                           "including computers."),
                ),
            ),
            (
                "inote_msg_showonwinlogononly",
                FixedValue(
                    value=True,
                    title=_("Show IDERI note message on the logon screen."),
                    totext = _("True"),
                    help=_("Show IDERI note message on the logon screen only. "
                           "Note: This will only work with an addressing mode "
                           "including computers."),
                ),
            ),
            (
                "checkmkUrl",
                HTTPUrl(
                    title=_("The URL to check_mk web interface."),
                    help=_("The URL of the check_mk web interface "
                           "(example: 'https://<servername>:<port>'). This "
                           "will include a link to the host or service in "
                           "checkmk into the IDERI note message. Links are "
                           "only shown in an IDERI note popup message. Messages"
                           "shown in ticker or full screen cannot show the link."),
                    allow_empty=False,
                ),
            ),
            (
                "inote_plugin_loglevel",
                CascadingDropdown(
                    title=_("Log mode:"),
                    help=_("Setting this to a value other than 'StandPard' the "
                           "script will write more information to the notify.log "
                           "of checkmk. Note: Levels 'Debug' and 'Trace' will "
                           "write extensive amount of data to the notify log."),
                    sorted=False,
                    choices=[
                        (
                            "1",
                            _("Standard"),
                        ),
                        (
                            "2",
                            _("Verbose"),
                        ),
                        (
                            "4",
                            _("Debug"),
                        ),
                        (
                            "8",
                            _("Trace"),
                        ),
                    ],
                ),
            ),
        ],
    )
)