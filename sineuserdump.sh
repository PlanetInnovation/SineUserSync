#!/bin/bash

# This script performs an ldap dump of users
# reformats it, adds groups based on email
# addresses and then finally saves the result
# as a .csv file

# Dump all active ldap users (exclude disabled accounts)
ldapsearch -h ldap.YourDomain.com -b "CN=users,DC=YourDomain,DC=com" -D "CN=SomeServiceAccount,CN=users,DC=YourDomain,DC=com" -w SecretPassword "(&(objectCategory=person)(objectClass=user)(memberOf=CN=SineUsers,OU=Groups,DC=YourDomain,DC=com)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" > /tmp/ldapsearch.txt


# select only relevant details like name, email, etc.
# use "distinguishedName" as a record seperator
# replace spaces with "§" so the for loop will have everyting on a single record
cat /tmp/ldapsearch.txt | egrep "givenName:|sn:|mail:|sAMAccountName:|telephoneNumber:|distinguishedName:" | sed 's/distinguishedName:\ CN=.*/XXxxXX/g' | sed ':a;N;$!ba;s/\n/,\ /g' | sed 's/XXxxXX/\n/g' | sed 's/^,\ //g' | sed 's/,\ $//g' | sed 's/ /§/g' > /tmp/detailsincusername.txt

# add header to new file
echo \"Email\",\"First Name\",\"Last Name\",\"Group Name\",\"Site Name\",\"Mobile\"


# start looping through all records
for CURRENTLOOPLINE in $(cat /tmp/sinedetailsonly.txt); do
	# get email
	EMAILADDR=$(echo $CURRENTLOOPLINE | egrep -o "mail:§([a-z]|[A-Z]|\-|'|@|\.)*" | cut -c 8-500)
	# get firstname and replace spaces
	FIRSTNAME=$(echo $CURRENTLOOPLINE | egrep -o "givenName:§([a-z]|[A-Z]|\-|'|§)*" | cut -c 13-500 | sed 's/§/ /g')
	# get surname and replace spaces
	SECONDNAME=$(echo $CURRENTLOOPLINE | egrep -o "sn:§([a-z]|[A-Z]|\-|'|§)*" | cut -c 6-500 | sed 's/§/ /g')
	# generate group name based on email address
	GROUPNAME=$(echo $EMAILADDR | egrep -o 'MainCompanyName.com|SubsiduaryCompanyName.com' | sed 's/MainCompanyName.com/Main Company Name/g' | sed 's/SubsiduaryCompanyName.com/Subsiduary Company Name/g')
	# set site name (all same site for now)
	SITENAME=$(echo Name of your main company site)
	# get phone number (and then replace spaces)
	PHONENUMBER=$(echo $CURRENTLOOPLINE | egrep -o "telephoneNumber:§([0-9]|§|\(|\)|\-|\+)*" | cut -c 19-500 | sed 's/§/ /g')

	# output final list in correct format for csv import
	echo \"$EMAILADDR\",\"$FIRSTNAME\",\"$SECONDNAME\",\"$GROUPNAME\",\"$SITENAME\",\"$PHONENUMBER\"

done

