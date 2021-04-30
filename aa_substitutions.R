#' aa_substitutions
#' Create a CSV file of AA substitutions in human sequences by date and country from a
#' GISAID metafile.
#'
#' @param meta_file - path name to GISAID metafile 
#' @param outfile - path name of output fril
#' @param host - host species. Default is human
#'
#' @return NULL
#'
aa_substitutions <- function(meta_file, outfile, host = "Human") {
  require(tidyverse)
  
  meta_table <- read.csv(meta_file, sep = "\t", header = TRUE)
  
  df <- meta_table %>% 
    filter(Host == {{ host }}) %>%
    filter(Pango.lineage != "") %>%
    filter(str_detect(Collection.date, "\\d\\d\\d\\d-\\d\\d-\\d\\d")) %>%
    select(Virus.name, Collection.date, Accession.ID, Location, Pango.lineage, AA.Substitutions) %>% 
    separate_rows(AA.Substitutions, sep = ",") %>% 
    separate(Location, c("Region", "Country", "State"), sep = "\\s*/\\s*", extra = "drop", fill = "right") %>%
    select(-c("Region", "State"))
  
  write.csv(df, outfile, row.names = FALSE)
}