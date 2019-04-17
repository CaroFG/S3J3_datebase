require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'json'
require 'pp'

class Scrapper
# On scrap les noms des villes et les liens de leurs pages sur la liste,
# et on les ajoute dans un hash. Le regex permet de remplacer les liens relatifs
# par des liens absolus.
	def hash_cities_urls
		# On va chercher la page voulue
		page = Nokogiri::HTML(open("http://annuaire-des-mairies.com/val-d-oise.html"))
		# On crée un nouveau hash vide pour stocker les villes et leurs urls
		@cities_url = Hash.new
		
		page.xpath('//td[@width="206"]/p/a').each do |city|
			@cities_url[city.text] = city['href'].gsub(/^[.]/, 'http://annuaire-des-mairies.com')
			puts "#{city.text} and its URL added!"
		end
	end

	# Méthode pour regrouper les mails et les noms des villes dans de nouveaux hashes, qu'on met
	# dans l'array principal
	def hash_cities_mails

		@global_array_cities_mails = []
		# Méthode pour récupérer l'adresse e-mail en foncton de l'url de la mairie de la ville
		def get_mail(url)
			# On va chercher la page voulue
			page = Nokogiri::HTML(open(url))
			# On cible le prochain td sibling de celui avec le contenu "Adresse Email", et on
			# récupère son contenu pour obtenir l'adresse e-mail.
			page.xpath('//td[text()="Adresse Email"]/following-sibling::td').each do |mail|
				return mail.text
			end
		end

	# On crée l'array qui va stocker les hashes avec nom des villes et emails
	@global_array_cities_mails = []

		# Pour chaque ville de l'array, on crée un nouveau hash,
		# On ajoute la ville en clé de ce hash, et son email
		# comme valeur. Puis on ajoute le hash dans l'array principal.
		@cities_url.each do |city, url|
			hash_ville_mail = Hash.new
			hash_ville_mail[city] = get_mail(url)
			@global_array_cities_mails << hash_ville_mail
		end
	end

	def save_as_json
		File.open("db/emails.json","w") do |f|
			f.write(JSON.pretty_generate(@global_array_cities_mails))
		end
	end

	# On execute le tout via une methode perform
	def perform
		hash_cities_urls
		puts "--------------------------------"
		puts "Fetching e-mails, please wait..."
		puts "--------------------------------"
		hash_cities_mails
		puts @global_array_cities_mails

		# Il parait que c'est pas super d'utiliser des variables globales partout,
		# donc on en met juste une pour le test avec rspec, qui se situe
		# en dehors des methodes
		$test_global_array_cities_mails = @global_array_cities_mails
		save_as_json
	end

end


