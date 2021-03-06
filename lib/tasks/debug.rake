namespace :debug do

	desc "Create a signed cookie, for testing - Interactive"
	task :make_cookie => :environment do
		puts "Provide a MapStory username that will be signed"
		puts "case sensitive"
		name = STDIN.gets.strip

		hash_check = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.secrets.mapstory_cookie_key, name)

		puts "#{name}:#{hash_check}"
		puts "Copyable code:"
		puts "cookies[:msid] = \"#{name}:#{hash_check}\""
	end

end