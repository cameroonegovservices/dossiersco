# frozen_string_literal: true

class ExportElevesXlsxJob < ActiveJob::Base

  def perform(agent)
    lignes = faire_lignes(agent)
    entete = cellules_entete(agent)

    creer_fichier(lignes, entete, agent)

    mailer = AgentMailer.export_eleves_xlsx(agent, File.read("tmp/eleves-#{agent.etablissement.id}.xlsx"))
    mailer.deliver_now
    FileUtils.rm_rf("tmp/eleves-#{agent.etablissement.id}.xlsx")
  end

  def faire_lignes(agent)
    lignes = []
    DossierEleve.where(etablissement: agent.etablissement).each do |dossier|
      options_eleve = cellules_options_eleve(dossier)
      ligne = cellules_infos_base(dossier).concat(options_eleve)
      ligne.concat(cellules_regime_sortie(dossier)) if agent.etablissement.regimes_sortie.count > 1
      lignes << ligne
    end
    lignes
  end

  def cellules_entete(agent)
    options_etablissement = agent.etablissement.options_pedagogiques
    entete_options = options_etablissement.map(&:nom)
    entete = ["classe actuelle", "MEF actuel", "prenom", "nom", "date naissance", "sexe"].concat(entete_options)

    entete.concat(agent.etablissement.regimes_sortie.map(&:nom)) if agent.etablissement.regimes_sortie.count > 1
    entete
  end

  def cellules_infos_base(dossier)
    mef_origin = dossier.mef_origine.present? ? dossier.mef_origine.libelle : ""
    [dossier.eleve.classe_ant, mef_origin, dossier.eleve.prenom, dossier.eleve.nom,
     dossier.eleve.date_naiss, dossier.eleve.sexe]
  end

  def cellules_options_eleve(dossier)
    options_eleve = []
    dossier.etablissement.options_pedagogiques.each do |option|
      options_eleve << (dossier.options_pedagogiques.include?(option) ? "X" : "")
    end
    options_eleve
  end

  def cellules_regime_sortie(dossier)
    regime_sortie = []
    dossier.etablissement.regimes_sortie.each do |regime|
      regime_sortie << (dossier.regime_sortie == regime ? "X" : "")
    end
    regime_sortie
  end

  def creer_fichier(lignes, entete, agent)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "Export-eleves") do |sheet|
        sheet.add_row entete
        lignes.each { |ligne| sheet.add_row ligne }
      end
      p.serialize("tmp/eleves-#{agent.etablissement.id}.xlsx")
    end
  end

end
