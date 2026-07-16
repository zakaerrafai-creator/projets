# TeleMed Campus - Projet Teleconsultation

Plateforme web de teleconsultation medicale construite pour couvrir les modules:
- ECUE 422 (interoprabilite, standards FHIR/HL7)
- ECUE 423 (developpement web)
- ECUE 424 (conception systemes de telemedecine)

## Fonctionnalites implementees
- Authentification (patient, medecin, admin)
- Gestion des rendez-vous
- Dossier medical simplifie
- Chat temps reel avec Socket.IO
- Export FHIR (Bundle Patient + Conditions)

## Arborescence
- server: API Express + MongoDB + Socket.IO
- client: interface HTML/CSS/JS + Bootstrap
- docs: documentation projet

## Prerequis
- Node.js 18+
- MongoDB local (ou URI distante)

## Installation
1. Ouvrir un terminal dans server
2. Installer les dependances
3. Copier .env.example en .env
4. Lancer l'API

Commandes:

```bash
cd server
npm install
copy .env.example .env
npm run dev
```

Frontend:
- Ouvrir client/index.html avec Live Server (ou un serveur statique)
- Verifier que CORS_ORIGIN dans .env correspond a l'URL du frontend

## Endpoints principaux
- POST /api/auth/register
- POST /api/auth/login
- POST /api/appointments
- GET /api/appointments/mine
- PATCH /api/appointments/:id/status
- POST /api/records
- GET /api/records/me
- GET /api/records/patient/:patientId
- GET /api/fhir/patients/:patientId/bundle

## Notes ECUE 422 (interoperabilite)
- Le endpoint FHIR retourne un Bundle conforme a une structure FHIR simplifiee
- Les diagnostics sont mappees en ressources Condition
- Le patient est mappe en ressource Patient

## Evolution conseillee
- Ajouter codification SNOMED CT / LOINC
- Ajouter visioconference WebRTC
- Ajouter audit, consentement et traçabilite RGPD
