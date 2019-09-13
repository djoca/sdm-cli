
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

### sdm-tickets.sh
Retrieves the tickets of a group. 
By default, all the open tickets are retrieved, limited by the max results parameter. You can change the default values with the command arguments.

``./sdm-tickets.sh <STATUS_NAME> [OPTIONS]``

The supported arguments are:

|Argument|Description|
|--|--|
| -x | Print raw XML result |
| -a | Comma separated attribute names (only works with -x option) |
| -n | Print ticket numbers only |
| -s | Ticket status name |
| -l | Max result length |

