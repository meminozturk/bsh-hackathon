extract_group <- function(fpy){
  fpy[,Group1:=gsub(".*-","",Nav_QM.Group_text)]
  fpy[,asd:=as.character(gsub("(.*)-.*", "\\1", Nav_QM.Group_text))]
  fpy[,asd:=gsub(' +',' ',asd)]
  library(stringr)
  fpy[,Group2:=strsplit(as.character(fpy$asd),split=" ")[[2]][4]]
  fpy[,asd:=NULL]
  return(fpy)
}
