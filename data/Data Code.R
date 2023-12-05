library(dplyr)

data <- read.csv("psam_p24.csv")
colnames(data)
#Missing rent 

select <- data %>% select("SERIALNO","RELSHIPP", "SEX", "AGEP", "RAC1P", "RACBLK", "ESR", "PINCP", "DREM", "DPHY", "DOUT", "DDRS", "DEYE", "DEAR", "VPS", "POWPUMA", "FHISP")
colnames(select) <- c("serial", "relate", "sex", "age", "race", "racblk", "empstat", "inctot", "diffrem", "diffphys", "diffmob", "diffcare", "diffeye", "diffhear", "vetstat", "pwpuma00", "ethnicity")

eligibility <- function(familysize, income) {
  if (familysize == 1 && income < 21870) {
    return(TRUE)
  } else if (familysize == 2 && income < 29580) {
    return(TRUE)
  } else if (familysize == 3 && income < 37290) {
    return(TRUE)
  } else if (familysize == 4 && income < 45000) {
    return(TRUE)
  } else if (familysize == 5 && income < 52710) {
    return(TRUE)
  } else if (familysize == 6 && income < 60420) {
    return(TRUE)
  } else if (familysize == 7 && income < 68130) {
    return(TRUE)
  } else if (familysize == 8 && income < 75840) {
    return(TRUE)
  } else if (familysize >= 9) {
    threshold_income = 75840 + 5140 * (familysize - 8)
    if (income < threshold_income) {
      return(TRUE)
    }
  }
  return(FALSE)
}

#Create new dataframe with desired atributes:
households <- data.frame(unique(select$serial))
colnames(households) <- "serialno"
households$'familysize' <- 0
households$'income' <- 0
households$'race' <- 0
households$'ethnicity' <- 0
households$'numchildren' <- 0
households$'numelderly' <- 0
households$'veteran' <- 0
households$'disability' <- 0
households$'waittime' <- 0
households$'topchoice' <- 0

#This takes a while to run, theoretically should loop through all and not just 1:1000
for (i in 1:length(households$serialno))
{
  currentnum <- households[i, 1]
  currenthouse <- select[select$serial == currentnum, ]
  households[i, 'familysize'] <- length(currenthouse$age)
  households[i, 'income'] <- sum(currenthouse$inctot, na.rm = T)
  if (eligibility(households[i, 'familysize'], households[i, 'income']))
  {
    households[i, 'race'] <- currenthouse[currenthouse$relate == 20, 'race']
    households[i, 'ethnicity'] <- currenthouse[currenthouse$relate == 20, 'ethnicity']
    households[i, 'numchildren'] <- length(currenthouse[currenthouse$age < 18,]$serial)
    households[i, 'numelderly'] <- length(currenthouse[currenthouse$age > 64,]$serial)
    households[i, 'veteran'] <- ifelse(all(is.na(currenthouse$vetstat), na.rm = TRUE), 0, 1)
    households[i, 'disability'] <- result <- ifelse(any(currenthouse$diffrem != 0 | currenthouse$diffphys != 0 | currenthouse$diffmob != 0 | currenthouse$diffcare != 0 | currenthouse$diffeye != 0 | currenthouse$diffhear != 0), 1, 0)    
  }
  else
  {
    households[i, 'race'] <- 99999
  }
  
}

eligible_households <- households[households$race != 99999, ]
write.csv(eligible_households, "Eligible_Applicants.csv")
