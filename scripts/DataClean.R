install.packages('dplyr')
install.packages('magrittr')
install.packages('rgdal')
install.packages('stringr')
install.packages('raster')

library(dplyr)
library(magrittr)
library(rgdal)
library(stringr)
library(raster)

# CDC data. Available at https://svi.cdc.gov/SVIDataToolsDownload.html
# replace /Users/jakesnyder/DisasterVulnerability/ with the path to the data on your machine

#Jake's Paths
cdc_county_path <- "/Users/jakesnyder/DisasterVulnerability/County"
cdc_tract_path <- "/Users/jakesnyder/DisasterVulnerability/Tract"
hazard_path <- "/Users/jakesnyder/DisasterVulnerability/ATTOM hazard.csv"
ccusa_path <- "/Users/jakesnyder/DisasterVulnerability/CountiesDioceses_052017.csv"
main_path <- "/Users/jakesnyder/DisasterVulnerability"

#Rich's Paths
#cdc_path<-"/Users/Richard/Documents/dev/DisasterVulnerability/merge_no_nulls"
#hazard_path<-"/Users/Richard/Documents/dev/DisasterVulnerability/ATTOM.csv"
#ccusa_path<-"/Users/Richard/Documents/dev/DisasterVulnerability/Poly_Counties.csv"

cdc_data <- readOGR(dsn = cdc_county_path, layer = "counties", stringsAsFactors = F)

# Disaster likelyhood by fips. Available if you have accest to proprietary data
# replace /Users/jakesnyder/DisasterVulnerability/ with the path to the data on your machine
hazard_data <- read.csv(hazard_path,stringsAsFactors = F, colClasses = c("FIPS" = "character"))

#remove extra columns
hazard_data<-hazard_data[,1:12]

# remove NA's from hazard data
hazard_data <- na.omit(hazard_data)

# Load CCUSA agency and remove extra columns
ccusa <- read.csv(ccusa_path,stringsAsFactors = F)
ccusa <- ccusa %>% select(FIPS,Diocese) %>%
  mutate(FIPS = str_pad(FIPS,5,pad="0"))


#test<-cdc_data@data
# join hazard data to shapefile
merge_data <- merge(cdc_data, hazard_data, by.x="FIPS", by.y="FIPS", all.x=T)
merge_data <- merge(merge_data, ccusa, by = "FIPS", all.x=T)

# getting data as data frame
county <- merge_data@data

# removing columns we don't need to keep the shapefile smaller
county <- county %>% select(FIPS,
                            LOCATIO,
                            E_TOTPO,
                            F_TOTAL,
                            starts_with('EP'),
                            -EP_UNIN,
                            starts_with('RP'),
                            contains('Risk'),
                            Diocese) %>%
  # rename columns to match tract file
  rename(LOCATION = LOCATIO,
         E_TOTPOP = E_TOTPO,
         EP_UNEMP = EP_UNEM,
         EP_NOHSDP = EP_NOHS,
         EP_AGE65 = EP_AGE6,
         EP_AGE17 = EP_AGE1,
         EP_DISABL = EP_DISA,
         EP_SNGPNT = EP_SNGP,
         EP_MINRTY = EP_MINR,
         EP_LIMENG = EP_LIME,
         EP_MUNIT = EP_MUNI,
         EP_MOBILE = EP_MOBI,
         EP_CROWD = EP_CROW,
         EP_NOVEH = EP_NOVE,
         EP_GROUPQ = EP_GROU,
         EPL_UNEMP = EPL_UNE,
         EPL_NOHSDP = EPL_NOH,
         EPL_AGE65 = EPL_AGE6,
         EPL_AGE17 = EPL_AGE1,
         EPL_DISABL = EPL_DIS,
         EPL_SNGPNT = EPL_SNG,
         EPL_MINRTY = EPL_MIN,
         EPL_LIMENG = EPL_LIM,
         EPL_MUNIT = EPL_MUN,
         EPL_MOBILE = EPL_MOB,
         EPL_CROWD = EPL_CRO,
         EPL_NOVEH = EPL_NOV,
         EPL_GROUPQ = EPL_GRO) %>%
  # set null values created by join to 0
  mutate(Total.Natural.Hazard.Risk.Index = ifelse(is.na(Total.Natural.Hazard.Risk.Index),0,Total.Natural.Hazard.Risk.Index)) %>%
  mutate(Earthquake.Risk.Index = ifelse(is.na(Earthquake.Risk.Index),0,Earthquake.Risk.Index)) %>%
  mutate(Tornado.Risk.Index = ifelse(is.na(Tornado.Risk.Index),0,Tornado.Risk.Index)) %>%
  mutate(Hail.Risk.Index = ifelse(is.na(Hail.Risk.Index),0,Hail.Risk.Index)) %>%
  mutate(Hurricane.Storm.Surge.Risk.Index = ifelse(is.na(Hurricane.Storm.Surge.Risk.Index),0,Hurricane.Storm.Surge.Risk.Index)) %>%
  mutate(Flood.Risk.Index = ifelse(is.na(Flood.Risk.Index),0,Flood.Risk.Index)) %>%
  mutate(Wildfire.Risk.Index = ifelse(is.na(Wildfire.Risk.Index),0,Wildfire.Risk.Index)) %>%
  # rename hazard field names to be <11 characters
  rename(Total.Risk = Total.Natural.Hazard.Risk.Index,
         Earthquake = Earthquake.Risk.Index,
         Tornado = Tornado.Risk.Index,
         Hail = Hail.Risk.Index,
         Hurricane = Hurricane.Storm.Surge.Risk.Index,
         Flood = Flood.Risk.Index,
         Wildfire = Wildfire.Risk.Index)

# setting it back to a large SpatialPolygonsDataframe
merge_data@data <- county

# replace /Users/jakesnyder/DisasterVulnerability/ with the path to your desired directory
writeOGR(merge_data, dsn=main_path, layer="counties", driver="ESRI Shapefile", overwrite_layer = T)

## tract file reduction
svi <- readOGR(cdc_tract_path, stringsAsFactors = F)
tract <- svi@data

# removing columns we don't need to keep the shapefile smaller
tract <- tract %>% select(FIPS,
                          LOCATION,
                          E_TOTPOP,
                          F_TOTAL,
                          starts_with('EP'),
                          -EP_UNINSUR,
                          starts_with('RP'))

# change null values to zero
tract[tract==-999] <- 0

svi@data <- tract
# replace /Users/jakesnyder/DisasterVulnerability/ with the path to your desired directory
writeOGR(svi, dsn=main_path, layer="tracts", driver="ESRI Shapefile", overwrite_layer = T)
