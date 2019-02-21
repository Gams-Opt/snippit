$if not set DIM $set DIM 1000
$ife mod(%DIM%,2)=0 $eval DIM %DIM%+1
set
                t                     "time 96 moments"                  /1*96/
                tt(t)                                                    /1*96/
                scenes                "scene for each probability"       /1*%DIM%/

                alias(scenes,allscene);
set             scene(scenes);
                scene(scenes) =yes;
set
*----------------level1 for root;level2 for inflow;level3 for price.
    level                   /level1*level3/
    stage(scenes,level)     'stage mapping'
    ancestor(scenes,scenes) 'ancestor matrix'
    leaf(scenes)            'leaf nodes';
    ancestor(scenes,scenes)=no;
* Assign stage mapping and leaf nodes
stage('1','level1') = yes;
*----------------level2 for inflow;
stage(scenes,'level2') = ord(scenes)>1 and ord(scenes)<= %DIM%/2+1;
*----------------level3 for price;
stage(scenes,'level3') = ord(scenes)>%DIM%/2+1;
leaf(scenes) = stage(scenes,'level3');
*Build ancenstor relations inflow is the ancestor of price
*----------------scenes in level1 is the ancestor of level2
ancestor(scenes,'1')$stage(scenes,'level2') = yes;
*----------------scenes in level2 is the ancestor of level3
ancestor(scenes,scenes-card(leaf))$stage(scenes,'level3') = yes;
display stage,leaf,ancestor;
parameter    prob(scenes)  'node probabilities';
prob(scenes) = 1/card(leaf);
*---------------------------load inflow data----------------------------------------------------
parameter mean(t),dev(t),nodes(t,scenes);
parameter p_water_DA(t),p_water_RT(t),price_water_RT(t,scenes),penalty_water_RT(t,scenes);
parameter dev_price(t);
$gdxin in.gdx
$load mean
$load dev
$load p_water_DA
$load p_water_RT
$gdxin
*----------------------------generate inflow scenes---------------------------------------------
* First stage infl_fcast p_water_RT(t),p_wind_DA(t),p_wind_RT(t),penalty_wind(t),penalty_water(t)
nodes(t,'1') = 1;
prob('1')  = 1;

* Second stage - inflow is uniformly distributed in [0,1]
nodes(t,scenes)$stage(scenes,'level2')=normal(MEAN(t),DEV(t));
*---------------------------load wind and price data--------------------------------------------
dev_price(t)=0.2*p_water_RT(t);
nodes(t,scenes)$stage(scenes,'level3')=normal(p_water_RT(t),dev_price(t));
*display nodes;
*price(n)$stage(n,'t2') = uniform(0,1);

* Initialize ScenRed2
$set sr2prefix 2.16
$libInclude scenred2

File fopts 'Scenred option file' / 'sr2%sr2prefix%.opt' /;
putClose fopts 'order           1'
             / 'section   epsilon'
             / ' 2           0.05'
             / ' 3           0.05'
             / 'end';

* Scenred2 method choice
ScenRedParms('construction_method') = 2;
ScenRedParms('reduction_method'   ) = 2;
ScenRedParms('sroption'           ) = 1;
ScenRedParms('visual_red'         ) = 1;
ScenRedParms('out_scen'           ) = 0;
ScenRedParms('out_tree'           ) = 0;
Set anc_noloss(scenes,scenes), prob_noloss(t);
* Scenred2 call
$libInclude runscenred2 %sr2prefix% tree_con scenes ancestor prob anc_noloss prob_noloss nodes
display anc_noloss,nodes;
parameter infl(t,scenes),pri(t,scenes);
infl(t,scenes)$stage(scenes,'level2')=nodes(t,scenes);
pri(t,scenes)$stage(scenes,'level3')=nodes(t,scenes);
*display nodes;
execute_unload 'sr2.16_out.gdx',infl,pri;
