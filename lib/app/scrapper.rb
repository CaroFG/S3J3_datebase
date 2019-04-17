require 'google_drive'
require 'csv'


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
		# On cŕee un nouvel hash vide 
		new_cities_mails = Hash.new
		# On parcourt notre array de hash
		@global_array_cities_mails.each do |hash|
		# Pour chaque hash de l'array on récupère la clé et la valeur
			hash.each do |city, mail|
		#On les stocke dans notre hash vide
				new_cities_mails[city] = mail
			end
		end
		# On ouvre le fichier .json  avec les droits en write
		File.open("db/emails.json","w") do |f|
			# f c'est peut-être le nom du fichier, dans ce fichier f on écrit le contenu du hash
			f.write(JSON.pretty_generate(new_cities_mails))
		end
	end

	def save_as_spreadsheet
		# Dans config.jason on a nos clés API
		session = GoogleDrive::Session.from_config("config.json")
		# ws est notre worksheet google
			ws = session.spreadsheet_by_key("1814thnpoaiBA4FiqZ-rtWEDHNVvbFL_Jhq_NNrsT1IM").worksheets[0]
			#ligne 1 colonne 1
			ws[1, 1] = "VILLES"
			#ligne 1 colonne 2
			ws[1, 2] = "E-MAILS"
			
		
			i = 0
		@global_array_cities_mails.each do |hash|   # This is an array of arrays of hashes
	     hash.each do |ville, email| # Pour chaque hash on parcourt la clé et la valeur
					 ws[i + 2, 1] = ville # On incrémente la ligne et on stocke la ville dans chaque ligne de la colonne 1
					 ws[i + 2, 2] = email # On incrémente la ligne et on stocke l'email dans chaque ligne de la colonne 2
				end
				i += 1
		end  

			ws.save
			ws.reload
	end

	def save_as_csv
		CSV.open("db/emails.csv", "w") do |csv|
			i = 1
				@global_array_cities_mails.each do |hash|   # This is an array of arrays of hashes
	     		hash.each do |ville, email| # On parcourt la clé et la valeur de chaque hash
					 	csv << [i, ville, email] # Les virgules séparent les colonnes
					 end
					 i += 1
				end
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
		#save_as_spreadsheet
		#save_as_csv
	end

end


