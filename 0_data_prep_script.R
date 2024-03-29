
library(tidyverse)
library(cansim)
library(GGally)
library(ggpubr)
library(lubridate)




#comparable Universities:

Macleans_comprehensive = c("Simon Fraser",
                           "University of Victoria",
                           "University of Waterloo",
                           "York University",
                           "Carleton",
                           "Guelph",
                           "Memorial",
                           "University of New Brunswick",
                           "Concordia University, Quebec",
                           "(Toronto Metropolitan)|(Ryerson)",
                           "Wilfrid Laurier",
                           "Université du Québec à Montréal",
                           "Brock",
                           "University of Regina",
                           "University of Windsor"
)
Macleans_medical = c("McGill",
                     "University of Toronto",
                     "University of British Columbia",
                     "McMaster University",
                     "University of Ottawa",
                     "University of Alberta",
                     "University of Calgary",
                     "Dalhousie",
                     "Queen's University",
                     "Université de Montréal",
                     "Université Laval, Quebec",
                     "Western University",
                     "University of Manitoba" ,
                     "Université de Sherbrooke",
                     "University of Saskatchewan"
)

# acquire and prep the data files:
# Pull CanSim table from StatCan or load them if they already exist:
  

cache_file_list = list.files("filecache/")

if(length(grep(cache_file_list, pattern = "37-10-0235-01", value = TRUE))==0){
  data     = get_cansim(              "37-10-0235-01") |> rename_all(make.names) 
  metadata = get_cansim_cube_metadata("37-10-0235-01") |> rename_all(make.names) 
  data     |> write_csv(paste0("filecache/","37-10-0235-01","_data.csv"))
  metadata |> write_csv(paste0("filecache/","37-10-0235-01","_metadata.csv"))
}else{
  data     = read_csv(paste0("filecache/","37-10-0235-01","_data.csv"))
  metadata = read_csv(paste0("filecache/","37-10-0235-01","_metadata.csv"))
}
location = "filecache/"
data |> dim() 
# 18.8 million rows and 36 columns  This can be filtered down by a lot.

Geo_list = data |> pull(GEO)|> unique()
mac_comp = str_detect(Geo_list, pattern = paste0("(",paste(Macleans_comprehensive,collapse=")|("),")"))
mac_doc  = str_detect(Geo_list, pattern = paste0("(",paste(Macleans_medical,collapse=")|("),")"))


# undergrads at 'major' universities (reduce to 41,412 rows and 9 columns)
undergrad_data = data |> 
  dplyr::filter(UOM == "Number")|> 
  dplyr::filter(Gender %in% c("Total, gender")) |>
  dplyr::filter(Program.type =="Undergraduate program")|>
  # dplyr::filter(Program.type %in% c(
  # "Graduate program (above the third cycle)","Graduate program (second cycle)","Graduate program (third cycle)","Undergraduate program"))|>
  dplyr::filter(Credential.type %in% c("Degree (includes applied degree)"))|>
  dplyr::filter(Institution.type == "University")|>
  dplyr::filter(Status.of.student.in.Canada == "Total, status of student in Canada")|>
  select(REF_DATE, Date,GEO,Field.of.study,VALUE)|>
  dplyr::filter(GEO %in% c("Canada",Geo_list[mac_doc],Geo_list[mac_comp])) |>
  # clunky, but extract the parent and child codes
  mutate(program.code.full = str_replace_all(Field.of.study, pattern = "(^.*\\[)|(\\])$", replacement = ""))|>
  mutate(program.code.first = str_replace_all(program.code.full, pattern = "\\..*$", replacement = ""))|>
  mutate(program.code.top = program.code.full == program.code.first) |>
  mutate(program.code.top = ifelse(program.code.top==FALSE, gsub(program.code.full, pattern = "\\.?c", replacement = "")== program.code.first, program.code.top))|>
  mutate(Field.of.study = as.character(Field.of.study))|>
  # clunky, but make a column labelling the parent Field of study
  group_by(program.code.first)|>
    mutate(Field.of.study.parent = Field.of.study[match(program.code.top,program.code.first)])|>
    mutate(Field.of.study.parent = ifelse(length(unique(Field.of.study.parent[!is.na(Field.of.study.parent)]))!=1,
           NA,
      unique(Field.of.study.parent[!is.na(Field.of.study.parent)])))|> 
    # fill in Field.of.study.parent when the parent is a number and letter
  mutate(temp.prog = ifelse(
    is.na(Field.of.study.parent),     # still NA becasue the `program.code.first' doesn't appear as a `program.code.full'. typically because of the format ##.c
    Field.of.study[match(str_replace_all(program.code.full, pattern = "\\.[[:alpha:]]", replacement = ""),program.code.first)],  
    Field.of.study.parent))|>
  mutate(Field.of.study.parent = ifelse(length(unique(temp.prog[!is.na(temp.prog)]))!=1,
                                        NA,
                                        temp.prog))|> 
  select(-c("temp.prog"))|>
  ungroup()|>
  mutate(School = str_replace(GEO,pattern = "\\sUniversity", replacement = ""),
         School = str_replace(School,pattern = ",.*", replacement = ""),
         School = paste0(substr(School, 1,4)," ",substr(School, 15,19)))
  #######relative growth since 2012.  
Baseline_2012 =  undergrad_data |>
  dplyr::filter(Date == as_date("2012-07-01"))|>
  mutate(VALUE2012 = VALUE)|>
  select(School, Field.of.study,VALUE2012)

undergrad_data = undergrad_data |> 
  inner_join(Baseline_2012)|>
  mutate(Percent_growth_since_2012 = VALUE/VALUE2012*100)

  

undergrad_data |> 
  filter(program.code.top == TRUE) |> 
  select(Field.of.study) |>
  unique() |> 
  write_csv(paste0(location,"top_program_codes.csv"))


undergrad_data |> 
  select(program.code.first, program.code.full, Field.of.study,Field.of.study.parent) |>
  unique() |>
  write_csv(paste0(location,"sub_program_codes.csv"))
  
undergrad_data |> write_csv(paste0(location,"undergrad_programs_data.csv"))
metadata       |> write_csv(paste0(location,"undergrad_programs_metadata.csv"))


doctoral_universities = Geo_list[mac_doc]
comprehensive_universities = Geo_list[mac_comp]

doctoral_universities |> write.csv(paste0(location,"doctoral_list.csv"))
comprehensive_universities |> write.csv(paste0(location,"comprehensive_list.csv"))







# ========

# grads at 'major' universities 
grad_data = data |> 
  dplyr::filter(UOM == "Number")|> 
  dplyr::filter(Gender %in% c("Total, gender")) |>
  dplyr::filter(Program.type %in% c(
      "Graduate program (above the third cycle)",
      "Graduate program (second cycle)",
      "Graduate program (third cycle)"))|>
  dplyr::filter(Credential.type %in% c("Degree (includes applied degree)"))|>
  dplyr::filter(Institution.type == "University")|>
  dplyr::filter(Status.of.student.in.Canada == "Total, status of student in Canada")|>
  select(REF_DATE, Date,GEO,Field.of.study,VALUE,Program.type)|>
  dplyr::filter(GEO %in% c("Canada",Geo_list[mac_doc],Geo_list[mac_comp])) |>
  # clunky, but extract the parent and child codes
  mutate(program.code.full = str_replace_all(Field.of.study, pattern = "(^.*\\[)|(\\])$", replacement = ""))|>
  mutate(program.code.first = str_replace_all(program.code.full, pattern = "\\..*$", replacement = ""))|>
  mutate(program.code.top = program.code.full == program.code.first) |>
  mutate(program.code.top = ifelse(program.code.top==FALSE, gsub(program.code.full, pattern = "\\.?c", replacement = "")== program.code.first, program.code.top))|>
  mutate(Field.of.study = as.character(Field.of.study))|>
  # clunky, but make a column labelling the parent Field of study
  group_by(program.code.first)|>
  mutate(Field.of.study.parent = Field.of.study[match(program.code.top,program.code.first)])|>
  mutate(Field.of.study.parent = ifelse(length(unique(Field.of.study.parent[!is.na(Field.of.study.parent)]))!=1,
                                        NA,
                                        unique(Field.of.study.parent[!is.na(Field.of.study.parent)])))|> 
  # fill in Field.of.study.parent when the parent is a number and letter
  mutate(temp.prog = ifelse(
    is.na(Field.of.study.parent),     # still NA becasue the `program.code.first' doesn't appear as a `program.code.full'. typically because of the format ##.c
    Field.of.study[match(str_replace_all(program.code.full, pattern = "\\.[[:alpha:]]", replacement = ""),program.code.first)],  
    Field.of.study.parent))|>
  mutate(Field.of.study.parent = ifelse(length(unique(temp.prog[!is.na(temp.prog)]))!=1,
                                        NA,
                                        temp.prog))|> 
  select(-c("temp.prog"))|>
  ungroup()|>
  mutate(School = str_replace(GEO,pattern = "\\sUniversity", replacement = ""),
         School = str_replace(School,pattern = ",.*", replacement = ""),
         School = paste0(substr(School, 1,4)," ",substr(School, 15,19)))
#######relative growth since 2012.  
Baseline_grad_2012 =  grad_data |>
  dplyr::filter(Date == as_date("2012-07-01"))|>
  mutate(VALUE2012 = VALUE)|>
  select(School, Field.of.study,Program.type,VALUE2012)

grad_data = grad_data |> 
  inner_join(Baseline_grad_2012)|>
  mutate(Percent_growth_since_2012 = VALUE/VALUE2012*100)



grad_data |> 
  filter(program.code.top == TRUE) |> 
  select(Field.of.study) |>
  unique() |> 
  write_csv(paste0(location,"top_program_codes_grad.csv"))


grad_data |> 
  select(program.code.first, program.code.full,Field.of.study,Field.of.study.parent) |>
  unique() |>
  write_csv(paste0(location,"sub_program_codes_grad_by_level.csv"))

grad_data  |> write_csv(paste0(location,"grad_programs_data.csv"))
metadata   |> write_csv(paste0(location,"grad_programs_metadata.csv"))





#--------------------- combining grad and undergrads while trying to keep the datasize manageable


# ========

# all levels at 'major' universities (reduce to 49,226 rows and 12 columns)
comparing_data = data |> 
  dplyr::filter(UOM == "Number")|> 
  dplyr::filter(Gender %in% c("Total, gender")) |>
  dplyr::filter(Credential.type %in% c("Degree (includes applied degree)"))|>
  dplyr::filter(Institution.type == "University")|>
  dplyr::filter(Program.type %in% c(
      "Undergraduate program",
    "Graduate program (second cycle)",
    "Graduate program (third cycle)"))|>
  dplyr::filter(Credential.type %in% c("Degree (includes applied degree)"))|>
  dplyr::filter(Institution.type == "University")|>
  dplyr::filter(Status.of.student.in.Canada == "Total, status of student in Canada")|>
  select(REF_DATE, Date,GEO,Field.of.study,VALUE,Program.type)|>
  dplyr::filter(GEO %in% c("Canada",Geo_list[mac_doc],Geo_list[mac_comp])) |>
  # clunky, but extract the parent and child codes
  mutate(program.code.full = str_replace_all(Field.of.study, pattern = "(^.*\\[)|(\\])$", replacement = ""))|>
  mutate(program.code.first = str_replace_all(program.code.full, pattern = "\\..*$", replacement = ""))|>
  mutate(program.code.top = program.code.full == program.code.first) |>
  mutate(program.code.top = ifelse(program.code.top==FALSE, gsub(program.code.full, pattern = "\\.?c", replacement = "")== program.code.first, program.code.top))|>
  mutate(Field.of.study = as.character(Field.of.study))|>
  # clunky, but make a column labelling the parent Field of study
  group_by(program.code.first)|>
  mutate(Field.of.study.parent = Field.of.study[match(program.code.top,program.code.first)])|>
  mutate(Field.of.study.parent = ifelse(length(unique(Field.of.study.parent[!is.na(Field.of.study.parent)]))!=1,
                                        NA,
                                        unique(Field.of.study.parent[!is.na(Field.of.study.parent)])))|> 
  # fill in Field.of.study.parent when the parent is a number and letter
  mutate(temp.prog = ifelse(
    is.na(Field.of.study.parent),     # still NA becasue the `program.code.first' doesn't appear as a `program.code.full'. typically because of the format ##.c
    Field.of.study[match(str_replace_all(program.code.full, pattern = "\\.[[:alpha:]]", replacement = ""),program.code.first)],  
    Field.of.study.parent))|>
  mutate(Field.of.study.parent = ifelse(length(unique(temp.prog[!is.na(temp.prog)]))!=1,
                                        NA,
                                        temp.prog))|> 
  select(-c("temp.prog"))|>
  ungroup()|>
  mutate(School = str_replace(GEO,pattern = "\\sUniversity", replacement = ""),
         School = str_replace(School,pattern = ",.*", replacement = ""),
         School = paste0(substr(School, 1,4)," ",substr(School, 15,19))) |>
  pivot_wider(names_from = Program.type, values_from = VALUE) |> 
  rename_all(make.names) |>
  replace_na( list(Graduate.program..second.cycle. = 0,Graduate.program..third.cycle.=0))|>
  mutate(all_grad_programs = Graduate.program..second.cycle.+Graduate.program..third.cycle.)|>
  mutate(grad.to.undergrad.ratio = all_grad_programs / Undergraduate.program)


comparing_data |>
  write_csv(paste0(location,"grad_comparison.csv"))

comparing_data|> 
  select(Field.of.study, Field.of.study.parent)|> 
  unique()|>
  write_csv(paste0(location,"grad_comparison_fields.csv"))



###

