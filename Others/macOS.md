# macOS Related

# macOS Static Route

## Display routing table:
You can use the following command `netstat -rn` and use `grep` to filter with a specific network on the Terminal.

```sh
netstat -rn | grep 198.19.0
```

## Add a static route temporarily
To add a static route:
```sh
sudo route -n add -net 198.19.0.0/24 192.168.13.61
```

## Delete a static route:
To delete a static route:
```sh
sudo route -n delete 198.19.0.0/24
```
