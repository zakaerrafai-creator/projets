/**
 * Utilitaire de codification SNOMED CT et LOINC pour l'export FHIR
 * ECUE 422 – Interoperabilite / Standards de sante
 */

const SNOMED_LOOKUP = [
  { keywords: ["diabete", "diabetes"], code: "73211009", display: "Diabetes mellitus (disorder)" },
  { keywords: ["hypertension", "hypertensif", "tension", "pression arterielle"], code: "38341003", display: "Hypertensive disorder (disorder)" },
  { keywords: ["asthme", "asthma", "bronchospasme"], code: "195967001", display: "Asthma (disorder)" },
  { keywords: ["covid", "coronavirus", "sars-cov"], code: "840539006", display: "COVID-19 (disorder)" },
  { keywords: ["grippe", "influenza", "flu"], code: "6142004", display: "Influenza caused by Influenza virus (disorder)" },
  { keywords: ["fracture"], code: "125605004", display: "Fracture of bone (disorder)" },
  { keywords: ["infection", "infectieux", "bacterien", "viral"], code: "40733004", display: "Infectious disease (disorder)" },
  { keywords: ["douleur", "douloureux", "algique"], code: "22253000", display: "Pain (finding)" },
  { keywords: ["insuffisance cardiaque", "cardio"], code: "84114007", display: "Heart failure (disorder)" },
  { keywords: ["depression", "anxiete", "anxieux"], code: "35489007", display: "Depressive disorder (disorder)" }
];

/**
 * Retourne un objet coding SNOMED CT a partir d'un texte de diagnostic
 * @param {string} diagnosis
 * @returns {{ system: string, code: string, display: string }}
 */
function getSnomedCoding(diagnosis) {
  const lower = (diagnosis || "").toLowerCase();
  for (const entry of SNOMED_LOOKUP) {
    if (entry.keywords.some((kw) => lower.includes(kw))) {
      return {
        system: "http://snomed.info/sct",
        code: entry.code,
        display: entry.display
      };
    }
  }
  // Code generique : Clinical finding
  return {
    system: "http://snomed.info/sct",
    code: "404684003",
    display: "Clinical finding (finding)"
  };
}

/**
 * Constantes LOINC pour les signes vitaux courants (UCUM)
 */
const LOINC_VITAL_SIGNS = [
  {
    loincCode: "8480-6",
    loincDisplay: "Systolic blood pressure",
    value: 120,
    unit: "mmHg",
    ucumCode: "mm[Hg]"
  },
  {
    loincCode: "8462-4",
    loincDisplay: "Diastolic blood pressure",
    value: 80,
    unit: "mmHg",
    ucumCode: "mm[Hg]"
  },
  {
    loincCode: "8867-4",
    loincDisplay: "Heart rate",
    value: 72,
    unit: "/min",
    ucumCode: "/min"
  }
];

/**
 * Construit une ressource FHIR Observation (signe vital) avec code LOINC
 * @param {string} patientId
 * @param {{ loincCode, loincDisplay, value, unit, ucumCode }} vitalSign
 * @param {string} idSuffix
 */
function buildVitalObservation(patientId, vitalSign, idSuffix) {
  return {
    resourceType: "Observation",
    id: `obs-${idSuffix}`,
    status: "final",
    category: [
      {
        coding: [
          {
            system: "http://terminology.hl7.org/CodeSystem/observation-category",
            code: "vital-signs",
            display: "Vital Signs"
          }
        ]
      }
    ],
    code: {
      coding: [
        {
          system: "http://loinc.org",
          code: vitalSign.loincCode,
          display: vitalSign.loincDisplay
        }
      ],
      text: vitalSign.loincDisplay
    },
    subject: { reference: `Patient/${patientId}` },
    valueQuantity: {
      value: vitalSign.value,
      unit: vitalSign.unit,
      system: "http://unitsofmeasure.org",
      code: vitalSign.ucumCode
    }
  };
}

module.exports = {
  getSnomedCoding,
  LOINC_VITAL_SIGNS,
  buildVitalObservation
};
