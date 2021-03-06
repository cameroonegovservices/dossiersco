# DossierSCO

Inscrire ses enfants au collège sans se déplacer, sans redonner d'informations déjà connues et sans flux papier.

[dossiersco.fr](https://dossiersco.fr/)

## Vie de l'équipe

- Vous pouvez nous retrouver chaque lundi et jeudi au [110bis Lab](http://www.education.gouv.fr/110bislab/pid37871/bienvenue-au-110-bis-le-lab-d-innovation-de-l-education-nationale.html) rue de Grenelle à Paris
- Retrouvez notre [agenda public](https://calendar.google.com/calendar/embed?src=contact%40dossiersco.beta.gouv.fr&ctz=Europe%2FParis)
- [Journal de l'équipe](https://gitlab.com/dossiersco/dossiersco/blob/master/doc/journal.md)
- Le [blog de l'équipe](https://blog.dossiersco.fr/)

Nous avons quelques rituels, des rendez-vous régulier :
- points quotidiens à 14h, en fonction des personnes présentes
- planification en début de semaine vers 14h30
- prise de recul sur le travail effectué le jeudi en fin d’aprèm (démo, rétro, journal)

## Documentation

- [L'histoire des décisions d'architecture](https://gitlab.com/dossiersco/dossiersco/tree/master/doc/architecture)
- le [suivi des travaux sur le projet](https://gitlab.com/dossiersco/dossiersco/boards)

## Développement

Le code source est disponible sur [gitlab.com/dossiersco](https://gitlab.com/dossiersco).

Pour faciliter la mise en place d'environnement, nous nous basons sur [docker](https://www.docker.com/). Les commandes principales sont placées dans un [`Makefile`](https://www.gnu.org/software/make/manual/make.html). Il est possible que certaines commandes particulières nécessitent malgré tout d'explorer les commandes ̀ docker` et plus particulièrement `docker-compose`.

Pour cloner le repository :
```bash
git clone https://gitlab.com/dossiersco/dossiersco.git
```

Pour constuire le projet (installer les gems entre autres) :
```bash
make build
```

Pour démarrer les serveurs (base de données et application) :
```bash
make run
```
L'accès à l'application se fait ensuite par <http://0.0.0.0:9393/>.

Pour lancer les tests :
```bash
make test
```

Pour lancer un test en particulier :
```bash
docker-composer run --rm test rails test <mon fichier ex: test/models/agent_test.rb>
```

Pour accéder à la console rails :
```bash
make console
```

## Outils

- Tous les identifiants et mots de passe sont stockés dans [Keybase](https://keybase.io/)
- Les mails transactionnels sont envoyés via [Mailjet](https://mailjet.com)
- On attrape toutes les erreurs sur [Sentry](https://sentry.io/betagouv-pe/rails/)
- Sur les environnements de développement et staging les emails sortants sont envoyés
    avec [Letter Opener Web](https://github.com/ryanb/letter_opener). On peut les consulter à l'url `/letter_opener`
- Envoie de SMS avec [NEXMO](https://www.nexmo.com/)
- Nous analysons les connexions avec [Matomo](https://matomo.org/). Pour accéder à l'interface du projet [dossierSco sur le compte de beta.gouv.fr](https://stats.data.gouv.fr/index.php?module=CoreHome&action=index&idSite=54&period=range&date=previous30&updated=1#?idSite=54&period=range&date=previous30&category=Dashboard_Dashboard&subcategory=1). Voir [beta.bouv.fr/suivi/](https://beta.gouv.fr/suivi/)
- Support utilisateurs en direct à l'aide de [Drift](https://app.drift.com/)
