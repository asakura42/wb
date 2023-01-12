#!/bin/sh
mv out.json out.bak
mv detail.json detail.bak

i=1

baseurl="$(printf "%s&%s\n" "$(curl -L "https://www.wildberries.ru/webapi/menu/main-menu-ru-ru.json" | sed 's/{/\n{/g;s/}/}\n/g' | grep "$(echo "$1" | sed 's/\?.*//;s/^.*wildberries.ru//;s/$/"/')" | jq -r '"https://catalog.wb.ru/catalog/\(.shard)/catalog?\(.query)"')" "$(echo "$1"  | sed 's/^.*?//' | python3 -c "import sys; from urllib.parse import unquote; print(unquote(sys.stdin.read()));" | sed '/^$/d;s/^/\&/')" | sed 's|&page=[[:digit:]]\+||' )"

while true ; do
	page=$(curl -L "${baseurl}&page=$i")
	if echo "$page" | grep '"products":\[\]' ; then
		break
	else
		echo "$page" | jq -r '.data.products[]' >> out.json
		i=$((i+1))
	fi
done


cat << EOF > index.html
<!doctype html>
<html lang="en-US">
<head>
  <meta charset="utf-8"/>
      <style>
        * {
            margin: 0;
            padding: 0;
        }
        .imgbox {
            display: grid;
            height: 100%;
        }
        .center-fit {
            max-width: 100%;
            max-height: 100vh;
            margin: auto;
        }
    </style>
</head>
<body>
<div class="imgbox">
EOF

cat out.json | jq -r 'select(.rating == 5 or .rating == 5) | select(.feedbacks > 30) | .id' | while IFS= read -r line ; do
if [ $(printf $line | wc -c ) = 7 ] ; then
	vol="${line:0:2}"
	part="${line:0:4}"
elif [ $(printf $line | wc -c ) =  8 ] ; then
	vol="${line:0:3}"
	part="${line:0:5}"
elif [ $(printf $line | wc -c ) =  9 ] ; then
	vol="${line:0:4}"
	part="${line:0:6}"
fi


if [ $(printf $line | cut -c1) = 1 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'

	elif [ $(printf $line | wc -c ) =  8 ] ; then
		if [ "$line" -gt 14399999 ] ; then
			domen='basket-02'
		else
			domen='basket-01'
		fi


	elif [ $(printf $line | wc -c ) =  9 ] ; then
		if [ "$line" -gt 111599999 ] ; then
			if [ "$line" -gt 116999999 ] ; then
				domen='basket-09'
			else
				domen='basket-08'
			fi
		else
			domen='basket-07'
		fi
	fi

elif [ $(printf $line | cut -c1) = 2 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	elif [ $(printf $line | wc -c ) =  8 ] ; then
		if [ "$line" -gt 28799999 ] ; then
			domen='basket-03'
		else
			domen='basket-02'
		fi
	else
		domen='basket-02'
	fi

elif [ $(printf $line | cut -c1) = 3 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	else
		domen='basket-03'
	fi

elif [ $(printf $line | cut -c1) = 4 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	elif [ $(printf $line | wc -c ) =  8 ] ; then
		if [ "$line" -gt 43199999 ] ; then
			domen='basket-04'
		else
			domen='basket-03'
		fi
	fi

elif [ $(printf $line | cut -c1) = 5 ] ; then
	domen='basket-04'

elif [ $(printf $line | cut -c1) = 6 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	else
		domen='basket-04'
	fi

elif [ $(printf $line | cut -c1) = 7 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	else
		if [ "$line" -gt 71999999 ] ; then
			domen='basket-05'
		else
			domen='basket-04'
		fi
	fi

elif [ $(printf $line | cut -c1) = 8 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	elif [ $(printf $line | wc -c ) =  8 ] ; then
		domen='basket-05'
	fi
elif [ $(printf $line | cut -c1) = 9 ] ; then
	if [ $(printf $line | wc -c ) =  7 ] ; then
		domen='basket-01'
	else
		domen='basket-05'
	fi

else
	domen='basket-01'
fi

curl -L "https://${domen}.wb.ru/vol${vol}/part${part}/${line}/images/big/1.jpg" -o $line
curl -L "https://${domen}.wb.ru/vol${vol}/part${part}/${line}/info/ru/card.json" | jq >> detail.json

img=$(base64 -w0 $line)

echo "<a href=\"https://www.wildberries.ru/catalog/$line/detail.aspx\"><img src=\"data:image/jpeg;base64, $img\" class=\"center-fit\"></a>" >> index.html

done

cat << EOF >> index.html
</div>
</body>
</html>
EOF
