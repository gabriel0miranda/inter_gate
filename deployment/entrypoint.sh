#!/bin/sh
set -e

supervisorctl -c /etc/inter_gate/inter_gate.conf start inter_gate
