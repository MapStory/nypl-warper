namespace :set do

  # Run with rake set:super_user["dlee"]
  desc "Grants user super_user and administrator rights"
  task :super_user, [:login]  => :environment do |t,args|

    user = User.find_by_login(args.login)

    Permission.create(role: Role.find_by_name('super user'), user: user)
    Permission.create(role: Role.find_by_name('administrator'), user: user)

  end

end
