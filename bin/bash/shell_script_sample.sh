#!/usr/bin/env bash

# switch case sample , with regex
case $mode in
"update")
    mode="update"
    ;;
*)
    mode="server"
    ;;
esac

# what kind of path defined?
filepath="*.lua"
st=0
error_msg="\n"

#for filename in $@; do
for filename in $filepath; do
    # for syntax check
    result_msg=$(luac5.1 "$filename" 2>&1)

    if [ $? != 0 ]; then
        st=1
        error_msg="$error_msg$filename syntan error...\n"
    fi
done

if [ "$st" == "1" ]; then
    echo -e "$error_msg" 1>&2
    exit 1
fi

compiled_file=()

# luajit from lua to luac.tmp  , after finish these mv all luac.tmp to real server dir
for entry in $filepath; do
    luac_tmp_file=$entry"c.tmp"
    result_msg=$(luajit -bg "$entry" "$luac_tmp_file" 2>&1)
    result_st=$?
    if [ "$result_st" != "0" ]; then
        echo -e "${entry} get error!\n ${result_msg}" 1>&2
        exit 1
    fi
    compiled_file+=("$luac_tmp_file")
    #    echo ${compiled_file[*]}
done

for filename in ${compiled_file[@]}; do
    mv "$filename" "${filename:0:-4}"
done

if [ $st == 0 ]; then
    echo "successful..."
fi

exit 0
