#!/usr/bin/env python

contacts_config_path = '/ROOT/www/mntos-1.0/contacts.ini' # /ROOT/www/mntos-1.0/contacts.ini
networks_config_path = '/ROOT/www/mntos-1.0/networks.ini' # /ROOT/www/mntos-1.0/networks.ini

from textwrap import wrap
import sys
import getpass
import re
import getopt

int_tuple = re.compile('[1-9]\d*(,[1-9]\d*)*')
trim = re.compile(r'\s+')

def usage():
	"""Print proper syntax for calling this script."""
	print "Usage: configure.py [OPTIONS]"
	print "Configure the MNTOS dashboard settings"
	print ""
	print "Optional arguments:"
	print "\t-h, --help       \tprint this help text"
	print "\t-r, --reconfigure\tedit an existing configuration (not yet implemented)"
	print ""
	print "Report bugs in this script to <tyarusso@nagios.com>"
	return True

def set_options(argv):
	"""Get options passed on the command line and either respond to or store them."""
	reconfigure = False
	try:
		opts, args = getopt.getopt(argv, "hr", ["help", "reconfigure"])
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	for opt, arg in opts:
		if opt in ("-h", "--help"):
			usage()
			sys.exit()
		elif opt in ("-r", "--reconfigure"):
			reconfigure = True
			print "This feature is not yet implemented, sorry."
			sys.exit()
	return (reconfigure, )
	
def query_yes_no(question, default="yes"):
	"""Ask a yes or no question via raw_input() and return their answer.
	
	"question" is a string that is presented to the user.
	"default" is the presumed answer if the user just hits <Enter>.
		It must be "yes" (the default), "no", or None (meaning an answer is required of the user).
	
	The "answer" return value is one of "yes" or "no".
	"""

	valid = {"yes":"yes",	"y":"yes",	"ye":"yes",
		 "no":"no",	"n":"no"}
	if default == None:
		prompt = " [y/n] "
	elif default == "yes":
		prompt = " [Y/n] "
	elif default == "no":
		prompt = " [y/N] "
	else:
		raise ValueError("invalid default answer: '%s'" % default)
	
	while True:
		sys.stdout.write(question + prompt)
		choice = raw_input().lower()
		if default is not None and choice =='':
			return default
		elif choice in valid.keys():
			return valid[choice]
		else:
			sys.stdout.write("Please respond with 'yes' or 'no'.\n")

def query_num_list(question, hint):
	"""Ask the user to specify a list of integers via raw_input() and return their answer after validating.
	
	"question" is a string that is presented to the user"
	
	The "answer return value must be something like "1", "1,3,4", "5,9", etc.
	"""
	
	print question + "  (" + hint + ")"
	validated = False

	while not (validated):
		contact_ids = raw_input("Contact IDs: ")
		if (int_tuple.match(contact_ids)):
			validated = True
		else:
			print "Your input does not seem to be in the proper format.  \
				It should be integers, separated by commas."

	return trim.sub('', contact_ids)

def add_contact(contacts, contactnum):
	"""Ask the user to input contact information and store this in a list of dictionaries, to be written to a file later."""
	print ""
	print "Defining contact #" + str(contactnum)
	contact_name = raw_input("Name: ")
	contact_address = raw_input("Address: ")
	contact_city = raw_input("City, State: ")
	contact_zip = raw_input("Postal/ZIP Code: ")
	contact_country = raw_input("Country: ")
	contact_email = raw_input("E-Mail Address: ")
	contact_wphone = raw_input("Work Phone: ")
	contact_pphone = raw_input("Private Phone: ")
	contact_profession = raw_input("Profession: ")

	confirm_input = query_yes_no("Confirm: Are all of those answers correct?", "yes")
	if confirm_input == "yes":
		contacts.append( { "id": str(contactnum), "name": contact_name, "address": contact_address, \
			"zipcode": contact_zip, "city": contact_city, "country": contact_country, \
			"email": contact_email, "workphone": contact_wphone, \
			"privatephone": contact_pphone, "profession": contact_profession } )
	return contacts, confirm_input

def add_network(networks, networknum, contacts):
	"""Ask the user to input network information and store this in a list of dictionaries, to be written to a file later."""
	print ""
	print "Defining network #" + str(networknum)
	location = raw_input("Network Location: ")
	network = raw_input("Network Name: ")
	fqdn = raw_input("FQDN of Nagios server: ")
	username = raw_input("Nagios Username: ")
	password = getpass.getpass("Nagios Password: ")

	print "\nEntered Contacts:"
	print "ID:\tName (Profession)"
	for person in contacts:
		print str(person["id"]) + ":\t" + person["name"] + " (" + person["profession"] + ")"
	print ""
	network_contacts = query_num_list("Which contacts would you like associated with this network?", \
		"Enter as comma-separated list of the ID numbers")
	confirm_input = query_yes_no("Confirm: Are all of those answers correct?", "yes")
	if confirm_input == "yes":
		networks.append( { "id": str(networknum), "location": location, "network": network, "fqdn": fqdn, \
		"username": username, "password": password, "contacts": network_contacts } )
	return networks, confirm_input

def writefiles(contacts, networks, contacts_config_path, networks_config_path):
	"""Take the information given earlier for contacts and networks, and write this out to their respective .ini files."""
	contactlines = []
	contactlines.append("\
;\n\
; Contacts Information\n\
; Define your contacts here\n\
; note: remember to increment the id by 1.\n")
	for person in contacts:
		contactlines.append("\n")
		contactlines.append("[WizardContact" + '%04d' % int(person["id"]) + "]\n")
		contactlines.append("id=" + person["id"] + "\n")
		contactlines.append("name=\"" + person["name"] + "\"\n")
		contactlines.append("address=\"" + person["address"] + "\"\n")
		contactlines.append("zipcode=\"" + person["zipcode"] + "\"\n")
		contactlines.append("city=\"" + person["city"] + "\"\n")
		contactlines.append("country=\"" + person["country"] + "\"\n")
		contactlines.append("email=\"" + person["email"] + "\"\n")
		contactlines.append("workphone=\"" + person["workphone"] + "\"\n")
		contactlines.append("privatephone=\"" + person["privatephone"] + "\"\n")
		contactlines.append("profession=\"" + person["profession"] + "\"\n")
	contactsini = open(contacts_config_path, 'w')
	contactsini.writelines(contactlines)
	contactsini.close()

	networklines = []
	networklines.append("\
; MNTOS Network Configuration File\n\
; remember to increment id value by one.\n")
	for network in networks:
		networklines.append("\n")
		networklines.append("[WizardNetwork" + '%04d' % int(network["id"]) + "]\n")
		networklines.append("id=" + network["id"] + "\n")
		networklines.append("location=\"" + network["location"] + "\"\n")
		networklines.append("network=\"" + network["network"] + "\"\n")
		networklines.append("nagios=\"http://" + network["username"] + ":" + network["password"] + \
			"@" + network["fqdn"] + "/nagios/cgi-bin/tac.cgi\"\n")
		networklines.append("public=\"http://" + network["fqdn"] + "/nagios/\"\n")
		networklines.append("contacts=" + network["contacts"] + "\n")
		networklines.append("icon=\"img/globe.png\"\n")
	networksini = open(networks_config_path, 'w')
	networksini.writelines(networklines)
	networksini.close()

def blankrun(options):
	print '\n'.join(wrap("The next step is to define your contacts.  \
This information will display in the sidebar of the MNTOS web interface.  \
The fields available are:", 80))
	print "\
	Name\n\
	Address\n\
	City, State\n\
	Postal Code\n\
	Country\n\
	E-Mail Address\n\
	Work Phone\n\
	Private Phone\n\
	Profession"
	print '\n'.join(wrap("You may leave any of these fields blank.  \
None are required for MNTOS operation - this is for your own convenience, \
so the person looking at the overview knows who to contact if there is a problem.", 80))

	another = 1
	contactnum = 0
	contacts = []
	while (another):
		contactnum += 1
		contacts, input_correct = add_contact(contacts, contactnum)
		if input_correct == "no":
			another = 1
			contactnum -= 1
			print "Try again..."
		else:
			answer = query_yes_no("Would you like to add another contact?", "yes")
			if answer == "yes":
				another = 1
			elif answer == "no":
				another = 0
				
	print '\n'.join(wrap("The next step is to define your networks.  \
This is how statuses will be grouped in the MNTOS interface.  \
Each network consists of one Nagios monitoring server.", 80))
	print ""

	another = 1
	networknum = 0
	networks =[]
	while (another):
		networknum += 1
		networks, input_correct = add_network(networks, networknum, contacts)
		if input_correct == "no":
			anoter = 1
			networknum -= 1
			print "Try again..."
		else:
			answer = query_yes_no("Would you like to add another network", "yes")
			if answer == "yes":
				another = 1
			elif answer == "no":
				another = 0

	writefiles(contacts, networks, contacts_config_path, networks_config_path)

	return True

blankrun(set_options(sys.argv[1:]))
