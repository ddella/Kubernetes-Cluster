# Linux vi arrow keys not working
If your arrow keys don't work in `vi` in insert mode at home, just add the following line in your local `.vimrc` file:

```sh
cat <<EOF >> .vimrc
:set nocompatible
:set backspace=indent,eol,start
EOF
```

## If you use `sudo`, you can use either solution:

Add a file `.vimrc` for the use `root`
```sh
cat <<EOF | sudo tee -a /root/.vimrc
:set nocompatible
:set backspace=indent,eol,start
EOF
```

OR use `sudo -E` every time you use `vi`

```sh
sudo -E /path/file
```
