# frozen_string_literal: true

class AgentMailer < ApplicationMailer

  default from: "equipe@dossiersco.fr",
          reply_to: "equipe@dossiersco.fr"

  def succes_import(email, statistiques)
    @statistiques = statistiques
    mail(subject: "Import de votre base élève dans DossierSCO", to: email, &:text)
  end

  def erreur_import(email)
    mail(subject: "L'import de votre base élève a échoué", to: email, &:text)
  end

  def invite_premier_agent(agent)
    @agent = agent
    mail(subject: "Activez votre compte DossierSCO", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

  def invite_agent(agent_invite, admin)
    @agent_invite = agent_invite
    @admin = admin
    mail(subject: "Activez votre compte agent sur DossierSCO", to: @agent_invite.email) do |format|
      format.html
      format.text
    end
  end

  def convocation(agent, zip)
    @agent = agent
    attachments["convocations.zip"] = { mime_type: "application/zip", content: zip }

    mail(subject: "Convocations pour l'inscription sur DossierSCO", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

  def fiche_infirmerie(agent, zip)
    @agent = agent
    attachments["fiches-infirmerie.zip"] = { mime_type: "application/zip", content: zip }

    mail(subject: "Fiches infirmerie DossierSCO", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

  def export_eleves_xlsx(agent, lignes)
    @agent = agent
    attachments["eleves.xlsx"] = { mime_type: "application/vnd.ms-excel", content: lignes }

    mail(subject: "Elèves par option", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

end
