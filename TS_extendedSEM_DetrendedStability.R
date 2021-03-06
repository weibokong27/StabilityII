###############################################
# EXTENDED SEM including mean + SD            #
# added paths for mean and sd water avail.    #
# to asynchrony                               #
# for each combination of                     #
# phylogenetic and functional                 #
# diversity metric:                           #
# 1) FDis + eMNTD                             #
# 2) FRic + eMNTD                             #
# 3) FDis + eMPD                              #
# 4) FRic + eMPD                              #
###############################################

require(devtools)
install_github("jslefche/piecewiseSEM")

require(dplyr)
require(piecewiseSEM)
library(semPlot)
library(lmerTest)
library(nlme)
library(car) 

# Data
stab<-read.delim("data.csv",sep=",",header=T)

stab<-filter(stab,Site!="BIODEPTH_GR")  # should get rid of site where we didn't have good trait coverage

stab_4<-select(stab,Site,Study_length,UniqueID,SppN,eMPD,eMNTD,ePSE,sMPD,sMNTD,FDis4,FRic4,PCAdim1_4trts,SLA, LDMC, LeafN, LeafP,
               Plot_TempStab,Plot_TempStab_Detrend,Plot_Biomassxbar, Plot_Biomasssd,Plot_Biomasssd_detrend=detrend_sd,
               Gross_synchrony, mArid,sdAridity)

# for plots with ONLY 1 spp, we assume that a species #is perfectly synchronized with itself

stab_4$Plot_Asynchrony<-ifelse(is.na(stab_4$Plot_Asynchrony)==TRUE,1,stab_4$Plot_Asynchrony) 
stab_4$Gross_synchrony<-ifelse(is.na(stab_4$Gross_synchrony)==TRUE,1,stab_4$Gross_synchrony) 
stab_4$Loreau_synchrony<-ifelse(is.na(stab_4$Loreau_synchrony)==TRUE,1,stab_4$Loreau_synchrony) 

# convert synchrony metrics to different scale

stab_4$PlotAsynchrony_s<-stab_4$Plot_Asynchrony*-1

stab_4$GrossAsynchrony_s<-stab_4$Gross_synchrony*-1

# further adjustments

stab_4$SppN<-as.numeric(stab_4$SppN)

stab_4$TS_lg2<-log(stab_4$Plot_TempStab,base=2)

stab_4$TS_detrend_lg2<-log(stab_4$Plot_TempStab_Detrend,base=2)

stab_4$lg2SppN <- log(stab_4$SppN,2)

stab_4$lg2_mArid  <-log(stab_4$mArid,base=2)

# Filter out NAs for Asynchrony and  FRic4

stab_4<-filter(stab_4, is.na(PlotAsynchrony_s)==FALSE)
stab_444<-filter(stab_4, is.na(FRic4)==FALSE)

# Control list set up for LMM in nlme 

bb<-lmeControl(msMaxIter=0,msVerbose = TRUE,opt="optim",maxIter=100,optimMEthod="L-BFGS-B")  ######## "msMaxIter=0" is important in here!!!
cc<-lmeControl(opt="optim")

##################
# FDis_eMNTD #####
##################

modList2=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMNTD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(Plot_Biomassxbar~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMNTD+FDis4+lg2_mArid, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  lme(Plot_Biomasssd_detrend~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMNTD+FDis4+sdAridity, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(TS_detrend_lg2~Plot_Biomassxbar+Plot_Biomasssd_detrend,random=~1|Site, control=cc,data=stab_444)
)

lapply(modList2, plot)

# Explore distribution of residuals

lapply(modList2, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList2[3:6], vif)


sem.fit(modList2,stab_444,corr.errors=c("eMNTD ~~ FDis4","Plot_Biomasssd_detrend ~~ Plot_Biomassxbar","FDis4 ~~ PCAdim1_4trts",
                                        "TS_detrend_lg2 ~~ FDis4","TS_detrend_lg2 ~~ eMNTD","TS_detrend_lg2 ~~ GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #initial model


emntdfdis.fit<-sem.fit(modList2,stab_444,
                       corr.errors=c("eMNTD ~~ FDis4","Plot_Biomasssd_detrend ~~ Plot_Biomassxbar","FDis4 ~~ PCAdim1_4trts",
                                     "TS_detrend_lg2 ~~ FDis4","TS_detrend_lg2 ~~ eMNTD","TS_detrend_lg2 ~~ GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"),
                       conditional=T,
                       model.control = list(lmeControl(opt = "optim"))) 

# add correlated error for eMNTD~~ sd of biomass

emntdfdis.fit<-cbind(emntdfdis.fit$Fisher.C,emntdfdis.fit$AIC)
emntdfdis.fit$ModClass<-"FDis_eMNTD_extended"

ts_emntd2<-sem.coefs(modList2,stab_444,standardize="scale",
                     corr.errors=c("eMNTD ~~ FDis4","Plot_Biomasssd_detrend ~~ Plot_Biomassxbar","FDis4 ~~ PCAdim1_4trts",
                                   "TS_detrend_lg2 ~~ FDis4","TS_detrend_lg2 ~~ eMNTD","TS_detrend_lg2 ~~ GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"))
ts_emntd2$ModClass<-"FDis_eMNTD_extended"

mf_ts_emntd<-sem.model.fits(modList2)
mf_ts_emntd$ResponseVars<-c("eMNTD","FDis4","Asynchrony","xbar_Biomass", "sd_Biomass","Temp_Stability_Detrend")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FDis4, lg2_mArid, sdArid","Asynchrony,lg2SppN,F-S,FD,PD, lg2_mArid",
                        "Asynchrony,lg2SppN,F-S,FD,PD, sdArid","meanBiomass,sdBiomass")
mf_ts_emntd$ModClass<-"FDis_eMNTD_extended"

#write out model results
write.table(ts_emntd2,"detrend_TS_emntd_fdis_sem_coefs_Extended.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"detrend_TS_emntd_fdis_model_fits_Extended.csv",sep=",",row.names=F)
write.table(emntdfdis.fit,"detrend_TS_emntd_fdis_semfit_Extended.csv",sep=",",row.names=F)

#######################
## FRic4 - eMNTD    ###
#######################

modList22=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMNTD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(Plot_Biomassxbar~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMNTD+FRic4+lg2_mArid, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(Plot_Biomasssd_detrend~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMNTD+FRic4+sdAridity, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(TS_detrend_lg2~Plot_Biomassxbar+Plot_Biomasssd_detrend,random=~1|Site, control=cc,data=stab_444)
  
)

lapply(modList22, plot)

# Explore distribution of residuals

lapply(modList22, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList22[3:6], vif)

sem.fit(modList22,stab_444,corr.errors=c("eMNTD~~FRic4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FRic4 ~~ PCAdim1_4trts",
                                         "TS_detrend_lg2~~FRic4","TS_detrend_lg2~~eMNTD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #initial model


emntdfric.fit<-sem.fit(modList22,stab_444,
                       corr.errors=c("eMNTD~~FRic4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FRic4 ~~ PCAdim1_4trts",
                                     "TS_detrend_lg2~~FRic4","TS_detrend_lg2~~eMNTD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"),
                       conditional=T,
                       model.control = list(lmeControl(opt = "optim"))) 


emntdfric.fit<-cbind(emntdfric.fit$Fisher.C,emntdfric.fit$AIC)
emntdfric.fit$ModClass<-"FRic_eMNTD_extended"

ts_emntd2<-sem.coefs(modList22,stab_444,standardize="scale",
                     corr.errors=c("eMNTD~~FRic4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FRic4 ~~ PCAdim1_4trts",
                                   "TS_detrend_lg2~~FRic4","TS_detrend_lg2~~eMNTD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"))
ts_emntd2$ModClass<-"FRic_eMNTD_extended"

mf_ts_emntd<-sem.model.fits(modList22)
mf_ts_emntd$ResponseVars<-c("eMNTD","FRic4","Asynchrony","xbar_Biomass", "sd_Biomass","Temp_Stability_Detrend")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FRic4, lg2_mArid, sdArid","Asynchrony,lg2SppN,F-S,eMNTD,FRic4, lg2_mArid",
                        "Asynchrony,lg2SppN,F-S, PD, FD, sdArid","meanBiomass,sdBiomass")
mf_ts_emntd$ModClass<-"FRic_eMNTD_extended"

# write out model results
write.table(ts_emntd2,"detrend_TS_emntd_fric_sem_coefs_Extended.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"detrend_TS_emntd_fric_model_fits_Extended.csv",sep=",",row.names=F)
write.table(emntdfric.fit,"detrend_TS_emntd_fric_semfit_Extended.csv",sep=",",row.names=F)

##################
# FDis_MPD ######
##################

modList3=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMPD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(Plot_Biomassxbar~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMPD+FDis4+lg2_mArid, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(Plot_Biomasssd_detrend~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMPD+FDis4+sdAridity, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(TS_detrend_lg2~Plot_Biomassxbar+Plot_Biomasssd_detrend,random=~1|Site, control=cc,data=stab_444)
)

lapply(modList3, plot)

# Explore distribution of residuals

lapply(modList3, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList3[3:6], vif)


sem.fit(modList3,stab_444,corr.errors=c("eMPD~~FDis4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FDis4 ~~ PCAdim1_4trts",
                                        "TS_detrend_lg2~~FDis4","TS_detrend_lg2~~eMPD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #initial model

# add correlated erors btw  eMPD & PCAdim1_4trts 

empdfdis.fit<-sem.fit(modList3,stab_444,
                      corr.errors=c("eMPD~~FDis4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FDis4 ~~ PCAdim1_4trts",
                                    "TS_detrend_lg2~~FDis4","TS_detrend_lg2~~eMPD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN","eMPD~~PCAdim1_4trts"),
                      conditional=T,
                      model.control = list(lmeControl(opt = "optim"))) 

empdfdis.fit<-cbind(empdfdis.fit$Fisher.C,empdfdis.fit$AIC)
empdfdis.fit$ModClass<-"FDis_eMPD_Extended"

ts_empd2<-sem.coefs(modList3,stab_444,standardize="scale",
                    corr.errors=c("eMPD~~FDis4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FDis4 ~~ PCAdim1_4trts",
                                  "TS_detrend_lg2~~FDis4","TS_detrend_lg2~~eMPD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN","eMPD~~PCAdim1_4trts"))
ts_empd2$ModClass<-"FDis_eMPD_Extended"

#sem.plot(modList3, stab_444, standardize = "scale")

mf_ts_empd<-sem.model.fits(modList3)
mf_ts_empd$ResponseVars<-c("eMPD","FDis4","Asynchrony","xbar_Biomass", "sd_Biomass","Temp_Stability_Detrend")
mf_ts_empd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FDis4, lg2_mArid, sdArid","Asynchrony,lg2SppN,F-S,FD,PD, lg2_mArid",
                       "Asynchrony,lg2SppN,F-S, FD, PD, sdArid","meanBiomass,sdBiomass")
mf_ts_empd$ModClass<-"FDis_eMPD_Extended"

#write out model results
write.table(ts_empd2,"detrend_TS_empd_fdis_sem_coefs_Extended.csv",sep=",",row.names=F)
write.table(mf_ts_empd,"detrend_TS_empd_fdis_modelfits_Extended.csv",sep=",",row.names=F)
write.table(empdfdis.fit,"detrend_TS_empd_fdis_semfits_Extended.csv",sep=",",row.names=F)

##################
# FRic_MPD #######
##################

modList44=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMPD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_444),
  lme(Plot_Biomassxbar~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMPD+FRic4+lg2_mArid, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(Plot_Biomasssd_detrend~GrossAsynchrony_s+PCAdim1_4trts+lg2SppN+eMPD+FRic4+sdAridity, random=~1+lg2SppN|Site,control=cc, data=stab_444),
  
  lme(TS_detrend_lg2~Plot_Biomassxbar+Plot_Biomasssd_detrend,random=~1|Site, control=cc,data=stab_444)
  
)

lapply(modList44, plot)

# Explore distribution of residuals

lapply(modList44, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList44[3:6], vif)


sem.fit(modList44,stab_444,corr.errors=c("eMPD~~FRic4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FRic4 ~~ PCAdim1_4trts",
                                         "TS_detrend_lg2~~FRic4","TS_detrend_lg2~~eMPD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #initial model

#add correlated errors for empd and f-s

empdfric.fit<-sem.fit(modList44,stab_444,
                      corr.errors=c("eMPD~~FRic4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FRic4 ~~ PCAdim1_4trts",
                                    "TS_detrend_lg2~~FRic4","TS_detrend_lg2~~eMPD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN","eMPD~~PCAdim1_4trts"),
                      conditional=T,
                      model.control = list(lmeControl(opt = "optim"))) 

empdfric.fit<-cbind(empdfric.fit$Fisher.C,empdfric.fit$AIC)
empdfric.fit$ModClass<-"FRic_eMPD_Extended"

ts_empd2<-sem.coefs(modList44,stab_444,standardize="scale",
                    corr.errors=c("eMPD~~FRic4","Plot_Biomasssd_detrend~~Plot_Biomassxbar","FRic4 ~~ PCAdim1_4trts",
                                  "TS_detrend_lg2~~FRic4","TS_detrend_lg2~~eMPD","TS_detrend_lg2~~GrossAsynchrony_s","TS_detrend_lg2 ~~ lg2SppN","eMPD~~PCAdim1_4trts"))
ts_empd2$ModClass<-"FRic_eMPD_Extended"

mf_ts_empd2<-sem.model.fits(modList44)
mf_ts_empd2$ResponseVars<-c("eMPD","FRic4","Asynchrony","xbar_Biomass", "sd_Biomass","Temp_Stability_Detrend")
mf_ts_empd2$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FRic4, lg2_mArid, sdArid","Asynchrony,lg2SppN,F-S,FRic4,PD, lg2_mArid",
                        "Asynchrony,lg2SppN,F-S, FRic4, PD, sdArid","meanBiomass,sdBiomass")
mf_ts_empd2$ModClass<-"FRic_eMPD_Extended"

# write out model results
write.table(ts_empd2,"detrend_TS_empd_fric_sem_coefs_Extended.csv",sep=",",row.names=F)
write.table(mf_ts_empd2,"detrend_TS_empd_fric_model_fits_Extended.csv",sep=",",row.names=F)
write.table(empdfric.fit,"detrend_TS_empd_fric_semfit_Extended.csv",sep=",",row.names=F)