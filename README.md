# nagios-checks

## Synopsis

**nagios-checks** is my compilation of home-grown check scripts for use with the Nagios monitoring platform.

## Code Example

### check_flexlm_expire
./check_flexlm_expire -w 60 -c 30 -f abaqus

### check_flexlm_feature

### check_hpc_queues

### check_mem

### check_sw_vpn_tunnels

## Motivation

I have developed these scripts largely in response to not having something I needed. 

In essense, they are my attempts to scratch very particular itches that I've encountered.

## Installation

Temporary hint: Copy `check_*` scripts into your Nagios **libexec** directory and ensure that they are all executable (chmod 755). You may also need to update certain variables inside to match your local situation.

Provide code examples and explanations of how to get the project.

## API Reference

Depending on the size of the project, if it is small and simple enough the reference docs can be added to the README. For medium size to larger projects it is important to at least provide a link to where the API reference docs live.

## Tests

Describe and show how to run the tests with code examples.

## Contributors

Let people know how they can dive into the project, include important links to things like issue trackers, irc, twitter accounts if applicable.

## License

A short snippet describing the license (MIT, Apache, etc.)



