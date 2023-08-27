# Install TMUX

```sh
sudo nala update
sudo nala install tmux
```

# Create script
This script will start multiple SSH sessions:
```sh
cat <<EOF > k8s-tmux.sh
#!/bin/bash

ssh_list=( daniel@k8smaster1 daniel@k8sworker1 daniel@k8sworker2 daniel@k8sworker3 )

split_list=()
for ssh_entry in "${ssh_list[@]:1}"; do
    split_list+=( split-pane ssh "$ssh_entry" ';' )
done

tmux new-session ssh "${ssh_list[0]}" ';' \
    "${split_list[@]}" \
    select-layout tiled ';' \
    set-option -w synchronize-panes
EOF
```

```sh
chmod +x k8s-tmux.sh
```

# Start SSH Sessions
```sh
./k8s-tmux.sh
```
