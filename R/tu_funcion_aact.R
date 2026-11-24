#' Resumen de ensayos clinicos por fase en AACT (ClinicalTrials.gov)
#'
#' Conecta de forma remota al servidor PostgreSQL de AACT usando las
#' credenciales almacenadas en .Renviron, filtra los ensayos por patologia
#' y devuelve el numero de estudios y el reclutamiento medio por fase.
#'
#' @param patologia Texto de busqueda de la enfermedad (ej. "Melanoma").
#'
#' @return Un data.frame con el número de estudios según el tipo de intervención.
#' @export
#'
#' @examples
#' \dontrun{
#' tu_funcion_aact("Melanoma")
#' }
tu_funcion_aact <- function(patologia = "Melanoma") {
  usuario <- Sys.getenv("AACT_USER")
  clave <- Sys.getenv("AACT_PASSWORD")
  if (usuario == "" || clave == "") {
    stop("Configura AACT_USER y AACT_PASSWORD en tu archivo .Renviron.")
  }
  con <- DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = "aact",
    host = "aact-db.ctti-clinicaltrials.org",
    port = 5432,
    user = usuario,
    password = clave
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  consulta_sql <- "
SELECT
    i.intervention_type AS tipo_intervencion,
    COUNT(DISTINCT s.nct_id) AS num_ensayos

  FROM ctgov.studies s

  INNER JOIN ctgov.conditions c
    ON s.nct_id = c.nct_id

  INNER JOIN ctgov.interventions i
    ON s.nct_id = i.nct_id

  WHERE LOWER(c.name) LIKE LOWER($1)

  GROUP BY i.intervention_type

  ORDER BY num_ensayos DESC;
  "

  DBI::dbGetQuery(
    con,
    consulta_sql,
    params = list(paste0("%", patologia, "%"))
  )
}
