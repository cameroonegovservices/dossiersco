require 'sinatra'
require 'json'
require 'sinatra/activerecord'
require 'action_mailer'

require './config/initializers/mailjet.rb'
require './config/initializers/actionmailer.rb'
require './config/initializers/carrierwave.rb'

require './helpers/models.rb'
require './uploaders/fichier_uploader.rb'
require './helpers/s3.rb'

configure :staging, :production do
  require 'rack/ssl-enforcer'
  use Rack::SslEnforcer
end

set :database_file, "config/database.yml"

set :session_secret, ENV['SESSION_SECRET']
use Rack::Session::Cookie, :key => 'dossiersco', :path => '/', :secret => ENV['SESSION_SECRET'], :expire_after => 604800

require_relative 'helpers/formulaire'
require_relative 'helpers/init'
require_relative 'helpers/mot_de_passe'

identite_resp_legal = ["lien_de_parente", "prenom", "nom", "adresse", "code_postal", "ville", "tel_principal",
											 "tel_secondaire", "email", "profession", "enfants_a_charge",
                       "communique_info_parents_eleves", "lien_avec_eleve"]


configure :test, :development, :staging do
  get '/init' do
    init
    redirect '/'
  end
end

before '/unepagequileveuneexception' do
  raise ArgumentError
end

before '/*' do
  agent_before = agent
  eleve_before = eleve
  identification = request.path_info == "/identification"
  home = request.path_info == "/"
  piece_jointe = request.path_info.start_with?("/piece")
  agent = request.path_info.start_with?("/agent")
  api = request.path_info.start_with?("/api")
  init = request.path_info.start_with?("/init")
  stats = request.path_info.start_with?("/stats")
  pass if home || identification || piece_jointe || agent || api || init || stats
  pass if eleve_before.present?
  pass if agent_before.present?
  return if home
  session[:message_erreur] = "Vous avez été déconnecté par mesure de sécurité. Merci de vous identifier avant de continuer."
  redirect '/'
end


get '/deconnexion' do
  session.clear
  redirect '/'
end


post '/famille' do
  dossier_eleve = eleve.dossier_eleve
	resp_legal1 = dossier_eleve.resp_legal_1
	resp_legal2 = dossier_eleve.resp_legal_2
	contact_urgence = ContactUrgence.find_by(dossier_eleve_id: dossier_eleve.id) || ContactUrgence.new(dossier_eleve_id: dossier_eleve.id)

	identite_resp_legal.each do |i|
		resp_legal1[i] = params["#{i}_rl1"] if params.has_key?("#{i}_rl1")
		resp_legal2[i] = params["#{i}_rl2"] if resp_legal2 && params.has_key?("#{i}_rl2")
		contact_urgence[i] = params["#{i}_urg"] if params.has_key?("#{i}_urg")
	end

	resp_legal1.save!
	resp_legal2.save! if resp_legal2
	contact_urgence.save!
	sauve_et_redirect dossier_eleve, 'administration'
end

get '/administration' do
  eleve.dossier_eleve.update derniere_etape: 'administration'
	erb :'administration', locals: {dossier_eleve: eleve.dossier_eleve}
end

post '/administration' do
	dossier_eleve = eleve.dossier_eleve
	dossier_eleve.demi_pensionnaire = params['demi_pensionnaire']
	dossier_eleve.autorise_sortie = params['autorise_sortie']
	dossier_eleve.renseignements_medicaux = params['renseignements_medicaux']
  dossier_eleve.check_paiement_cantine = params['check_paiement_cantine']
	dossier_eleve.save!
	sauve_et_redirect dossier_eleve, 'pieces_a_joindre'
end

get '/piece/:dossier_eleve/:code_piece/:s3_key' do
  dossier_eleve = get_dossier_eleve params[:dossier_eleve]

  # Vérifier les droits d'accès
  famille_autorisé = params[:dossier_eleve] == session[:identifiant]

  agent = Agent.find_by(identifiant: session[:identifiant])
  agent_autorisé = agent.present? and (dossier_eleve.etablissement == agent.etablissement)

  usager_autorisé = famille_autorisé || agent_autorisé

  objet_demandé = params[:s3_key]
  objet_présent = PieceJointe.find_by(dossier_eleve_id: dossier_eleve.id, clef: params[:s3_key])
  clef_objet_présent = objet_présent.clef if objet_présent.present?
  objet_conforme = objet_demandé == clef_objet_présent

  if usager_autorisé and objet_conforme
    extension = objet_présent.ext
    fichier = get_fichier_s3(objet_demandé)
    if extension == 'pdf'
      content_type 'application/pdf'
    elsif extension == 'jpg' or extension == 'jpeg'
      content_type 'image/jpeg'
    elsif extension == 'png'
      content_type 'image/png'
    end
    open fichier.url(Time.now.to_i + 30)
  else
    redirect '/'
  end
end

get '/pieces_a_joindre' do
  eleve.dossier_eleve.update derniere_etape: 'pieces_a_joindre'
	erb :'pieces_a_joindre', locals: {dossier_eleve: eleve.dossier_eleve}
end

post '/pieces_a_joindre' do
  dossier_eleve = eleve.dossier_eleve
  pieces_attendues = dossier_eleve.etablissement.piece_attendue
  pieces_obligatoires = false
  pieces_attendues.each do |piece|
  piece_jointe = piece.piece_jointe
    if !piece_jointe.present? && piece.obligatoire
      pieces_obligatoires = true
    end
  end
  if pieces_obligatoires
    erb :'pieces_a_joindre', locals: {dossier_eleve: dossier_eleve, message: 'Veuillez télécharger les pièces obligatoires'}
  else
    sauve_et_redirect dossier_eleve, 'validation'
  end
end

post '/enregistre_piece_jointe' do
  dossier_eleve = eleve.dossier_eleve
  upload_pieces_jointes dossier_eleve, params
  redirect '/pieces_a_joindre'
end

post '/pieces_a_joindre' do
  redirect '/validation'
end

get '/validation' do
	erb :'validation', locals: { eleve: eleve, dossier_eleve: eleve.dossier_eleve }
end

post '/validation' do
  dossier_eleve = eleve.dossier_eleve
  dossier_eleve.signature = params[:signature]
  dossier_eleve.date_signature = Time.now
  dossier_eleve.save
  if dossier_eleve.etat != 'validé'
    mail = AgentMailer.envoyer_mail_confirmation(dossier_eleve.eleve)
    mail.deliver_now
    dossier_eleve.update(etat: 'en attente de validation')
  end
  sauve_et_redirect dossier_eleve, 'confirmation'
end

get '/confirmation' do
  dossier_eleve = eleve.dossier_eleve
  dossier_eleve.update derniere_etape: 'confirmation'
	erb :'confirmation', locals: { eleve: eleve, dossier_eleve: dossier_eleve }
end

post '/satisfaction' do
  dossier_eleve = eleve.dossier_eleve
  dossier_eleve.satisfaction = params[:note]
  dossier_eleve.save!
end

post '/commentaire' do
  dossier_eleve = eleve.dossier_eleve
  dossier_eleve.commentaire = params[:commentaire]
  dossier_eleve.save!
  redirect '/confirmation'
end

get '/stats' do
  etablissements = Etablissement.all.sort_by {|e| e.dossier_eleve.count}.reverse
  erb :stats, locals: {etablissements: etablissements}
end

get '/api/recevoir_sms' do
  puts params.merge(request.content_type == 'application/json' ? JSON.parse(request.body.read) : {})
  status 204
end

post '/api/recevoir_sms' do
  puts params.merge(request.content_type == 'application/json' ? JSON.parse(request.body.read) : {})
  status 204
end

not_found do
  erb :not_found
end

error do
  erb :error
end

def sauve_et_redirect dossier_eleve, etape_la_plus_avancee
  dossier_eleve.etape_la_plus_avancee = etape_la_plus_avancee
  dossier_eleve.save!
  redirect "/#{etape_la_plus_avancee}"
end

