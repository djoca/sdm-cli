

# SDM CLI

The SDM CLI is a command line interface for the CA Service Desk Management Rest API.

## Dependencies

The scripts dependencies are:

- Tidy
- cURL
- sed
- base64

Make sure you have these installed before using sdm-cli.

## Installation

Before running any script, you need to configure the SDM host.

1. Create the following file in your home directory

``~/.sdm-cli/sdm-cli.conf``

2. Insert a line containing the URL of the SDM REST API

``sdm-host: http://<host>:<port>``

## Authentication

Once configured, you will need to authenticate. The authentication process generates an access key that will be used in all requests until it expires.

To authenticate, use the ./sdm-authenticate.sh script.

``./sdm-authenticate.sh <login>``

It will prompt for your password and print the access key. This access key and the expiration date will be saved in the ~/.sdm-cli directory for further uses.

If you wish to retrieve the access key, you can retrieve the access key with the -r argument.

``./sdm-authenticate.sh -r``

The stored access key is used by the other scripts. When it expires, any attempt run a script (other than sdm-authenticate.sh) will display an expiration message and you will need to authenticate again.

## Usage

After successfully authenticated, the following commands can be used:

### sdm-group.sh
Retrieves a group internal ID.
This script is used internally by sdm-tickets.sh and it's not very useful alone.

``./sdm-group.sh <GROUP_NAME>``

### sdm-status.sh
Retrieves a ticket status internal ID.
This script is used internally by sdm-tickets.sh and it's not very useful alone.

``./sdm-status.sh <STATUS_NAME>``

### sdm-contact.sh
Retrieves a contact internal ID.
This script is used internally by sdm-tickets.sh and it's not very useful alone.

``./sdm-contact.sh <CONTACT_NAME>``

### sdm-tickets.sh
Retrieves a list of tickets.
By default, all the active tickets are retrieved, limited by the max results parameter. You can change the default values with the command arguments.

``./sdm-tickets.sh [OPTIONS]``

The supported arguments are:

|Argument|Description|
|--|--|
| -a, --attr-list | Comma separated attribute names (only works with -x option) |
| --assignee | Tickets assigned to a contact |
| -g, --group | Group name |
| -l | Max result length |
| -n | Print ticket numbers only |
| -o, --opened-by | Tickets opened by a contact |
| -r, --requested-by | Tickets requested by a contact |
| -c, --customer | Tickets affecting a contact |
| -s, --status | Ticket status name |
| -x, --xml | Print raw XML result |

## Cron notifications

A useful use of sdm-cli is to periodically check and notify open tickets. You can schedule sdm-cli executions using cron.

The following cron expression retrieves tickets of "YOUR GROUP NAME" group with "YOUR STATUS NAME" status every 1 minute and, if any, send the ticket numbers by e-mail:

``*/1 * * * * TICKETS=$(sdm-tickets.sh -g "YOUR GROUP NAME" -s "YOUR STATUS NAME" -n 2>&1); [ -n "$TICKETS" ] && echo "Open tickets: $TICKETS" | mail "email@domain"``

The following cron expression does the same, but ticket numbers are displayed by a desktop notification:

``*/1 * * * * TICKETS=$(sdm-tickets.sh -g "YOUR GROUP NAME" -s "YOUR GROUP STATUS" -n 2>&1); [ -n "$TICKETS" ] && (eval "export $(egrep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $LOGNAME gnome-session)/environ | tr -d '\0')"; notify-send "SDM-CLI" "Open tickets: $TICKETS")``

> __Important:__ Remember to include the sdm-cli installation directory in the PATH environment variable used by cron or use the full path in your cron expressions.
