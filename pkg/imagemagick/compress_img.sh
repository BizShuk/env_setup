#!/bin/bash





function get_img_details {
    file="$1"
    identify $1 | tr 'x' ' ' | awk '{print $1 " " $2 " " $3 " " $4 " " $9}' 

}

resize=

while getopts "s:" opt; do
    case $opt in
        s)
           resize=$OPTARG
            ;;
        \?)
            echo $opt
            exit 1
            ;;
        :)
            echo Need specific size
            exit 1
            ;;
    esac
done


if [ "$resize" == "" ]; then
    echo "Need size with -s" >&2
    exit 1
fi


# echo $OPTIND 
shift $(expr $OPTIND - 1)


# check size should be a number

for file in $@
do
    image_details=(`get_img_details $file`)
    name=${image_details[0]%.*}
    extension=${image_details[0]#*.}
    type=${image_details[1]}
    width=${image_details[2]}
    height=${image_details[3]}
    size=${image_details[4]}

    maxedge=
    if [ "$width" -gt "$height" ]; then 
        maxedge=$width
    else
        maxedge=$height
    fi


    if [ "$maxedge" -lt "$resize" ]; then 
        continue
    fi

    percentage=$(( $resize*10000 / $maxedge ))

    convert ${image_details[0]} -resize $(($percentage/100))% ${image_details[0]}




done
