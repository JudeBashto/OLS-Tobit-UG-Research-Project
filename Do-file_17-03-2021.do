

*drops any non-household addresses: 
tab gq, missing
tab gq, nolabel
keep if gq==1|gq==2
tab gq
drop gq

*drops people not native to the US
tab bpld, missing
tab bpld, nolabel
count if missing(bpld)
keep if bpld<=5600

*drops age out of age range: 
summarize age
count if missing(age)
keep if (age>=18&age<=45)

*drops individuals not in relationships: 
tab coupletype, missing
tab coupletype, nolabel
drop if coupletype==0
count if missing(coupletype)

*spouse age fixing: 
summarize age_sp
count if missing(age_sp)
drop if missing(age_sp)
*this automatically drops missing observations for all other spousal vars

*marital status summaries: 
tab marst, missing
tab marst, nolabel

*times married summaries: 
tab marrno, missing
tab marrno, nolabel
summarize marrno

*race summaries: 
tab race, missing
tab race, nolabel
*recode to only 3 categories + nicer labels: 
recode race (1=1) (2=2) (else=0)
label value race
label define race 0 "other" 1 "white" 2 "black"
label values race race

*hispanic dummy generation: 
tab hispan, missing
tab hispan, nolabel
*recode to two categories: hispanic and non hispanic + fixing labels accordingly: 
recode hispan (0=0) (else=1)
label values hispan
label define hispan 0 "non-hispanic" 1 "hispanic"
label values hispan hispan

*hcovany: health insurance dummy generation: 
tab hcovany, missing
tab hcovany, nolabel
recode hcovany (1=0) (2=1)
label values hcovany
label define hcovany 0 "no health insurance coverage" 1 "with health insurance coverage"
label values hcovany hcovany

* educd: recoding and summarizing years of education: 
tab educd, missing
tab educd, nolabel
recode educd (2/11=0) (12=0) (14=1) (15=2) (16=3) (17=4) (22=5) (23=6) (25=7) (26=8) (30=9) (40=10) (50=11) (61=11) (63=12) (64=12) (65=13) (71=14) (81=15) (101=16) (114=18) (115=22) (116=30), gen(yearsEdu)
tab yearsEdu
count if missing(educd)


*fixing family total income: 
summarize ftotinc
count if ftotinc<0
count if ftotinc<incwage
*we drop those: 
drop if ftotinc<incwage

*time to generate "other income" variable (specified in empirical model):
count if missing(ftotinc)
summarize ftotinc
count if ftotinc<0
count if ftotinc<incwage
*we drop those: 
drop if ftotinc<incwage
gen IncO= ftotinc-incwage
summarize IncO

* educd_sp: recoding and summarizing years of education: 
tab educd_sp, missing
tab educd_sp, nolabel
recode educd_sp (2/11=0) (12=0) (14=1) (15=2) (16=3) (17=4) (22=5) (23=6) (25=7) (26=8) (30=9) (40=10) (50=11) (61=11) (63=12) (64=12) (65=13) (71=14) (81=15) (101=16) (114=18) (115=22) (116=30), gen(yearsEdu_sp)
tab yearsEdu_sp
count if missing(educd_sp)

*bpld_sp: summarizing: 
tab bpld_sp, missing
tab bpld_sp, nolabel
count if missing(bpld_sp)
keep if bpld_sp<=5600 

*year: 
tab multyear
count if missing(multyear)

*region: 
tab region, missing
tab region, nolabel
recode region (11/12=0 "Northeast Region") (21/22=1 "Midwest Region") (31/33=2 "South Region") (41/42=3 "West Region"), gen(region1)
drop region
rename region1 region


*homemaker is defined as the spouse with lower income (lazy but best thing i got)
*we need to drop all breadwinners: 
drop if incwage>incwage_sp

*sex variable: 
tab sex, nolabel
recode sex (1=0 "male") (2=1 "female"), gen(sex1)
drop sex
rename sex1 sex

*gen same sex couple designations: 
gen coupleDesignation=0
replace coupleDesignation=1 if ((coupletype==2|coupletype==4)&sex==0)
replace coupleDesignation=2 if ((coupletype==2|coupletype==4)&sex==1)
label define coupleDesignation 0 "Opposite-Sex Couple" 1 "Same-sex Male couple" 2 "Same sex Female Couple"
label values coupleDesignation coupleDesignation

*sexual orientation dummy:
gen SO=0
replace SO=1 if coupletype==2|coupletype==4
label define SO 0 "opposite sex couple" 1 "same-sex couple"
label values SO SO

*number of children: 
tab nchild, missing
tab nchild, nolabel

*incwage: wage income : 
summarize incwage
count if incwage==999999
count if incwage==999998
*code book says above codes are for not applicable/notavailable. All good.

*drop unwanted variables:
drop hispand bpl educ degfieldd occ2010 ftotinc incwage_sp educd educd_sp coupletype raced


*in order to generate log incomes, i need to convert incwage=0 to incwage=1 
*(this is so the log exists):
replace incwage=1 if incwage==0
replace IncO=1 if IncO==0

*generating log incomes for better coefficients:
rename incwage incwagenum
gen incwage=ln(incwagenum)
rename IncO IncOnum
gen IncO=ln(IncOnum)

*sampling to reduce computation time:
set seed 1997 
*set seed so its reproducible
sample 200000 if coupleDesignation==0, count

*variable labelling: 
label variable incwage "Homemaker Income from Labour"
label variable IncO "Other non-earned Income"
label variable yearsEdu "Homemaker Years of Education"
label variable yearsEdu_sp "Breadwinner Years of Education"
label variable age "Homemaker Age"
label variable age_sp "Breadwinner Age"
label variable multyear "Year of Survey"
label variable hispan "Hispanic =1 if Hispanic"
label variable sex "Sex =1 if female"





*descriptive statistics: 

summarize nchild incwage IncO i.SO age age_sp yearsEdu yearsEdu_sp multyear marrno i.marst i.race i.hispan i.hcovany i.sex i.region


*regression for different sample subgroups: 
*note on margins: tobit is not linear. normal margins predict linearly. Need to adjust margins command


*opposite sex couples margins and estimates store: 
quietly tobit nchild incwage IncO age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp multyear marrno i.marst i.race hispan i.hcovany sex i.region i.bpld i.bpld_sp if coupleDesignation==0, ll(0)
estimates store m1, title(Opposite-Sex Couples only)
quietly margins, predict(e(0,.))  at(incwage=(0(1)13)) saving(Incwage_Margins_Opposite-Sex_Couples_only, replace)
quietly margins, predict(e(0,.))  at(IncO=(0(1)14)) saving(IncO_Margins_Opposite_Sex_Couples_only, replace)

*same sex couples- male only: 
quietly tobit nchild incwage IncO age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp multyear marrno i.marst i.race hispan i.hcovany sex i.region i.bpld i.bpld_sp if coupleDesignation==1, ll(0)
estimates store m2, title(Same-sex Male Couples)
quietly margins, predict(e(0,.))  at(incwage=(0(1)13)) saving(Incwage_Margins_Same-Sex_Male_Couples_only, replace)
quietly margins, predict(e(0,.))  at(IncO=(0(1)14)) saving(IncO_Margins_Same_Sex_Male_Couples_only, replace)

*same sex couples-female only: 
quietly tobit nchild incwage IncO age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp multyear marrno i.marst i.race hispan i.hcovany sex i.region i.bpld i.bpld_sp if coupleDesignation==2, ll(0)
estimates store m3, title(Same-sex Female Couples)
quietly margins, predict(e(0,.))  at(incwage=(0(1)13)) saving(Incwage_Margins_Same-Sex_Female_Couples_only, replace)
quietly margins, predict(e(0,.))  at(IncO=(0(1)14)) saving(IncO_Margins_Same_Sex_Female_Couples_only, replace)

*combomarginsplot for incwage: 
combomarginsplot Incwage_Margins_Opposite-Sex_Couples_only Incwage_Margins_Same-Sex_Male_Couples_only Incwage_Margins_Same-Sex_Female_Couples_only, labels("Opposite Sex Couples" "Same-Sex Male" "Same-Sex Female") noci
*combomarginsplot for years of education: 
combomarginsplot IncO_Margins_Opposite_Sex_Couples_only IncO_Margins_Same_Sex_Male_Couples_only IncO_Margins_Same_Sex_Female_Couples_only, labels("Opposite Sex Couples" "Same-Sex Male" "Same-Sex Female") noci

*regressing both same sex and opposite sex with sexual orientation dummy and interaction
quietly tobit nchild SO##c.incwage SO##c.IncO age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp multyear marrno i.marst i.race hispan i.hcovany sex i.region i.bpld i.bpld_sp
estimates store m4, title(Regressing Entire Sample)


estout m1 m2 m3 m4, cells(b(star fmt(%9.3f)) t(par))  label nobaselevels stats(N) varwidth(50) title("Regression Results for the Reduced Form Model for All Couples") legend note("t-statistic in parentheses")

*further: combomarginsplot for same sex vs all opposite sex: 
quietly tobit nchild incwage IncO age c.age#c.age age_sp c.age_sp#c.age_sp yearsEdu yearsEdu_sp multyear marrno i.marst i.race hispan i.hcovany sex i.region i.bpld i.bpld_sp if (coupleDesignation==1|coupleDesignation==2), ll(0)
estimates store m2, title(Same-sex All Couples)
quietly margins, predict(e(0,.))  at(incwage=(0(1)13)) saving(Incwage_Margins_Same-Sex_All, replace)
quietly margins, predict(e(0,.))  at(IncO=(0(1)14)) saving(IncO_Margins_Same_Sex_All, replace)
*combomarginsplot for incwage: 
combomarginsplot Incwage_Margins_Opposite-Sex_Couples_only Incwage_Margins_Same-Sex_All, labels("Opposite Sex Couples" "Same-Sex All") noci
*combomarginsplot for years of education: 
combomarginsplot IncO_Margins_Opposite_Sex_Couples_only IncO_Margins_Same_Sex_All, labels("Opposite Sex Couples" "Same-Sex All") noci









