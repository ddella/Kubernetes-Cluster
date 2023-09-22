# Extend `kubectl` with plugins

## Installing kubectl plugins
A plugin is a standalone executable file, whose name begins with `kubectl-`. To install a plugin, move its executable file to anywhere on your PATH.

## Discovering plugins
`kubectl` provides a command `kubectl plugin list` that searches your PATH for valid plugin executables. Executing this command causes a traversal of all files in your PATH. Any files that are executable, and begin with `kubectl-` will show up in the order in which they are present in your PATH in this command's output. A warning will be included for any files beginning with `kubectl-` that are not executable. A warning will also be included for any valid plugin files that overlap each other's name.

## Example plugin
```sh
cat <<'EOF' | sudo tee /usr/local/bin/kubectl-foo > /dev/null
#!/bin/bash

# optional argument handling
if [[ "$1" == "version" ]]
then
    echo "Version: 1.0.0"
    exit 0
fi

# optional argument handling
if [[ "$1" == "config" ]]
then
    echo "Configuration:"
    exit 0
fi

echo "I am a plugin named 'kubectl-foo'"
EOF
```

Make it executable:
```sh
sudo chmod +x /usr/local/bin/kubectl-foo
```

## Test

```
kubectl foo
I am a plugin named 'kubectl-foo'

kubectl foo version
Version: 1.0.0

kubectl foo config
Configuration:
```

# References
https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/
