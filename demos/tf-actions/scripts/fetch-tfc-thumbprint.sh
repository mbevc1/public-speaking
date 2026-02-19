openssl s_client -connect app.terraform.io:443 -showcerts </dev/null 2>/dev/null \
| awk '/BEGIN CERTIFICATE/{i++} i==2{print}' \
| openssl x509 -noout -fingerprint -sha1 \
| sed 's/://g' \
| sed 's/SHA1 Fingerprint=//' \
| tr 'A-F' 'a-f'
