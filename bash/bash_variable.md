# variable

## env
PATH

## variable meaning
- `$?` , last command status
- `$0` , shell name
- `$#` , parameter's count
- `$*` , no diff with $@ , but "$@" => "" for each one parameter
- `$@` , no diff with $* , but "$*" => "" for all parameter together
- `$!` , last job id
- `$$` , current shell id
- `$_` , last argument in last command

## variable operation

- `${var:start:length}` , get substring  
- `${var//search/substitude}` , replace substring  
  
- `${var:=value}` , output: default , "$var" == "<value>"  
- `${var:-value}` 如果var有值了那麼就用原本的值，不然用value的值
- `${var:+value}` 如果var有值就用value的值
- `${var:?message}` var有值那麼就用原本的值，不然就印出message 值到螢幕並且跳出。
- `${var:%pattern}` 如果pattern與var後面的部份吻合，傳回剩下沒有 吻合部份給var
- `${var:#pattern}` 如果pattern與var前面的部份吻合，傳回剩下沒有 吻合部份給var


