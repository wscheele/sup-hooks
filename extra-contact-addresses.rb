#
# Return a list of email addresses from somewhere

contacts=[]

`lbdbq . |awk -F"\t" '{print $2 , "<"$1">"}'`.each { |c|
  contacts.push(c)
}
contacts
