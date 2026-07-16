# Architecture simplifiee

## Couches
- Presentation: client HTML/CSS/JS
- Services: API REST Express
- Donnees: MongoDB
- Temps reel: Socket.IO
- Interoperabilite: export FHIR

## Flux principal teleconsultation
1. Authentification utilisateur
2. Prise de rendez-vous
3. Echange de messages temps reel sur consultation
4. Production d'un dossier medical
5. Export des donnees en Bundle FHIR

## Justification pedagogique
- ECUE 423: mise en oeuvre frontend + backend web
- ECUE 424: scenario fonctionnel de teleconsultation
- ECUE 422: integration de standards d'echange en sante
