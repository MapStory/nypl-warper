# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# A default admin user. For some reason seed isn't assigning an ID?
user = User.create(login: "warper", email: "warper@localhost", description: "Dev admin account")  
#puts user.save
#puts user.valid?
#puts user.inspect
#puts user.errors.messages
Permission.create(role: Role.find_by_name('super user'), user: user)
Permission.create(role: Role.find_by_name('administrator'), user: user)
