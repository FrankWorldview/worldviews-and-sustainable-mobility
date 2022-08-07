* Encoding: UTF-8.

SHOW N.

SORT VARIABLES BY NAME.

VARIABLE LABELS Rage 'Age'.
VARIABLE LABELS RAgeCat 'Age category'.
VARIABLE LABELS HHincome 'Household income'.
VARIABLE LABELS HEdQual 'Educational level_orig'.

SELECT IF RANGE(HEdQual, 1, 7).

FREQUENCIES VARIABLES=HEdQual
    /ORDER=ANALYSIS.

DESCRIPTIVES VARIABLES=HEdQual
    /STATISTICS=MEAN STDDEV MIN MAX.

* Change foreign degree (HEdQual = 6) to $SYSMIS and replce it with the mean value.
DO IF RANGE(HEdQual, 1, 5).
    COMPUTE EduLevel = 7 - HEdQual.
ELSE IF (HEdQual = 7).
    COMPUTE EduLevel = 1.
ELSE.
    COMPUTE EduLevel = $SYSMIS.
END IF.

RMV /EduLevel = SMEAN(EduLevel).

VARIABLE LABELS EduLevel 'Educational level'.

FREQUENCIES VARIABLES=EduLevel
    /ORDER=ANALYSIS.

DESCRIPTIVES VARIABLES=EduLevel
    /STATISTICS=MEAN STDDEV MIN MAX.

SELECT IF RANGE(Rsex, 1, 2).

* Exclude Rage = 98 (don't know) or 99 (refusal).
* SELECT IF NOT(Rage = 98 OR Rage = 99).

SELECT IF RANGE(RAgeCat, 1, 7).

SELECT IF RANGE(HHincome, 1, 20).

* Exclude PartyIDN = -2 (schedule not applicable) and -1 (item not applicable).
SELECT IF RANGE(PartyIDN, 1, 99).

RECODE Rsex (1 = 0) (ELSE = 1) INTO Sex.
VARIABLE LABELS Sex 'Sex'.
VALUE LABELS
    Sex
    0 'Male'
    1 'Female'.

FREQUENCIES VARIABLES=Rsex
    /ORDER=ANALYSIS.

FREQUENCIES VARIABLES=Sex
    /ORDER=ANALYSIS.

COMPUTE Party = PartyIDN.
FORMATS Party(f2.0).

FREQUENCIES VARIABLES=Party
    /ORDER=ANALYSIS.

* If Party = 10 (other party), 11 (other answer), 20 (refused to say), 98 (don't know), or 99 (refusal), then set it to other party (10).
DO IF (Party = 10 OR Party = 11 OR Party = 20 OR Party = 98 OR Party = 99).
    COMPUTE Party = 10.
END IF.

* If Party = 12 (none), then set it to no party (0).
DO IF (Party = 12).
    COMPUTE Party = 0.
END IF.

* For linear regression.
* Consolidate PC (5), BNP (8), SOC (9), and other (10) to OTH, becuase they are too few.
RECODE Party (0 = 1) (ELSE = 0) INTO NO_PARTY.
RECODE Party (1 = 1) (ELSE = 0) INTO CON.
RECODE Party (2 = 1) (ELSE = 0) INTO LAB.
RECODE Party (3 = 1) (ELSE = 0) INTO LD.
RECODE Party (4 = 1) (ELSE = 0) INTO SNP.
RECODE Party (6 = 1) (ELSE = 0) INTO GRE.
RECODE Party (7 = 1) (ELSE = 0) INTO UKIP.
RECODE Party (5 = 1) (8 = 1) (9 = 1) (10 = 1) (ELSE = 0) INTO OTH.

VARIABLE LABELS NO_PARTY 'No party'.
VARIABLE LABELS CON 'CON'.
VARIABLE LABELS LAB 'LAB'.
VARIABLE LABELS LD 'LD'.
VARIABLE LABELS SNP 'SNP'.
VARIABLE LABELS GRE 'GRE'.
VARIABLE LABELS UKIP 'UKIP'.
VARIABLE LABELS OTH 'OTH'.

FREQUENCIES VARIABLES=Party
    /ORDER=ANALYSIS.

FREQUENCIES VARIABLES=OTH
    /ORDER=ANALYSIS.

* Party for GLM.
* Consolidate none (0), SNP (4), PC (5), and other (10) to 8, becuase they are too few.
RECODE Party (0 = 8) (1 = 1) (2 = 2) (3 = 3) (4 = 8) (5 = 8) (6 = 4) (7 = 5) (8 = 6) (9 = 7) (10 = 8) INTO Party_G.
VARIABLE LABELS Party_G 'Party idenification'.
FORMATS Party_G(f1.0).

FREQUENCIES VARIABLES=Party_G
    /ORDER=ANALYSIS.

* For spatial microsimulation.
RECODE Party (1 = 1) (ELSE = 0) INTO CON1.
RECODE Party (2 = 1) (ELSE = 0) INTO LAB1.
RECODE Party (3 = 1) (ELSE = 0) INTO LD1.
RECODE Party (4 = 1) (ELSE = 0) INTO SNP1.
RECODE Party (5 = 1) (ELSE = 0) INTO PC1.
RECODE Party (6 = 1) (ELSE = 0) INTO GRE1.
RECODE Party (7 = 1) (ELSE = 0) INTO UKIP1.
RECODE Party (8 = 1) (ELSE = 0) INTO BNP1.
RECODE Party (9 = 1) (ELSE = 0) INTO SOC1.
RECODE Party (10 = 1) (ELSE = 0) INTO OTH1.

* If Party = none (0), SNP (4), PC (5), or other (10), then OTHERS1 = 1.
DO IF (Party = 0 OR Party = 4 OR Party = 5 OR Party = 10).
    COMPUTE OTHERS1 = 1.
    *     COMPUTE CON1 = 0.
    *     COMPUTE LAB1 = 0.
    *     COMPUTE LD1 = 0.
    *     COMPUTE GRE1 = 0.
    *     COMPUTE UKIP1 = 0.
    *     COMPUTE BNP1 = 0.
    *     COMPUTE SOC1 = 0.
ELSE.
    COMPUTE OTHERS1 = 0.
END IF.

FREQUENCIES VARIABLES=OTHERS1
    /ORDER=ANALYSIS.

* The sum of each individual.
COMPUTE TestSum = CON1 + LAB1 + LD1 + GRE1 + UKIP1 + BNP1 + SOC1 + OTHERS1.

* If no missing values, then good.
FREQUENCIES VARIABLES=TestSum
    /ORDER=ANALYSIS.

EXECUTE.
SHOW N.

SELECT IF RANGE(redistrb, 1, 5).
COMPUTE ReDist = 6 - redistrb.
VARIABLE LABELS ReDist 'Government should redistribute income from the better-off to those who are less well-off.'.

SELECT IF RANGE(richlaw, 1, 5).
COMPUTE RichPoorLaws = 6 - richlaw.
VARIABLE LABELS RichPoorLaws 'There is one law for the rich and one for the poor.'.

* Ver A & C.
SELECT IF RANGE(govresp7, 1, 4).
COMPUTE ReDiff = 5 - govresp7.
VARIABLE LABELS ReDiff 'Government should reduce income differences between the rich and the poor.'.

EXECUTE.
SHOW N.

SELECT IF RANGE(obey, 1, 5).
COMPUTE ObeyAuth = 6 - obey.
VARIABLE LABELS ObeyAuth 'Schools should teach children to obey authority.'.

SELECT IF RANGE(tradvals, 1, 5).
COMPUTE Trad = 6 - tradvals.
VARIABLE LABELS Trad 'Young people today do not have enough respect for traditional British values.'.

SELECT IF RANGE(censor, 1, 5).
COMPUTE Censorship = 6 - censor.
VARIABLE LABELS Censorship 'Censorship of films and magazines is necessary to uphold moral standards.'.

EXECUTE.
SHOW N.

* Ver A & C.
SELECT IF RANGE(gvspend7, 1, 5).
COMPUTE LessSpendUnemp = gvspend7.
VARIABLE LABELS LessSpendUnemp 'Government should not spend more on unemployment benefits.'.

SELECT IF RANGE(welffeet, 1, 5).
COMPUTE LessWelFeet = 6 - welffeet.
VARIABLE LABELS LessWelFeet 'If welfare benefits were not so generous, people would learn to stand on their own two feet.'.

SELECT IF RANGE(damlives, 1, 5).
COMPUTE LessWelDamage = damlives.
VARIABLE LABELS LessWelDamage "Cutting welfare benefits would not damage too many people's lives.".

EXECUTE.
SHOW N.

RELIABILITY
    /VARIABLES=ReDist RichPoorLaws ReDiff
    /SCALE('ALL VARIABLES') ALL
    /MODEL=ALPHA
    /STATISTICS=CORR
    /SUMMARY=TOTAL.

RELIABILITY
    /VARIABLES=ObeyAuth Trad Censorship
    /SCALE('ALL VARIABLES') ALL
    /MODEL=ALPHA
    /STATISTICS=CORR
    /SUMMARY=TOTAL.

RELIABILITY
    /VARIABLES=LessSpendUnemp LessWelFeet LessWelDamage
    /SCALE('ALL VARIABLES') ALL
    /MODEL=ALPHA
    /STATISTICS=CORR
    /SUMMARY=TOTAL.

FACTOR
    /VARIABLES ReDist RichPoorLaws ReDiff ObeyAuth Trad Censorship LessSpendUnemp LessWelFeet LessWelDamage
    /MISSING LISTWISE
    /ANALYSIS ReDist RichPoorLaws ReDiff ObeyAuth Trad Censorship LessSpendUnemp LessWelFeet LessWelDamage
    /PRINT UNIVARIATE INITIAL CORRELATION SIG DET KMO INV REPR AIC EXTRACTION ROTATION FSCORE
    /FORMAT SORT BLANK(.10)
    /PLOT EIGEN ROTATION
    /CRITERIA FACTORS(3) ITERATE(25)
    /EXTRACTION PAF
    /CRITERIA ITERATE(25) DELTA(0)
    /ROTATION OBLIMIN
    /SAVE REG(ALL)
    /METHOD=CORRELATION.

*   /SAVE BART(ALL)

VARIABLE LABELS FAC1_1 'I'.
VARIABLE LABELS FAC2_1 'H'.
VARIABLE LABELS FAC3_1 'E'.

COMPUTE F1 = FAC3_1.
COMPUTE F2 = FAC2_1.
COMPUTE F3 = FAC1_1.

VARIABLE LABELS F1 'Egalitarianism'.
VARIABLE LABELS F2 'Hierarchy'.
VARIABLE LABELS F3 'Individualism'.

COMPUTE Worldview = 1.
If (F2 > F1) Worldview = 2.
If ((F3 > F1) AND (F3 > F2)) Worldview = 3.

VARIABLE LABELS Worldview 'Worldview'.

VALUE LABELS
    Worldview
    1 'Egalitarian'
    2 'Hierarchist'
    3 'Individualist'.

FREQUENCIES VARIABLES=Worldview
    /ORDER=ANALYSIS.

SORT CASES BY Worldview.

ONEWAY Sex Rage RAgeCat HHincome EduLevel BY Worldview
    /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
    /PLOT MEANS
    /MISSING ANALYSIS
    /POSTHOC=TUKEY GH ALPHA(0.05).

EXECUTE.
SHOW N.

* All people

DO IF RANGE(carreduc, 1, 5).
    COMPUTE ReduceCarUse = 6 - carreduc.
ELSE.
    COMPUTE ReduceCarUse = $SYSMIS.
END IF.
*VARIABLE LABELS ReduceCarUse 'For the sake of the environment, everyone should reduce how much they use their cars.'.

DO IF RANGE(carallow, 1, 5).
    COMPUTE AllowCarUse = 6 - carallow.
ELSE.
    COMPUTE AllowCarUse = $SYSMIS.
END IF.
*VARIABLE LABELS AllowCarUse 'People should be allowed to use their cars as much as they like, even if it causes damage to the environment.'.

DO IF RANGE(cartaxhi, 1, 5).
    COMPUTE HigherCarTax = 6 - cartaxhi.
ELSE.
    COMPUTE HigherCarTax = $SYSMIS.
END IF.
*VARIABLE LABELS HigherCarTax 'For the sake of the environment, car users should pay higher taxes.'.

DO IF RANGE(carenvdc, 1, 5).
    COMPUTE RoadPriceIncentive = 6 - carenvdc.
ELSE.
    COMPUTE RoadPriceIncentive = $SYSMIS.
END IF.
*VARIABLE LABELS RoadPriceIncentive 'People who drive cars that are better for the environment should pay less to use the roads than people whose cars are more harmful to the environment.'.

DO IF RANGE(TrfPb10u, 1, 4).
    COMPUTE FumesProblem = 5 - TrfPb10u.
ELSE.
    COMPUTE FumesProblem = $SYSMIS.
END IF.
*VARIABLE LABELS FumesProblem 'How serious a problem for you are exhaust fumes from traffic in towns and cities?'.

DO IF RANGE(carnod2, 1, 5).
    COMPUTE UnlessOthersDo = 6 - carnod2.
ELSE.
    COMPUTE UnlessOthersDo = $SYSMIS.
END IF.
*VARIABLE LABELS UnlessOthersDo 'There is no point in reducing my car use to help the environment unless others do the same.'.

DO IF RANGE(speedlim, 1, 5).
    COMPUTE ObeySpeedLimit = 6 - speedlim.
ELSE.
    COMPUTE ObeySpeedLimit = $SYSMIS.
END IF.
*VARIABLE LABELS ObeySpeedLimit 'People should drive within the speed limit.'.

DO IF RANGE(CycDang, 1, 5).
    COMPUTE BikeDanger = 6 - CycDang.
ELSE.
    COMPUTE BikeDanger = $SYSMIS.
END IF.
*VARIABLE LABELS BikeDanger 'It is too dangerous for me to cycle on the roads.'.

DO IF RANGE(TRFPB9U, 1, 4).
    COMPUTE CongestionProblem = 5 - TRFPB9U.
ELSE.
    COMPUTE CongestionProblem = $SYSMIS.
END IF.
*VARIABLE LABELS CongestionProblem 'How serious a problem for you is traffic congestion in towns and cities?'.

* Car users.

COMPUTE CReduceCarTravel = CCACar.

DO IF (CReduceCarTravel = 6).
    COMPUTE CReduceCarTravel = 1.
END IF.

DO IF RANGE(CReduceCarTravel, 1, 5).
    COMPUTE CReduceCarTravel = 6 - CReduceCarTravel.
ELSE.
    COMPUTE CReduceCarTravel = $SYSMIS.
END IF.
*VARIABLE LABELS CReduceCarTravel 'I am willing to reduce the amount I travel by car, to help reduce the impact of climate change.'.

COMPUTE CLowCarbonCar = CCALowE.

DO IF (CLowCarbonCar = 6) OR (CLowCarbonCar = 7).
    COMPUTE CLowCarbonCar = 1.
END IF.

DO IF RANGE(CLowCarbonCar, 1, 5).
    COMPUTE CLowCarbonCar = 6 - CLowCarbonCar.
ELSE.
    COMPUTE CLowCarbonCar = $SYSMIS.
END IF.
*VARIABLE LABELS CLowCarbonCar 'Next time I buy a car, I would be willing to buy a car with lower CO2 emissions. This might be an ordinary car with a smaller or more efficient engine, or a vehicle that runs on electric or alternative fuels.'.

EXECUTE.

* ANOVA for all people and car users

ONEWAY ReduceCarUse AllowCarUse HigherCarTax RoadPriceIncentive FumesProblem UnlessOthersDo ObeySpeedLimit BikeDanger CongestionProblem CReduceCarTravel CLowCarbonCar BY Worldview
    /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
    /PLOT MEANS
    /MISSING ANALYSIS
    /POSTHOC=TUKEY GH ALPHA(0.05).

SHOW N.

* COMPUTE ReduceCarUse_RS = ReduceCarUse * 2.
* COMPUTE AllowCarUse_RS = AllowCarUse * 2.
* COMPUTE HigherCarTax_RS = HigherCarTax * 2.
* COMPUTE RoadPriceIncentive_RS = RoadPriceIncentive * 2.
* COMPUTE FumesProblem_RS = FumesProblem * 2.5.
* COMPUTE UnlessOthersDo_RS = UnlessOthersDo * 2.
* COMPUTE ObeySpeedLimit_RS = ObeySpeedLimit * 2.
* COMPUTE BikeDanger_RS = BikeDanger * 2.
* COMPUTE CongestionProblem_RS = CongestionProblem * 2.5.
* COMPUTE CReduceCarTravel_RS = CReduceCarTravel * 2.
* COMPUTE CLowCarbonCar_RS = CLowCarbonCar * 2.

* ONEWAY ReduceCarUse_RS AllowCarUse_RS HigherCarTax_RS RoadPriceIncentive_RS FumesProblem_RS UnlessOthersDo_RS ObeySpeedLimit_RS BikeDanger_RS CongestionProblem_RS CReduceCarTravel_RS CLowCarbonCar_RS BY Worldview
    /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
    /PLOT MEANS
    /MISSING ANALYSIS
    /POSTHOC=TUKEY GH ALPHA(0.05).

CORRELATIONS
    /VARIABLES=F1 F2 F3 ReduceCarUse AllowCarUse HigherCarTax RoadPriceIncentive FumesProblem UnlessOthersDo ObeySpeedLimit BikeDanger CongestionProblem CReduceCarTravel CLowCarbonCar
    /PRINT=TWOTAIL NOSIG
    /STATISTICS DESCRIPTIVES
    /MISSING=PAIRWISE.

* Baseline group: Party = 0 (no party).

REGRESSION
    /DESCRIPTIVES MEAN STDDEV CORR SIG N
    /MISSING LISTWISE
    /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL
    /CRITERIA=PIN(.05) POUT(.10)
    /NOORIGIN
    /DEPENDENT F1
    /METHOD=ENTER Sex RAgeCat HHincome EduLevel CON LAB LD SNP GRE UKIP OTH.

REGRESSION
    /DESCRIPTIVES MEAN STDDEV CORR SIG N
    /MISSING LISTWISE
    /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL
    /CRITERIA=PIN(.05) POUT(.10)
    /NOORIGIN
    /DEPENDENT F2
    /METHOD=ENTER Sex RAgeCat HHincome EduLevel CON LAB LD SNP GRE UKIP OTH.

REGRESSION
    /DESCRIPTIVES MEAN STDDEV CORR SIG N
    /MISSING LISTWISE
    /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL
    /CRITERIA=PIN(.05) POUT(.10)
    /NOORIGIN
    /DEPENDENT F3
    /METHOD=ENTER Sex RAgeCat HHincome EduLevel CON LAB LD SNP GRE UKIP OTH.

* REGRESSION
    /DESCRIPTIVES MEAN STDDEV CORR SIG N
    /MISSING LISTWISE
    /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL
    /CRITERIA=PIN(.05) POUT(.10)
    /NOORIGIN
    /DEPENDENT F3
    /METHOD=ENTER Sex Rage HHincome EduLevel CON LAB LD SNP GRE UKIP OTH.

FREQUENCIES VARIABLES=carreduc carallow cartaxhi carenvdc TrfPb10u carnod2 speedlim CycDang TRFPB9U CCACar CCALowE
    /ORDER=ANALYSIS.

USE ALL.
COMPUTE filter_$1=(~MISSING(carreduc)).
VARIABLE LABELS filter_$1 '~MISSING(carreduc) (FILTER)'.
VALUE LABELS filter_$1 0 'Not Selected' 1 'Selected'.
FORMATS filter_$1 (f1.0).
FILTER BY filter_$1.
EXECUTE.

FREQUENCIES VARIABLES=Worldview
    /ORDER=ANALYSIS.

USE ALL.
COMPUTE filter_$2=(~MISSING(speedlim)).
VARIABLE LABELS filter_$2 '~MISSING(speedlim) (FILTER)'.
VALUE LABELS filter_$2 0 'Not Selected' 1 'Selected'.
FORMATS filter_$2 (f1.0).
FILTER BY filter_$2.
EXECUTE.

FREQUENCIES VARIABLES=Worldview
    /ORDER=ANALYSIS.

USE ALL.
COMPUTE filter_$3=(~MISSING(CCACar)).
VARIABLE LABELS filter_$3 '~MISSING(CCACar) (FILTER)'.
VALUE LABELS filter_$3 0 'Not Selected' 1 'Selected'.
FORMATS filter_$3 (f1.0).
FILTER BY filter_$3.
EXECUTE.

FREQUENCIES VARIABLES=Worldview
    /ORDER=ANALYSIS.

USE ALL.
SHOW N.


* Income for GLM.
RECODE HHincome (1 = 1) (2 = 2) (3 THRU 5 = 3) (6 THRU 8 = 4) (9 THRU 11 = 5) (12 THRU 14 = 6) (15 THRU 17 = 7) (18 THRU 20 = 8) INTO Income_G.
VARIABLE LABELS Income_G 'Houshold income'.
FORMATS Income_G(f1.0).

FREQUENCIES VARIABLES=Income_G
    /ORDER=ANALYSIS.

* Educational level for GLM.
COMPUTE EduLevel_G = 2.

RECODE EduLevel (1 = 1) (2 = 3) (3 = 3) (4 = 4) (5 = 4) (6 = 5) INTO EduLevel_G.
VARIABLE LABELS EduLevel_G 'Educational level'.
FORMATS EduLevel_G(f1.0).

FREQUENCIES VARIABLES=EduLevel_G
    /ORDER=ANALYSIS.

FREQUENCIES VARIABLES=Sex
    /ORDER=ANALYSIS.

FREQUENCIES VARIABLES=RAgeCat
    /ORDER=ANALYSIS.

FREQUENCIES VARIABLES=Party_G
    /ORDER=ANALYSIS.

UNIANOVA F1 BY Sex RAgeCat Income_G EduLevel_G Party_G
    /METHOD=SSTYPE(3)
    /INTERCEPT=INCLUDE
    /PRINT ETASQ
    /CRITERIA=ALPHA(.05)
    /DESIGN=Sex RAgeCat Income_G EduLevel_G Party_G
    Sex*RAgeCat Sex*Income_G Sex*EduLevel_G Sex*Party_G
    RAgeCat*Income_G RAgeCat*EduLevel_G RAgeCat*Party_G
    Income_G*EduLevel_G Income_G*Party_G
    EduLevel_G*Party_G.

UNIANOVA F2 BY Sex RAgeCat Income_G EduLevel_G Party_G
    /METHOD=SSTYPE(3)
    /INTERCEPT=INCLUDE
    /PRINT ETASQ
    /CRITERIA=ALPHA(.05)
    /DESIGN=Sex RAgeCat Income_G EduLevel_G Party_G
    Sex*RAgeCat Sex*Income_G Sex*EduLevel_G Sex*Party_G
    RAgeCat*Income_G RAgeCat*EduLevel_G RAgeCat*Party_G
    Income_G*EduLevel_G Income_G*Party_G
    EduLevel_G*Party_G.

UNIANOVA F3 BY Sex RAgeCat Income_G EduLevel_G Party_G
    /METHOD=SSTYPE(3)
    /INTERCEPT=INCLUDE
    /PRINT ETASQ
    /CRITERIA=ALPHA(.05)
    /DESIGN=Sex RAgeCat Income_G EduLevel_G Party_G
    Sex*RAgeCat Sex*Income_G Sex*EduLevel_G Sex*Party_G
    RAgeCat*Income_G RAgeCat*EduLevel_G RAgeCat*Party_G
    Income_G*EduLevel_G Income_G*Party_G
    EduLevel_G*Party_G.
