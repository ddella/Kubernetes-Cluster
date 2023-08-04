# calicoctl ipam check
Generate a report using the check command:
```sh
calicoctl ipam check -o report.json
```

# calicoctl ipam show
```sh
calicoctl ipam show
```

```
+----------+---------------+-----------+------------+--------------+
| GROUPING |     CIDR      | IPS TOTAL | IPS IN USE |   IPS FREE   |
+----------+---------------+-----------+------------+--------------+
| IP Pool  | 10.255.0.0/16 |     65536 | 16 (0%)    | 65520 (100%) |
+----------+---------------+-----------+------------+--------------+
```

```sh
calicoctl ipam show --show-blocks
```

```
+----------+------------------+-----------+------------+--------------+
| GROUPING |       CIDR       | IPS TOTAL | IPS IN USE |   IPS FREE   |
+----------+------------------+-----------+------------+--------------+
| IP Pool  | 10.255.0.0/16    |     65536 | 16 (0%)    | 65520 (100%) |
| Block    | 10.255.153.64/26 |        64 | 4 (6%)     | 60 (94%)     |
| Block    | 10.255.18.128/26 |        64 | 4 (6%)     | 60 (94%)     |
| Block    | 10.255.74.64/26  |        64 | 5 (8%)     | 59 (92%)     |
| Block    | 10.255.77.128/26 |        64 | 3 (5%)     | 61 (95%)     |
+----------+------------------+-----------+------------+--------------+
```

# References
[calicoctl ipam check](https://docs.tigera.io/calico/latest/reference/calicoctl/ipam/check)  
