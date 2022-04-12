*READ ME:

*Notes:  
* Running this do-file on my computer with the university-provided stata
*timer command output was: 
*  1:   4216.63 /        1 =    4216.6290
*which means my run time is around 1 hour and 10 minutes.

****************************************************************************

timer on 1
*drops any non-household addresses:
 
keep if gq==1|gq==2
drop gq

*drops people not native to the US
keep if bpld<=5600

*drops age out of age range: 
keep if (age>=18&age<=45)

*drops individuals not in relationships: 
drop if coupletype==0

*spouse age fixing: 
drop if missing(age_sp)
*this automatically drops missing observations for all other spousal vars


*recode to only 3 categories + nicer labels: 
recode race (1=1) (2=2) (else=0)
label value race
label define race 0 "other" 1 "white" 2 "black"
label values race race

*hispanic dummy generation: 
*recode to two categories: hispanic and non hispanic + fixing labels accordingly: 
recode hispan (0=0) (else=1)
label values hispan
label define hispan 0 "non-hispanic" 1 "hispanic"
label values hispan hispan

*hcovany: health insurance dummy generation: 
recode hcovany (1=0) (2=1)
label values hcovany
label define hcovany 0 "no health insurance coverage" 1 "with health insurance coverage"
label values hcovany hcovany

* educd: recoding and summarizing years of education: 
drop if educd==1
*dont want not applicable education. 

recode educd (2/12=0) (14=1) (15=2) (16=3) (17=4) (22=5) (23=6) (25=7) (26=8) (30=9) (40=10) (50=11) (61=11) (63=12) (64=12) (65=13) (71=14) (81=14) (101=16) (114=17) (115=20) (116=24), gen(yearsEdu)
* 12 years of education= regular highschool diploma + GED or alternative credential + some college but less than 1 year 
* 13 years of education: some college, but less than 1 year 
* 14 years of education: 1 or more years of college credit, no degree+ associate's degree 
* 16 years of education: undergraduate diploma
* 17 years of education: masters degree
* 20 years of education: professional degree beyond a bachelor's degree 
* 24 years of education: PHD

*categorical education: 
recode educd (0/60=0 "Less than High School") (61/100=1 "HighSchool") (101=2 "Bachelor's Degree") (114=3 "Master's Degree") (115=4 "Professional Degree") (116=5 "PHD"), gen(highest_edu)

* educd_sp: recoding and summarizing years of education: 
recode educd_sp (2/12=0) (14=1) (15=2) (16=3) (17=4) (22=5) (23=6) (25=7) (26=8) (30=9) (40=10) (50=11) (61=11) (63=12) (64=12) (65=13) (71=14) (81=14) (101=16) (114=17) (115=20) (116=24), gen(yearsEdu_sp)

*categorical education:
recode educd_sp (0/60=0 "No education") (61/100=1 "HighSchool") (101=2 "Bachelor's Degree") (114=3 "Master's Degree") (115=4 "Professional Degree") (116=5 "PHD"), gen(highest_edu_sp)

*bpld_sp: drop non-native spouses: 
keep if bpld_sp<=5600 


*homemaker is defined as the spouse with lower income (lazy but best thing i got)
*we need to drop all breadwinners: 
drop if incwage>incwage_sp

*sex variable: 
recode sex (1=0 "male") (2=1 "female"), gen(female)
drop sex


*gen same sex couple designations: 
gen coupleDesignation=0
replace coupleDesignation=1 if ((coupletype==2|coupletype==4)&female==0)
replace coupleDesignation=2 if ((coupletype==2|coupletype==4)&female==1)
label define coupleDesignation 0 "Opposite-Sex Couple" 1 "Same-sex Male couple" 2 "Same sex Female Couple"
label values coupleDesignation coupleDesignation

*sexual orientation dummy:
gen SO=0
replace SO=1 if coupletype==2|coupletype==4
label define SO 0 "opposite sex couple" 1 "same-sex couple"
label values SO SO

*income from business and farm income: another sample exclusion: 
keep if incbus00==0
drop incbus00

*drop unwanted variables:
drop hispand bpl educ degfieldd occ2010 educd educd_sp coupletype raced


*in order to generate log incomes, i need to convert incwage=0 to incwage=1 
*(this is so the log exists):
replace incwage=1 if incwage==0
replace incwelfr=1 if incwelfr==0
replace incwage_sp=1 if incwage_sp==0
*a difference of one dollar won't make a huge difference to estimates.

*incinvst has negative values that do have information we need. the min val is -5700. so the entire var will be recentered: 
replace incinvst=incinvst+5701
*the lowest values will now have the same relationship it did to higher values, sans negative sign, enabling log transformation. 
*this impacts the interpretation of the intercept (which we dont care about) but (hopefully) not the slope parameter estimates. 

*generating log incomes for better coefficients:
gen logincwage=ln(incwage)
gen logincinvst=ln(incinvst)
gen logincwelfr=ln(incwelfr)
gen logincwagesp=ln(incwage_sp)

keep if marrno<=1
*drops people with previous marriages 
keep if marst==1 | marst==6
*drops any respondents who are divorced, widowed, separated. 

*sampling to reduce computation time:
set seed 1997 
*set seed so its reproducible
sample 200000 if coupleDesignation==0, count

*variable labelling: 
label variable logincwage "Log Respondent Income from Labour"
label variable logincinvst "Log Respondent Income from Investment"
label variable logincwagesp "Log Spouse Income from Labour"
label variable logincwelfr "Log Respondent Welfare Income"

label variable yearsEdu "Respondent Years of Education"
label variable yearsEdu_sp "Spouse Years of Education"
label variable age "Respondent Age"
label variable age_sp "Spouse Age"
label variable multyear "Year of Survey"
label variable hispan "Hispanic =1 if Hispanic"
label variable female "Sex =1 if female"





*descriptive statistics: 

summarize nchild logincwage logincwagesp logincinvst logincwelfr i.SO age age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.marst i.race i.hispan i.hcovany i.female
*for opposite sex couples (appendix):
summarize nchild logincwage logincwagesp logincinvst logincwelfr age age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.marst i.race i.hispan i.hcovany i.female if coupleDesignation==0
*for same sex couples Female (appendix):
summarize nchild logincwage logincwagesp logincinvst logincwelfr age age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.marst i.race i.hispan i.hcovany if coupleDesignation==2
*for same sex couples Male (appendix):
summarize nchild logincwage logincwagesp logincinvst logincwelfr age age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.marst i.race i.hispan i.hcovany if coupleDesignation==1

*graphically: 
graph pie if SO==0, over(nchild) plabel(1 percent) plabel(2 percent) plabel(3 percent) sort(nchild) title(Percentage of Respondents by Number of Children, size(10pt))  scheme(s1color) subtitle(Opposite-Sex Couples, size(5pt))
graph pie if SO==1, over(nchild) plabel(1 percent) plabel(2 percent) plabel(3 percent) sort(nchild) title(Percentage of Respondents by Number of Children, size(10pt))  scheme(s1color) subtitle(Same-Sex Couples, size(5pt)) allcategories

*regression for different sample subgroups: 
*note on margins: tobit is not linear. normal margins predict linearly. Need to adjust margins command

*************************************************************
*opposite sex couples margins and estimates store: 
************
quietly tobit nchild logincwage logincwagesp logincwelfr logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany i.state i.bpld i.bpld_sp female if SO==0, ll(0) vce(robust)
estimates store m1, title(Opposite-Sex Couples only)

*1) logincwage: 
quietly margins, predict(ystar(0,.))  at(logincwage=(0(1)13)) saving(LogIncwage_Margins_Opposite-Sex_Couples, replace)
*2) logincwagesp:
quietly margins, predict(ystar(0,.))  at(logincwagesp=(0(1)13)) saving(LogIncwageSP_Margins_Opposite-Sex_Couples, replace)
*3) education: 
quietly margins, predict(ystar(0,.)) at(yearsEdu=(0(1)24)) saving(yearsEdu_Margins_Opposite-Sex_Couples, replace)

**************************************************************
*same sex couples only: 
**************

*A: Female same sex couples: 
quietly tobit nchild logincwage logincwagesp logincwelfr logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany i.state i.bpld i.bpld_sp if coupleDesignation==2, ll(0) vce(robust)
estimates store m2, title(Female Same-sex Couples)

*1) logincwage
quietly margins, predict(ystar(0,.))  at(logincwage=(0(1)13)) saving(LogIncwage_Margins_FemaleSS_Couples, replace)
*2) logincwagesp:
quietly margins, predict(ystar(0,.))  at(logincwagesp=(0(1)13)) saving(LogIncwageSP_Margins_FemaleSS_Couples, replace)
*3) education: 
quietly margins, predict(ystar(0,.)) at(yearsEdu=(0(1)24)) saving(yearsEdu_Margins_FemaleSS_Couples, replace)

*B: Male same sex couples: 
quietly tobit nchild logincwage logincwagesp logincwelfr logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany i.state i.bpld i.bpld_sp if coupleDesignation==1, ll(0) vce(robust)
estimates store m3, title(Male Same-sex Couples)

*1) logincwage
quietly margins, predict(ystar(0,.))  at(logincwage=(0(1)13)) saving(LogIncwage_Margins_MaleSS_Couples, replace)
*2) logincwagesp:
quietly margins, predict(ystar(0,.))  at(logincwagesp=(0(1)13)) saving(LogIncwageSP_Margins_MaleSS_Couples, replace)
*3) education: 
quietly margins, predict(ystar(0,.)) at(yearsEdu=(0(1)24)) saving(yearsEdu_Margins_MaleSS_Couples, replace)

*************************************************************
*combomargins plot: 

*1. Logincwage: 
combomarginsplot LogIncwage_Margins_Opposite-Sex_Couples LogIncwage_Margins_FemaleSS_Couples LogIncwage_Margins_MaleSS_Couples , labels("Opposite Sex Couples" "Female-Same-Sex Couples" "Male Same-Sex Couples") noci title(Predictive Margins for Number of Children Censored) ytitle(Predicted number of children) scheme(s1color)

*2.: Logincwagesp: 
combomarginsplot LogIncwageSP_Margins_Opposite-Sex_Couples LogIncwageSP_Margins_FemaleSS_Couples LogIncwageSP_Margins_MaleSS_Couples , labels("Opposite Sex Couples" "Female Same-Sex Couples" "Male Same-Sex Couples") noci title(Predictive Margins for Number of Children Censored) ytitle(Predicted number of children) scheme(s1color)

*3.: education:
combomarginsplot yearsEdu_Margins_Opposite-Sex_Couples yearsEdu_Margins_FemaleSS_Couples yearsEdu_Margins_MaleSS_Couples, labels("Opposite Sex Couples" "Female Same-Sex Couples" "Male Same-Sex Couples") noci title(Predictive Margins for Number of Children Censored) ytitle(Predicted number of children) scheme(s1color)



**************************************************************

*regressing both same sex and opposite sex with sexual orientation dummy and interaction:

quietly tobit nchild SO##c.logincwage SO##c.logincwagesp SO##c.logincwelfr SO##c.logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany female i.state i.bpld i.bpld_sp, ll(0) vce(robust)
estimates store m4, title(Entire Sample)
*Difference between predicted censored no of children for same sex and opposite sex couples (logincwage): 
quietly margins, dydx(SO) at(logincwage=(0(1)13)) predict(ystar(0,.))
marginsplot,  title(Difference in Predicted Number of Children between Same Sex and Opposite Sex Couples, size(3) ) ytitle(Diff. bt. no. of children for SS and OS couples) scheme(s1color) yline(0) yscale(range(-0.6(0.1)-1.1) titlegap(5))
*Predicted censored no of children for same sex and opposite sex couples (logincwage): 
quietly margins, at(logincwage=(0(1)13) SO=(0 1)) predict(ystar(0,.))
marginsplot,  title(Predicted Number of Children for Same Sex and Opposite Sex Couples, size(3) ) ytitle(Number of children for SS and OS couples) scheme(s1color) 

*Difference between predicted censored no of children for same sex and opposite sex couples (logincwageSP): 
quietly margins, dydx(SO) at(logincwagesp=(0(1)13)) predict(ystar(0,.))
marginsplot,  title(Difference in Predicted Number of Children between Same Sex and Opposite Sex Couples, size(3) ) ytitle(Diff. bt. no. of children for SS and OS couples) scheme(s1color)
*Predicted censored no of children for same sex and opposite sex couples (logincwageSP): 
quietly margins, at(logincwagesp=(0(1)13) SO=(0 1)) predict(ystar(0,.))
marginsplot,  title(Predicted Number of Children for Same Sex and Opposite Sex Couples, size(3) ) ytitle(Number of children for SS and OS couples) scheme(s1color) 



estout m1 m2 m3 m4, cells(b(star fmt(%9.3f)) p(par fmt(%9.3f)))  label nobaselevels stats(N p r2_p, fmt(%14.3f)) varwidth(50) title("Regression Results") legend note("p-values in parentheses. Reported stats are: number of observations, p-value for F-test of overall significance, and Pseudo-R2" and "Robust Standard Errors Used") 


*Instrumental variable regression section: 
quietly reg logincwage ib(0).highest_edu yearsEdu i.degfield
predict logincwagehat, xb
quietly tobit nchild i.SO##c.logincwagehat  i.SO##c.logincwagesp i.SO##c.logincwelfr i.SO##c.logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp  yearsEdu_sp  i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany female i.state i.bpld i.bpld_sp, ll(0) vce(robust)
estimates store m5, title(IV tobit model)
quietly margins, dydx(SO) at(logincwagehat=(0(1)13)) predict(ystar(0,.))
marginsplot,  title(Difference in Predicted Number of Children between Same Sex and Opposite Sex Couples, size(3) ) ytitle(Diff. bt. no. of children for SS and OS couples) scheme(s1color) yline(0) yscale(range(-0.6(0.1)-1.1) titlegap(5))
estout  m4 m5, cells(b(star fmt(%9.3f)) p(par fmt(%9.3f)))  label nobaselevels stats(N p r2_p, fmt(%14.3f)) varwidth(50) title("Regression Results") legend note("p-values in parentheses. Reported stats are: number of observations, p-value for F-test of overall significance, and Pseudo-R2" and "Robust Standard Errors Used")
quietly margins, at(logincwagehat=(0(1)13) SO=(0 1)) predict(ystar(0,.))
marginsplot,  title(Predicted Number of Children for Same Sex and Opposite Sex Couples, size(3) ) ytitle(Number of children for SS and OS couples) scheme(s1color) xtitle(Predicted logged respondent income)
*Difference between predicted censored no of children for same sex and opposite sex couples (logincwageSP): 
quietly margins, dydx(SO) at(logincwagesp=(0(1)13)) predict(ystar(0,.))
marginsplot,  title(Difference in Predicted Number of Children between Same Sex and Opposite Sex Couples, size(3) ) ytitle(Diff. bt. no. of children for SS and OS couples) scheme(s1color)
*Predicted censored no of children for same sex and opposite sex couples (logincwageSP): 
quietly margins, at(logincwagesp=(0(1)13) SO=(0 1)) predict(ystar(0,.))
marginsplot,  title(Predicted Number of Children for Same Sex and Opposite Sex Couples, size(3) ) ytitle(Number of children for SS and OS couples) scheme(s1color) 


*durbin-wu hausman test sans robust SE: 
*quietly ivtobit nchild (logincwage = ib(0).highest_edu yearsEdu i.degfield)  i.SO##c.logincwagesp i.SO##c.logincwelfr i.SO##c.logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp  yearsEdu_sp  i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany female i.state i.bpld i.bpld_sp, ll(0)
*estimates store m6
*quietly tobit nchild SO##c.logincwage SO##c.logincwagesp SO##c.logincwelfr SO##c.logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany female i.state i.bpld i.bpld_sp, ll(0)
*estimates store m7
*hausman m6 m7, constant

timer off 1
timer list

*additional things for ppt (ignore me) : 
*scatter nchild logincwage, yscale(range(-2 10)) ylabel(-2(2)10) scheme(s1color) title(Number of Children at Each Income Level)
*quietly tobit nchild SO##c.logincwage SO##c.logincwagesp SO##c.logincwelfr SO##c.logincinvst age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp i.highest_edu i.highest_edu_sp i.multyear ib(1).marst ib(1).race hispan i.hcovany female i.state i.bpld i.bpld_sp, ll(0) vce(robust)
*predict pnchild, xb
*scatter pnchild logincwage, yscale(range(-10 10)) ylabel(-10(2)10) scheme(s1color) title(Fitted Number of Children at Each Income Level) yline(0) ytitle(Predicted Number of Children)





