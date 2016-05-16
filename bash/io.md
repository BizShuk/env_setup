# io direction

- `command > <file>` redirect to file
- `> <file>` , truncate file to 0 length
- `>> <file>` , append to file
- `1> <file>` , stdout to file
- `2> <file>` , stderr to file
- `&> <file>` , both stdout and stderr to file
- `2>&1` , redirect stderr to stdout
- `< <file>` , accept input from a file
- `<<< $var` , accept input from variable

# file desciptor (fd)
A temporary redirect operation.  
syntax:`<src_fd>[<>]&[<fd>-]`  

- `<fd><&-` , close input fd
- `<fd>>&-` , close output fd
- `>&<fd>` , redirect to <fd>












