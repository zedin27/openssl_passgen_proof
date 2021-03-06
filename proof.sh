#!/bin/bash

# This script aims to prove that OpenSSL's password generation (at the very least for DES)
# is as follows
#
#     MD5(password||salt)
#
# as said in https://security.stackexchange.com/questions/29106/openssl-recover-key-and-iv-by-passphrase

# Modify the password if you wish
PASSWORD="password"

# Just a temporary file to reference later
SSL_OUT=openssl_command_output

# Perform the initial OpenSSL key generation and store it in the temp file
openssl des -P -pass pass:$PASSWORD > $SSL_OUT

echo -e "\nOPENSSL OUTPUT:"
cat $SSL_OUT

# Extract the separate values for SALT, KEY and IV
SSL_SALT=$( cat $SSL_OUT | grep "^salt=" | cut -c6- )
SSL_KEY=$( cat $SSL_OUT | grep "^key=" | cut -c5- )
SSL_IV=$( cat $SSL_OUT | grep "^iv =" | cut -c5- )

# Perform string manipulations to convert the OpenSSL hex output to raw ASCII
HEX_SALT=$( echo $SSL_SALT | sed -E 's/(..)/0x\1 /g' )
RAW_SALT=$( echo $HEX_SALT | xxd -r )

# Old debug statements
#echo -e $SSL_SALT $HEX_SALT $RAW_SALT
#echo -e ""

# Perform the hash on the password with the salt, converted to uppercase for visual diff
MD5=$( md5 -q -s "$PASSWORD$RAW_SALT" | awk '{print toupper($0)}' )

# Separate the md5 hash into the two values by putting a space every 16 bytes
MD5_SPLIT=$( echo $MD5 | sed -E 's/(.{16})/\1  /' )

echo -e "\nMD5 of $PASSWORD concatenated with the raw value of $HEX_SALT:\n$MD5"
echo -e "\nLook for yourself:"

# Set the new values by the space delimiter
NEW_KEY=$( echo $MD5_SPLIT | cut -d' ' -f1 )
NEW_IV=$( echo $MD5_SPLIT | cut -d' ' -f2 )

echo -e "SSL key: $SSL_KEY\nNEW key: $NEW_KEY\n"
echo -e "SSL iv: $SSL_IV\nNEW iv: $NEW_IV\n"
