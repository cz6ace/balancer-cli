# balancer-cli
Apache HTTP server balancer manager CLI

This is shell script for sending commands to Apache HTTP server balancer-manager manager using URI requests.

# Usage
```bash
Usage: ./balancer-cli.sh [OPTION]... command [ARG]
Executes command in apache balancer manager.

Options:
  --host host       host of balancer manager  (default localhost)
  --port            port of the balancer manager (default 80)
  --path            path of the balancer manager (default balancer-manager)
  -h --help         show this help

Commands:
  balancers                   list all balancers
  enable <balancer> <worker>  enable the worker in the specified balancer, clears the drain flag
  disable <balancer> <worker> disable the worker in the specified balancer
  drain <balancer> <worker>   set the worker to drain mode in the specified balancer
```

# Examples
## list balancers and workers
./balancer-cli.sh --host localhost --port 80 balancers

## disable the worker http://worker1:8080 in balancer bal1
./balancer-cli.sh --host localhost --port 80 disable bal1 http://worker1:8080

## set the worker http://worker1:8080 in balancer bal1 to drain mode
./balancer-cli.sh --host localhost --port 80 drain bal1 http://worker1:8080

# Defaults
Script looks in current directory and then in user's home directory for file ```.balancer-cli``` which can specify the hostname, port. One can use the template with default values, uncomment and copy into the user home directory.
