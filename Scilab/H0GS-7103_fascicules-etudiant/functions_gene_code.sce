MY_TRUE=%t; // merci scilab, compatibilite arriere de isfield...
function output=compute_c_filter(F_w,params)
// first convert F_w to list if necessary
  if (typeof(F_w)~="list") then
    tmp=list();
    tmp(1)=F_w;
    F_w=tmp;
  end
//--------------------------------------------------
// then verify if F_w is in the w plane, and convert it if necessary
//--------------------------------------------------
  vn=my_varn(F_w); // the name of var in polynomial
  w=poly(0,"w");
  if (vn=="z") then
    z_de_w=(1+w)/(1-w);
    F_w=hornerij(F_w,z_de_w,"hd") ;
  end
  if (vn=="z_1") then
    z_1_de_w=(1-w)/(1+w);
    F_w=hornerij(F_w,z_1_de_w,"hd") ;
  end
//--------------------------------------------------
// now set defaults parameters if necessary
//--------------------------------------------------
   [lhs,rhs]=argn(0);
   if (rhs<2) then
   // create default structure
     params=struct("file_name","toto");
   end
// get default value of fields if not given by unexperimented user
   if isfield(params,"file_name")~=MY_TRUE then
     params.file_name="toto"; // ne perdons pas les bonnes habitudes...
   end
   if isfield(params,"name_filter")~=MY_TRUE then
     params.name_filter="Fz";
   end
   if isfield(params,"switch_structure")~=MY_TRUE then
     params.switch_structure="cascade-to-paralell";//"cascade","paralell","cascade-to-paralell"
   end
   if isfield(params,"switch_operateur")~=MY_TRUE then
     params.switch_operateur="z_1"; // "x" ou "z_1"
   end
   if params.switch_operateur=="z" then
     params.switch_operateur="z_1"; 
   end
   if params.switch_operateur=="x" then
     if isfield(params,"switch_vx_ideal")~=MY_TRUE then
       params.switch_vx_ideal=%f;// works only for x operator
     end
   end 
   if isfield(params,"switch_round")~=MY_TRUE then
     params.switch_round="floor"; // "floor","round", "fix","round only at key points"
   end
   if isfield(params,"switch_saturate")~=MY_TRUE then
     params.switch_saturate="no saturate"; // "saturate","no saturate"
   end
   if isfield(params,"over_scale")~=MY_TRUE then
   // you can overscale input by this factor comparing to analysis
   // <=> first lbd=first lbd . overscale
   //     last  lbd=last lbd/over_scale
   // take care, you can generate overflow if youy use it!...
     params.over_scale=1;
   end
   if isfield(params,"i_norm_scaling")~=MY_TRUE then
     params.i_norm_scaling=%inf; // 1, 2 or %inf
   end
   if isfield(params,"i_norm_analysis")~=MY_TRUE then
     params.i_norm_analysis=2;// 1, 2 or %inf
   end
   if isfield(params,"NBECHS_NORM")~=MY_TRUE then
   // Nb sample for norm 1,norm 2 and norm inf computation
     params.NBECHS_NORM=compute_NBECH_Fw(F_w);
     MAX_NBECHS_NORM=1000000;
     if (params.NBECHS_NORM>MAX_NBECHS_NORM) then
        disp("WARNING in function functions_gene_code->compute_c_filter");
        disp("  theoretical NBECH for norm computation is "+string(params.NBECHS_NORM));
        disp("  automatically limited to "+string(MAX_NBECHS_NORM));
        params.NBECHS_NORM=MAX_NBECHS_NORM;
     end
   end
   NBECHS_NORM=params.NBECHS_NORM;
   if isfield(params,"NB_BITS")~=MY_TRUE then
     params.NB_BITS=16;
   end
   if isfield(params,"verbose")~=MY_TRUE then
     params.verbose=%t; // %t for verbose or %f for silent computation
   end
   if isfield(params,"switch_quantifie")~=MY_TRUE then
     params.switch_quantifie=%t;
   end
   if isfield(params,"switch_form")~=MY_TRUE then
     params.switch_form="df2";// "df1","df1t","df2","df2t","state-space"
   end
   if params.switch_form=="state-space" then
     if isfield(params,"switch_ss")~=MY_TRUE then
       params.switch_ss="hwang";//"hwang", 'normal' type of state-space representation used
     end
   end
   if isfield(params,"type_allpass")~=MY_TRUE then
     params.type_allpass='M'; // 'J','M' or 'Q' , but unused for instance
   end
   if isfield(params,"switch_sort")~=MY_TRUE then
     params.switch_sort=[]; //[],"well damped first","bad damped first"
   end
   if isfield(params,"switch_use_power_of_2")~=MY_TRUE then
     params.switch_use_power_of_2=%t; // use scaling in integer power of 2
   end

   w=poly(0,'w');
   x=poly(0,"x");
   x_1=poly(0,"x_1");
   x_de_x_1=1/x_1;
   moins_w=-w;
   z=poly(0,'z');
   w_de_z=(z-1)/(z+1);
   z_de_w=(1+w)/(1-w);
   i_inf=0;infos_=list();
     i_inf=i_inf+1;infos_(i_inf)=("-----analysis of filter :"+params.name_filter+"-------------");
   if (params.switch_form=="state-space")&(params.switch_operateur=="x")&(params.switch_ss~="hwang") then
     disp(" WARNING");
     disp("  state-space forms of type:"+params.switch_form+" can only be used with z_1 operator");
     disp("  automatically changing params.switch_operateur to z_1");
     params.switch_operateur="z_1";
   end
   i_inf=i_inf+1;infos_(i_inf)=("op="+params.switch_operateur+",form :"+params.switch_form+" programmed as "+params.switch_structure);
   i_inf=i_inf+1;infos_(i_inf)=("scaling norm="+string(params.i_norm_scaling)+",analysis norm="+string(params.i_norm_analysis));
// creation de output_, de type structure contenant le champ infos
  output_=struct("infos",infos_);
// creation des autres champs de sortie
  output_.F_w=F_w;
  output_.F_z=hornerij(output_.F_w,w_de_z,"hd");
  if (params.switch_structure=="cascade") then
    output_.F_z_casc_ideal=output_.F_z;
  elseif (params.switch_structure=="cascade-to-paralell") then
    output_.F_z_casc_ideal=output_.F_z;
    output_.F_w_casc_ideal=F_w;
    [K_inf,output_.F_z]=my__parfrac(output_.F_z);
    l=list();
    l(1)=real(K_inf);
    output_.F_z=lstcat(l,output_.F_z);
    output_.F_w=hornerij(output_.F_z,z_de_w,"hd");
    osm=simp_mode();
    simp_mode(%f);
    for i=1:length(output_.F_w),
      output_.F_w(i)=real(numer(output_.F_w(i)))/real(denom(output_.F_w(i)));
      output_.F_z(i)=real(numer(output_.F_z(i)))/real(denom(output_.F_z(i)));
    end 
    simp_mode(osm);
  elseif (params.switch_structure=="paralell") then
    output_.F_z=hornerij(F_w,w_de_z,"hd");
    output_.F_w=hornerij(output_.F_z,z_de_w,"hd");
  else
    error("bad params.switch_structure:"+params.switch_structure);
  end
  if (params.switch_sort~=[]) then
    [output_.F_w,output_.infos_roots]=sort_filter(output_.F_w,params.switch_sort);
  end
  output_.params=params;
  lambda_glob=1; // scaling factor
//---------------------------------------------
// compute direct form transferts
//---------------------------------------------
  NFES_z=list();
  DFES_z=list();
  if (params.switch_operateur=="z_1") then
    b0x_de_z=1;
    a0x_de_z=0;
 // Fq(z)=(b0Fqz+b1Fqz.z)/(a0Fqz+a1Fqz.z)=(z-1)/(z-(1-2-Lop))
    b1Fqz=0;b0Fqz=0;
    a1Fqz=0;a0Fqz=1;
    x_de_w=(1-w)/(1+w);
    w_de_x=horner11_inv(x_de_w,"x");
  end
  F_x=list();
  F_xq=list();
  v_x=list();
  F_z_qtf=list();
  cel_qtf=list(); // structures defining quantified cels
  for i_f=1:length(output_.F_w),
  // ieme cel = structure with name cel(indice of cel)
     cel_i=struct("name","cel("+string(i_f)+")");
     Fwi=output_.F_w(i_f);
     Nwi=numer(Fwi);
     Dwi=denom(Fwi);
     pw=roots(Dwi);
     b0w=coeff(Nwi,0);
     b1w=coeff(Nwi,1);
     b2w=coeff(Nwi,2);
     a0w=coeff(Dwi,0);
     a1w=coeff(Dwi,1);
     a2w=coeff(Dwi,2);
  // compute operator x if necessary 
     vx_i=1;
     if params.switch_operateur=="x" then
        vn=abs(pw(1));
        vx_i=compute_vx(vn,params.switch_vx_ideal);
        if (vx_i<=1) then
        // low frequency gain normalised to 1
          x_de_w=(1-w)/(1+w/vx_i);
        else
        // high frequency gain normalised to -1
          x_de_w=(1-w)/(vx_i+w);
        end
        w_de_x=horner11_inv(x_de_w,"x");
        X=x;
        w_de_X=w_de_x;
        X_de_z=hornerij(x_de_w,w_de_z);
     // X(z)=b0Fxz/(z+a0Fxz)
        d1_X=coeff(denom(X_de_z),1);
        X_de_z=(numer(X_de_z)/d1_X)/(denom(X_de_z)/d1_X);
        b0x_de_z=coeff(numer(X_de_z),0);
        a0x_de_z=coeff(denom(X_de_z),0);
     // Fq(z)=(b0Fqz+b1Fqz.z)/(a0Fqz+a1Fqz.z)=(z-1)/(z+a0x_de_z)
        b1Fqz=1;b0Fqz=sign(a0x_de_z);
        a1Fqz=1;a0Fqz=a0x_de_z;
     //   b1Fqz=0;b0Fqz=0;a1Fqz=0;a0Fqz=1;
     end // if params.switch_operateur=="x"
   // compute transfer function in X, works in x and in z_1
     [b0X,b1X,b2X,a0X,a1X,a2X]=clc_Fx_de_Fw(b0w,b1w,b2w,a0w,a1w,a2w..
       ,b0x_de_z,a0x_de_z);
     b0X=b0X/a0X;
     b1X=b1X/a0X;
     b2X=b2X/a0X;
     a1X=a1X/a0X;
     a2X=a2X/a0X;
     a0X=1;
     osm=simp_mode();
     simp_mode(%f);
     F_x(i_f)=(b0X+b1X*x+b2X*x^2)/(1+a1X*x+a2X*x^2);
     Nxi=numer(F_x(i_f));
     Dxi=denom(F_x(i_f));
     simp_mode(osm);
   // now compute filter implementation in x
     if (params.switch_form=="state-space") then
     // state-space form
       Fxi=hornerij(Fwi,w_de_x,"ld");
       Fx_1i=hornerij(Fxi,x_de_x_1,"hd"); 
       Nx_1i=numer(Fx_1i);
       Dx_1i=denom(Fx_1i);
       degre_i=degree(Dx_1i);
       if (degre_i>0) then
         sys_abcdi=syslin(1,Nx_1i,Dx_1i);
         sys_abcdi=tf2ss(sys_abcdi); 
         if params.switch_ss=="hwang" then
           sys_ssi=hwang_optimal_ss(sys_abcdi,a0x_de_z);
         elseif params.switch_ss=='normal' then
           sys_ssi=normal_optimal_ss(sys_abcdi);
         else
           error("sys_ss="+params.switch_ss+" not implemented");
         end
         cel_i=get_scaled_ss(sys_ssi,params.NB_BITS);
         if (params.switch_quantifie==%t) then
           sys_ssi=cel_i.sys_ss_q;
         end
         cel_i.a0x_de_z=a0x_de_z;
         cel_i.sys_ssx_1=sys_ssi;
         [NFES_zi,DFES_zi,NFES_wi,DFES_wi,NFES_z_1i,DFES_z_1i]=clc_ss(lambda_glob,..
             sys_ssi.A,sys_ssi.B,sys_ssi.C,sys_ssi.D,cel_i.a0x_de_z);
        else
       // degree=0 => no states, just a pure gain, program it as you want
         cel_i=get_scaled_direct_form(b0X,"df2",params.NB_BITS);
         cel_i.b0x_de_z=1;// useful for code generation
         cel_i.a0x_de_z=0;
         if (params.switch_quantifie==%t) then
           b0X=coeff(numer(cel_i.Fx_q),0);
         end
         [NFES_zi,DFES_zi,NFES_wi,DFES_wi,NFES_z_1i,DFES_z_1i]=clc_direct_form("df2",lambda_glob,..
           b0X,0,0,0,0,..
           0,0,1,0,..
           cel_i.b0x_de_z,cel_i.a0x_de_z);
         NFES_z(i_f)=NFES_zi;
         DFES_z(i_f)=DFES_zi;
       end // end of degree 0
     // end of state-space forms
     else
     // df1,df1t,df2,df2t forms
       osm=simp_mode();
       simp_mode(%f);
       F_x(i_f)=(b0X+b1X*x+b2X*x^2)/(1+a1X*x+a2X*x^2);
       F_xi=(b0X+b1X*x+b2X*x^2)/(1+a1X*x+a2X*x^2);
       cel_i=get_scaled_direct_form(F_xi,params.switch_form,params.NB_BITS);
       ci=cel_i;
       ci.b0x_de_z=b0x_de_z;// useful for code generation
       ci.a0x_de_z=a0x_de_z;
       cel_i=ci;
       if (params.switch_quantifie==%t) then
         F_xq(i_f)=cel_i.Fx_q;
       else
         F_xq(i_f)=F_x(i_f);
       end
       b0X=coeff(numer(F_xq(i_f)),0);
       b1X=coeff(numer(F_xq(i_f)),1);
       b2X=coeff(numer(F_xq(i_f)),2);
       a0X=coeff(denom(F_xq(i_f)),0);
       a1X=coeff(denom(F_xq(i_f)),1);
       a2X=coeff(denom(F_xq(i_f)),2);
       v_x(i_f)=vx_i;
       simp_mode(osm);
       [NFES_zi,DFES_zi,NFES_wi,DFES_wi,NFES_z_1i,DFES_z_1i]=clc_direct_form(params.switch_form,lambda_glob,..
         b0X,b1X,b2X,a1X,a2X,..
         b0Fqz,b1Fqz,a0Fqz,a1Fqz,..
         b0x_de_z,a0x_de_z);
     end
     NFES_z(i_f)=NFES_zi;
     DFES_z(i_f)=DFES_zi;
     osm=simp_mode();
     simp_mode(%f);
     cel_i.NFES_z=NFES_zi;
     cel_i.DFES_z=DFES_zi;
     cel_i.F_z_qtf=NFES_zi(1)(1)/DFES_zi(1)(1);
     F_z_qtf(i_f)=NFES_zi(1)(1)/DFES_zi(1)(1);
     simp_mode(osm);
     cel_qtf(i_f)=cel_i;
  end
  output_.F_z_qtf=F_z_qtf;
  if (length(cel_qtf)==1) then
  // scilab, or unfixed, bug !...
  //  if cel_qtf has only one element
  //  then scilab is unable to display output
  // so in this case add another element to cel_qtf
  // i've not found another way to solve the problem
    cel_qtf(length(cel_qtf)+1)=[];
  end
  output_.cel_qtf=cel_qtf;
  output_.NB_CELS=length(output_.F_w);
//-----------------------------------------------------------
// analyse des caracteristiques
//-----------------------------------------------------------

  params=output_.params;
  params.is_paralell=strindex(params.switch_structure,"paralell")>0==%t;
  if (params.is_paralell) then
    type_Fq="paralell";
  else
    type_Fq="cascade";
  end
  output_.type_of_F_z_qtf=type_Fq;
  norme_F_1=norme_Fz(F_z_qtf,type_Fq,1,NBECHS_NORM);
  norme_F_2=norme_Fz(F_z_qtf,type_Fq,2,NBECHS_NORM);
  norme_F_Hinf=norme_Fz(F_z_qtf,type_Fq,%inf,NBECHS_NORM);
  max_e=2^(params.NB_BITS-1);
  max_val_eff_e=max_e; // suppose egal au maximum de l'entree dans le pire des cas
  ecart_type_e=(2*max_e)*sqrt(1/12); // ecart-type de e, si bruit blanc
  output_levels.max_module_s=norme_F_1*max_e;
  output_levels.max_val_eff_s=norme_F_Hinf*max_val_eff_e;
  output_levels.ecart_type_s=norme_F_2*ecart_type_e;
  output_.output_levels=output_levels;
  output_.norme1_Fz_qtf=norme_F_1;
  output_.norme2_Fz_qtf=norme_F_2;
  output_.normeHinf_Fz_qtf=norme_F_Hinf;
  output_.params=params;
  if (params.is_paralell==%f) then
    [output_.lambda,output_.max_x_e,output_.norm_sb]=scale_cels(NFES_z,DFES_z,params.NBECHS_NORM,params.i_norm_scaling,params.i_norm_analysis,params.switch_use_power_of_2);
  else
  // special treatment for paralell forms
    lN=list();lD=list();
    output_.lambda=list();
    output_.max_x_e=list();
    output_.norm_sb=[];
    for i_f=1:output_.NB_CELS,
      cel_i=output_.cel_qtf(i_f);
      lN(1)=cel_i.NFES_z;
      lD(1)=cel_i.DFES_z;
      [li,mxei,nsbi]=scale_cels(lN,lD,params.NBECHS_NORM,params.i_norm_scaling,params.i_norm_analysis,params.switch_use_power_of_2);
      output_.lambda(i_f)=li;
      output_.max_x_e(i_f)=mxei;
      output_.norm_sb=[output_.norm_sb;nsbi];
    end
  end
  if (params.i_norm_analysis)~=1 then
    output_.output_noise=norm(output_.norm_sb,2)
  else
    output_.output_noise=norm(output_.norm_sb,1)
  end
  output=output_;
endfunction
function new_code=append_filter_to_c_code(old_code,output)
  format(20);//use 20 decimals numbers for writing old_code
  new_code=old_code;
  if (length(output.cel_qtf)<=0) then
    return;
  end
  cel_qtf=list();k=0;
  l=length(output.cel_qtf);
  for i=1:l,
    ci=output.cel_qtf(i);
    ok=typeof(ci)~="constant";
    if (ok) then
      k=k+1;cel_qtf(k)=ci;
    end
  end
  ok_old_code=max(size(old_code))>0;
  if (ok_old_code) then
    ok_old_code=isfield(old_code,"int_code")==MY_TRUE;
  end
  if (~ok_old_code) then
    name=list();
    int_code.name=name;
    int_code.specif=list();
    float_code.name=name;
    float_code.specif=list();
    int_code.ALL_NB_BITS=[];
  else
   int_code=old_code.int_code;
   float_code=old_code.float_code;
  end
  params=output.params;
  n= params.NB_BITS;
  i=find(int_code.ALL_NB_BITS==n);
  if (i==[]) then
    int_code.ALL_NB_BITS=[int_code.ALL_NB_BITS;n];
  end
  ic=length(int_code.name);ic=ic+1;
  int_code.name(ic)="integer "+string(n)+"/"+string(2*n)+" bits code  of filter "+params.name_filter;
  name_struct=params.name_filter;
// overscale is dangerous, just used for testing purpose
  lambda_overscale=output.lambda;
  l=length(lambda_overscale);
  if (params.is_paralell==%f) then
  // cascade cels
    lambda_overscale(1)=lambda_overscale(1)*params.over_scale;
    lambda_overscale(l)=lambda_overscale(l)/params.over_scale;
    [l_ini_coeffs,l_one_step,l_define]=get_casc_integer_c_code(lambda_overscale,cel_qtf,params.name_filter,params.switch_round,params.switch_saturate);
  else
  // paralell cels
    for i=1:l,
      cel_qtf(i).NB_BITS=params.NB_BITS;
      lambda_overscale(i)(1)=lambda_overscale(i)(1)*params.over_scale;
      lambda_overscale(i)(2)=lambda_overscale(i)(2)/params.over_scale;
    end
  //  cel_qtf(i).NB_BITS= params.NB_BITS;
    [l_ini_coeffs,l_one_step,l_define]=get_parl_integer_c_code(lambda_overscale,cel_qtf,params.name_filter,params.switch_round,params.switch_saturate);
    
  end
  int_code.specif(ic)=lstcat(l_ini_coeffs,l_one_step);
  l=genere_declarations(int_code.ALL_NB_BITS);
  l_define=lstcat(l_define,l);
  int_code.l_define=l_define;
// generate global integer code
  int_code.all_code=list();
  for i=1:length(int_code.specif),
    int_code.all_code=lstcat(int_code.all_code,int_code.specif(i));
  end
// floating point ideal old_code
  float_code.name(ic)="double precision code of filter "+params.name_filter;
  is_paralell=output.params.is_paralell;
  [l_specif,l_define]=get_ideal_c_code(output.F_z,params.name_filter,is_paralell);
  if isfield(float_code,"common_code")~=MY_TRUE then
    float_code.l_define=l_define;
  end
  float_code.specif(ic)=l_specif;
// generate global floating point code
  float_code.all_code=list();
  for i=1:length(float_code.specif),
    float_code.all_code=lstcat(float_code.all_code,float_code.specif(i));
  end
  all_code=lstcat(int_code.l_define,float_code.l_define);
  all_code=lstcat(all_code,int_code.all_code);
  all_code=lstcat(all_code,float_code.all_code);
  new_code.all_code=all_code;
  int_code.all_code=lstcat(int_code.l_define,int_code.all_code);
  new_code.int_code=int_code;
  float_code.all_code=lstcat(float_code.l_define,float_code.all_code);
  new_code.float_code=float_code;
endfunction
function l=genere_declarations(NB_BITS)
  l=list();il=0;
  for i=1:max(size(NB_BITS)),
    s="# define int_"+string(NB_BITS)+"_"+name_struct+" short int";
    il=il+1;l(il)=s;
    s="# define int_"+string(2*NB_BITS)+"_"+name_struct+" long int";
    il=il+1;l(il)=s;
  end
endfunction
function nx=get_nb_states(cel)
  nx=cel.degre;
endfunction 
function nc=get_nb_coeffs(cel)
  if (cel.forme=="df1") then
    nc=(cel.degre+1)+(cel.degre);
    return
  end
  if (cel.forme=="df1t") then
    nc=(cel.degre+1)+(cel.degre);
    return
  end
  if (cel.forme=="df2") then
    nc=(cel.degre+1)+(cel.degre);
    return
  end
  if (cel.forme=="df2t") then
    nc=(cel.degre+1)+(cel.degre);
    return
  end
  if (cel.forme=="ss") then
    nc=(cel.degre^2)+2*(cel.degre)+1;
    return
  end
  error("not yet implemented for cel of type :"+cel.forme);
endfunction
function [l_out,s_struct,p_name_struct]=append_declar_fcts_to_l(l)
  s_NB_BITS=string(NB_BITS);
  s_2NB_BITS=string(2*NB_BITS);
  s_name_struct="s_"+s_NB_BITS+"bits_"+"filter_"+name_struct;
  p_name_struct="p_"+s_NB_BITS+"bits_"+"filter_"+name_struct;
  i=length(l);
  i=i+1;l(i)="  "+"typedef struct {";
  i=i+1;l(i)="  "+"  int nb_coeffs;";
  i=i+1;l(i)="  "+"  int nb_states;";
  i=i+1;l(i)="  "+"  "+s_int16+" *coeffs;";
  i=i+1;l(i)="  "+"  "+s_int32+" *states;";
  i=i+1;l(i)="  "+"}"+s_name_struct+";";
  i=i+1;l(i)="  "+"typedef "+s_name_struct +" *"+p_name_struct +";";
  i=i+1;l(i)="/* creator of structure "+p_name_struct+" */";
  i=i+1;l(i)="  "+p_name_struct+" new_"+s_NB_BITS+"bits_"+"filter_"+name_struct+"() {";
  s_struct="p_"+name_struct;
  i=i+1;l(i)="  "+"  "+p_name_struct+" "+s_struct+";";
  i=i+1;l(i)="  "+"  "+s_struct+" = ("+s_name_struct+" *) malloc(sizeof("+s_name_struct+"));"
  i=i+1;l(i)="  "+"  "+s_int32+" *states;";
  i=i+1;l(i)="  "+"  "+"int is;";
  i=i+1;l(i)="  "+"  "+s_struct+"->nb_coeffs="+string(nb_coeffs)+";";
  i=i+1;l(i)="  "+"  "+s_struct+"->nb_states="+string(nb_states)+";";
  i=i+1;l(i)="  "+"  "+s_struct+"->coeffs=("+s_int16+" *)&(coeffs_"+s_NB_BITS+"bits_"+name_struct+"[0]);";
  i=i+1;l(i)="  "+"  states =("+s_int32+" *) malloc("+string(nb_states)+" * sizeof("+string(s_int32)+"));";
  i=i+1;l(i)= "  "+"  "+s_struct+"->states = states;";
  i=i+1;l(i)="  "+"  for (is=0;is<"+string(nb_states)+";is++) {";
  i=i+1;l(i)="  "+"    *(states++)=0;";
  i=i+1;l(i)="  "+"  }";
  i=i+1;l(i)="  "+"  return "+s_struct+";";
  i=i+1;l(i)= "  } /* "+p_name_struct+" new_"+s_NB_BITS+"bits_"+"filter_"+name_struct+"()  */";
  i=i+1;l(i)="/* destructor of structure "+p_name_struct+" */";
  i=i+1;l(i)="  "+"void  destroy_"+s_NB_BITS+"bits"+"_filter_"+name_struct+"("+p_name_struct+" "+s_struct +") {";
  i=i+1;l(i)="  "+"  free((void *) ("+s_struct+"->states) ); /* release memory allocated for states */";
  i=i+1;l(i)="  "+"  free((void *)"+s_struct+") ;/* release memory allocated for structure */";
  i=i+1;l(i)= "  } /* void destroy_"+s_NB_BITS+"bits"+"_filter_"+name_struct+"("+p_name_struct+" "+s_struct +") */";;
  l_out=l;
endfunction
function [l_ini,l_cod,l_define]=get_parl_integer_c_code(lbds,cels,name_struct,switch_round,switch_saturate)

  [lhs,rhs]=argn(0);
  if (rhs<4) then
    switch_round="floor";
  end
  if (rhs<5) then
    switch_saturate="no saturate";
  end
  if switch_round=="round only at key points" then
    switch_round_std="floor";
    switch_round_key="round";
  else 
    switch_round_std=switch_round;
    switch_round_key=switch_round;
  end
  if (length(cels)>0) then
    NB_BITS=cels(1).NB_BITS;
    name_tmp_2N="tmp_"+string(2*NB_BITS);
  end

  s_int16="int_"+string(NB_BITS)+"_"+name_struct;
  s_int32="int_"+string(2*NB_BITS)+"_"+name_struct;
  en_32="en_"+string(2*NB_BITS);
  sn_32="sn_"+string(2*NB_BITS);
  en_16="en_"+string(NB_BITS);
  x1="x1_"+string(NB_BITS);
  x2="x2_"+string(NB_BITS);
  vn="vn_"+string(NB_BITS);
  lbd_in=1;
  l_cod=list();
  l_ini=list();
  nb_states=0;
  nb_coeffs=0;
  max_deg=0;
// pass 1 get individual codes and output scalings 
  l_cod_i=list();
  lbd_out_i=[];
  need_acc_x=%f;
  for i=1:length(cels),
    celi=cels(i);
    celi.switch_round=switch_round;
    celi.switch_saturate=switch_saturate;
    max_deg=max([max_deg,celi.degre]);
    nb_states=nb_states+get_nb_states(celi);
    nb_coeffs=nb_coeffs+get_nb_coeffs(celi);
    lbd_in=lbds(i)(1);
    l_cod=list();
    i_cod=length(l_cod);
    i_cod=i_cod+1;l_cod(i_cod)="/* code of cel "+string(i)+" */";
    gain_is_0=(celi.degre==0);
    if gain_is_0 then
      gain_is_0=abs(celi.Bi_int)*2^(-celi.LB) <=1/2^(NB_BITS-1);
    end
    if gain_is_0 then
      lbd_out_i=[lbd_out_i;-%inf];
      l_cod=list();
      l_cod_i(i)=l_cod;
      i_ini=length(l_ini);
      i_ini=i_ini+1;l_ini(i_ini)="0 /* no init of cel "+string(i)+" wich has zero gain*/";
    //  l_ini=lstcat(l_ini,l_initi);
    else
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect(en_32,en_16,2*NB_BITS);
      [lbd_out,l_initi,l_codi]=get_integer_cel_code(lbd_in,celi,name_struct,i);
      lbd_out_i=[lbd_out_i;lbd_out*lbds(i)(2)];
      l_cod=lstcat(l_cod,l_codi);
      l_cod_i(i)=l_cod;
      i_ini=length(l_ini);
    //  i_ini=i_ini+1;l_ini(i_ini)="/* init of cel "+string(i)+" */";
      l_ini=lstcat(l_ini,l_initi);
    end
    if (celi.forme=="ss")&(cels(i).degre>0) then
      need_acc_x=%t;
    end
  end
// get global output scaling
  l_out_glob=max(lbd_out_i);
  l_out_glob=max([l_out_glob]);
  lbd_out_i=lbd_out_i/l_out_glob;
// pass 2 : scale output of each cel
  l_cod=list();
  for i=1:length(cels),
    l_codi=l_cod_i(i);
    lbd_out=lbd_out_i(i);
    if (lbd_out~=-%inf) then
      li=cod_decal_with_round(en_32,en_32,round(log2(lbd_out)),-1,switch_round_std);
      li(1)=li(1)+" /* scale output of cel "+string(i)+"*/";
      l_codi=lstcat(l_codi,li);
      s=sn_32+"+="+en_32+";";
      i_codi=length(l_codi);
      i_codi=i_codi+1;l_codi(i_codi)=s;
    else
      i_codi=length(l_codi);
      i_codi=i_codi+1;l_codi(i_codi)="/* no accumulation because cel "+string(i)+" has zero gain */";
    end
    l_cod_i(i)=l_codi;
    l_cod=lstcat(l_cod,l_cod_i(i));
  end
// pass 3 : scale global output
  li=cod_decal_with_round(sn_32,sn_32,round(log2(l_out_glob)),-1,switch_round_key);
  li(1)=li(1)+" /* scale global output */";
  l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  li=cod_saturation(sn_32,sn_32,NB_BITS,switch_saturate);
  l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  if (lhs==3) then
    l=list();i=0;
    i=i+1;l(i)="/* stdio may be useful if you use printf */";
    i=i+1;l(i)="#include <stdio.h>";
    i=i+1;l(i)="/* stdlib is needed for malloc declaration */";
    i=i+1;l(i)="#include <stdlib.h>";
    l_define=l;
  end
// entete of l_ini
  s_NB_BITS=string(NB_BITS);
  i=i+1;l(i)="const "+s_int16+" coeffs_"+s_NB_BITS+"bits_"+name_struct+"["+string(nb_coeffs)+"]={";
  s="     ";
  for i=1:length(l_ini),
    l_ini(i)=s+l_ini(i);
    s="     ,";
  end
  s=l_ini(length(l_ini));
  i=length(l_ini);
  i=i+1;l_ini(i)="};"
  l=lstcat(l,l_ini);
  [l,s_struct,p_name_struct]=append_declar_fcts_to_l(l);
  i=length(l);
  l_ini=lstcat(l);
  l_ini=ident_list(l_ini,"  ");
// entete of l_cod
  l_cod=ident_list(l_cod,"  ");
  l=list();i=0;
  s=s_int32 + " one_step_"+s_NB_BITS+"bits_filter_"+name_struct+"("+s_int16+" "+en_16+" , "+p_name_struct+" "+s_struct+") {";
  i=i+1;l(i)=s;
  i=i+1;l(i)="  "+s_int16+" *coeffs;";
  i=i+1;l(i)="  "+s_int32+" *states;";
  i=i+1;l(i)="  "+"coeffs="+s_struct+"->coeffs;";
  i=i+1;l(i)="  "+"states="+s_struct+"->states;";
  if (switch_round~="floor") then
    i=i+1;l(i)="  "+s_int32+" "+name_tmp_2N+";";
  end
  i=i+1;l(i)="  "+s_int16+" "+vn+";";
  i=i+1;l(i)="  "+s_int16+" "+x1+";";
  if (max_deg>1) then
    i=i+1;l(i)="  "+s_int16+" "+x2+";";
  end
  if (need_acc_x==%t) then
    acc_x="accx_"+string(2*NB_BITS);
    i=i+1;l(i)="  "+s_int32+" "+acc_x+";";
  end
  i=i+1;l(i)="  "+s_int32+" "+en_32+";";
  i=i+1;l(i)="  "+s_int32+" "+sn_32+";";
  i=i+1;l(i)="  "+sn_32+"=0;";
  l_cod=lstcat(l,l_cod);
  l=list();i=0;
  i=i+1;l(i)="  "+"return  ( "+sn_32+") ;";
  i=i+1;l(i)="} /* "+s_int32 +" one_step_+"+s_NB_BITS+"bits_filter_"+name_struct+"(..) */";
  l_cod=lstcat(l_cod,l);
  l_test=get_integer_test_code();
  l_cod=lstcat(l_cod,l_test);
  l_cod=ident_list(l_cod,"  ");

endfunction
function l=cod_saturation(out,in,NB_BITS,switch_saturate)
  l=list();il=0;
  if (switch_saturate~="saturate") then
     if (out==in) then
     // nothing to do 
       return;
     end
     il=il+1;l(il)=cod_affect(out,in,NB_BITS);
     return  
  end
  if (switch_saturate=="saturate") then
    max_int=2^(NB_BITS-1)-1;max_int=string(max_int);
    min_int=-2^(NB_BITS-1);min_int=string(min_int);
  end
  if (out==in) then
    NB_BITS=-1;
  end
  il=il+1;l(il)="/* "+out+" <- "+in+" saturated between["+max_int+","+min_int+"] */";
  il=il+1;l(il)="if ("+in+">"+max_int+") {";
     il=il+1;l(il)="  "+cod_affect(out,max_int,-1);
  il=il+1;l(il)="} else if ("+in+"<"+min_int+") {";
     il=il+1;l(il)="  "+cod_affect(out,min_int,-1);
  il=il+1;l(il)="}";
  if (out~=in) then
  // no saturation, result in strupid code : out=out; if name input = name output
    il=il+1;l(il)="else {";
    il=il+1;l(il)="  "+cod_affect(out,in,NB_BITS);
    il=il+1;l(il)="}";
  end 
endfunction
function ld=get_integer_test_code()
    ld=list();id=0;
    id=id+1;ld(id)= "/* math.h is included only for cos and round function */";
    id=id+1;ld(id)= "#include <math.h>";
    id=id+1;ld(id)= " void teste_"+s_NB_BITS+"bits_filter_"+name_struct+"(void) {";
    id=id+1;ld(id)= "    long int n=0,NB_ECHS=10; /* YOU CAN CHANGE THIS  */";
    s_max_int_16=string(2^(NB_BITS-1)-1);
    id=id+1;ld(id)= "    double amp_en="+s_max_int_16+" ;  /* amplitude of input */";
    id=id+1;ld(id)= "    double f_ech=100 ; /* sampling frequency hz */";
    id=id+1;ld(id)= "    double f_reelle=2 ; /* real frequency hz */";
    id=id+1;ld(id)= "    double freq_en=f_reelle/f_ech ; /* freelle/fe */";
    id=id+1;ld(id)= "    double en ; ";
    id=id+1;ld(id)= "    const double PI=3.141592653589793115998 ; ";
    id=id+1;ld(id)= "    "+s_int16+" en_"+s_NB_BITS+" ; ";
    id=id+1;ld(id)= "    double phi_n=0 ; ";
    id=id+1;ld(id)= "    double sn ;";
    id=id+1;ld(id)= "    "+p_name_struct +" "+s_struct+"=new_"+s_NB_BITS+"bits_filter_"+name_struct+"();";
    id=id+1;ld(id)= "    for (n=0;n<NB_ECHS;n++) {";
    id=id+1;ld(id)= "      en=amp_en*cos(phi_n);";
    id=id+1;ld(id)= "      en_"+s_NB_BITS+"=("+s_int16+") floor(en+0.5);"
    id=id+1;ld(id)= "      sn =  (double)one_step_"+s_NB_BITS+"bits_filter_"+name_struct+"(en_"+s_NB_BITS+" , "+s_struct +") ;";
    id=id+1;ld(id)= "      phi_n+=2*PI*freq_en;";
    id=id+1;ld(id)= "      if (phi_n>2*PI) {";
    id=id+1;ld(id)= "        phi_n-=2*PI;";
    id=id+1;ld(id)= "      }";
    id=id+1;ld(id)= "    } /*for (n=0;n<NB_ECHS;n++) */";
    id=id+1;ld(id)= "    destroy_"+s_NB_BITS+"bits_filter_"+name_struct+"("+s_struct +") ;";
    id=id+1;ld(id)= "  } /* void teste_"+s_NB_BITS+"bits_filter_"+name_struct+"(void)  */";
endfunction
function [l_ini,l_cod,l_define]=get_casc_integer_c_code(lbds,cels,name_struct,switch_round,switch_saturate)

  [lhs,rhs]=argn(0);
  if (rhs<4) then
    switch_round="floor";
  end
  if (rhs<5) then
    switch_saturate="no saturate";
  end
  if switch_round=="round only at key points" then
    switch_round_std="floor";
    switch_round_key="round";
  else 
    switch_round_std=switch_round;
    switch_round_key=switch_round;
  end
  if (length(cels)>0) then
    NB_BITS=cels(1).NB_BITS;
    name_tmp_2N="tmp_"+string(2*NB_BITS);
  end
  s_NB_BITS=string(NB_BITS);
  lbd_in=1;
  l_cod=list();
  l_ini=list();
  nb_states=0;
  nb_coeffs=0;
  max_deg=0;
  need_acc_x=%f;
  for i=1:length(cels),
    celi=cels(i);

    if (celi.forme=="ss")&(cels(i).degre>0) then
      need_acc_x=%t;
    end
    celi.switch_round=switch_round;
    celi.switch_saturate=switch_saturate;
    max_deg=max([max_deg,celi.degre]);
    nb_states=nb_states+get_nb_states(celi);
    nb_coeffs=nb_coeffs+get_nb_coeffs(celi);

    lbd_in=lbd_in*lbds(i);
    i_cod=length(l_cod);
    i_cod=i_cod+1;l_cod(i_cod)="/* code of cel "+string(i)+" */";
    [lbd_out,l_initi,l_codi]=get_integer_cel_code(lbd_in,celi,name_struct,i);
    l_cod=lstcat(l_cod,l_codi);
    i_ini=length(l_ini);
  //  i_ini=i_ini+1;l_ini(i_ini)="/* init of cel "+string(i)+" */";
    l_ini=lstcat(l_ini,l_initi);
    lbd_in=lbd_out;
  end
  i=length(cels)+1;
  lbd_in=lbd_in*lbds(i);
  s_int16="int_"+string(NB_BITS)+"_"+name_struct;
  s_int32="int_"+string(2*NB_BITS)+"_"+name_struct;

  if (lhs==3) then
    l=list();i=0;
    i=i+1;l(i)="/* stdio may be useful if you use printf */";
    i=i+1;l(i)="#include <stdio.h>";
    i=i+1;l(i)="/* stdlib is needed for malloc declaration */";
    i=i+1;l(i)="#include <stdlib.h>";
    l_define=l;
  end
  en="en_"+string(2*NB_BITS);
  li=cod_decal_with_round(en,en,round(log2(lbd_in)),-1,switch_round_key);
  li(1)=li(1)+" /* scale global output */";
  l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  li=cod_saturation(en,en,NB_BITS,switch_saturate);
  l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
// entete of l_ini
  //l_ini=ident_list(l_ini,"  ");
  l=list();i=0;
  i=i+1;l(i)="const "+s_int16+" coeffs_"+s_NB_BITS+"bits_"+name_struct+"["+string(nb_coeffs)+"]={";
  s="     ";
  for i=1:length(l_ini),
    l_ini(i)=s+l_ini(i);
    s="     ,";
  end
  s=l_ini(length(l_ini));
  i=length(l_ini);
  i=i+1;l_ini(i)="};"
  l=lstcat(l,l_ini);
  [l,s_struct,p_name_struct]=append_declar_fcts_to_l(l);
  l_ini=l;
  l_ini=ident_list(l_ini,"  ");
// entete of l_cod
  l_cod=ident_list(l_cod,"  ");
  l=list();i=0;
  en_32="en_"+string(2*NB_BITS);
  en_16="en_"+string(NB_BITS);
  x1="x1_"+string(NB_BITS);
  x2="x2_"+string(NB_BITS);
  vn="vn_"+string(NB_BITS);
  if (need_acc_x==%t) then
    acc_x="accx_"+string(2*NB_BITS);
    i=i+1;l(i)="  "+s_int32+" "+acc_x+";";
  end
  s=s_int32 + " one_step_"+s_NB_BITS+"bits_filter_"+name_struct+"("+s_int16+" "+en_16+" , "+p_name_struct+" "+s_struct+") {";
  i=i+1;l(i)=s;
  i=i+1;l(i)="  "+s_int16+" *coeffs;";
  i=i+1;l(i)="  "+s_int32+" *states;";
  i=i+1;l(i)="  "+"coeffs="+s_struct+"->coeffs;";
  i=i+1;l(i)="  "+"states="+s_struct+"->states;";
  if (switch_round~="floor") then
    i=i+1;l(i)="  "+s_int32+" "+name_tmp_2N+";";
  end
  i=i+1;l(i)="  "+s_int16+" "+vn+";";
  i=i+1;l(i)="  "+s_int16+" "+x1+";";
  if (max_deg>1) then
    i=i+1;l(i)="  "+s_int16+" "+x2+";";
  end 
  i=i+1;l(i)="  "+s_int32+" "+en_32+";";
  i=i+1;l(i)="  "+en_32+" = ("+s_int32+") "+en_16+" ;";
  l_cod=lstcat(l,l_cod);
  l=list();i=0;
  i=i+1;l(i)="  "+"return  ( "+en_32+") ;";
  i=i+1;l(i)="} /*  one_step_"+s_NB_BITS+"bits_filter_"+name_struct+"(..) */";
  l_cod=lstcat(l_cod,l);
  l_test=get_integer_test_code();
  l_cod=lstcat(l_cod,l_test);
  l_cod=ident_list(l_cod,"  ");

endfunction
function [lbd_out,l_init,l_cod]=get_integer_cel_code(lbd_in,cel,name_struct,num_cel)
  [lhs,rhs]=argn(0);
  if (rhs<4) then
     num_cel=0; // unknown number of cel 
  end
  if (cel.forme=="df2") then
    [lbd_out,l_init,l_cod]=get_integer_df2_code(lbd_in,cel,name_struct,num_cel)
    return
  elseif (cel.forme=="ss") then
    [lbd_out,l_init,l_cod]=get_integer_ss_code(lbd_in,cel,name_struct,num_cel)
    return
  end
  error("not yet implemented for "+cel.forme);
endfunction
function s=cod_auto_decal(nv,val_d)
  if (val_d==0) then
    s=[];
  elseif val_d>0 then
    s=nv+"="+nv+"<<"+string(val_d)+";"
  else
    s=nv+"="+nv+">>"+string(-val_d)+";"
  end
endfunction
function l=cod_decal_with_round(n_out,nv,val_d,NB_BITS,switch_round)
  l=list();i=0;
  if (val_d>=0)|(switch_round=="floor") then
    s=cod_decal(n_out,nv,val_d,NB_BITS)
    i=i+1;l(i)=s;
    return;
  end
  if (switch_round=="round") then
    s=cod_decal(name_tmp_2N,nv,val_d+1);
    i=i+1;l(i)=s;
    s=name_tmp_2N+"+=1;"
    i=i+1;l(i)=s;
    s=cod_decal(n_out,name_tmp_2N,-1,NB_BITS)
    i=i+1;l(i)=s;
    return
  end
  if (switch_round=="fix") then
    i=i+1;l(i)="if ("+nv+">=0) {";
      s=cod_decal(n_out,nv,val_d,NB_BITS)
      i=i+1;l(i)="  "+s;
    i=i+1;l(i)="} else {";
      s=cod_decal(n_out,"(-"+nv+")",val_d,NB_BITS)
      i=i+1;l(i)="  "+s;
      i=i+1;l(i)="  "+n_out+"=-"+n_out+";";
    i=i+1;l(i)="}";
    return
  end
  error("switch_round="+switch_round+" not yet implemented");
endfunction

function s=cod_decal(n_out,nv,val_d,NB_BITS)
  [lhs,rhs]=argn(0);
  s_type=[];
  if (rhs>3) then
    if (NB_BITS>0) then
      s_type="(int_"+string(NB_BITS)+"_"+name_struct+")";
    end
  end
  s_val_d=string(abs(val_d));
  if (val_d==0) then
    s_rhs=[];
  elseif val_d>0 then
    s_rhs=nv+"<<"+s_val_d;
  else
    s_rhs=nv+">>"+s_val_d;
  end
  if (s_type==[]) then
    if (s_rhs==[]) then
      if ( n_out==nv) then
        s=[];
        return
      else
        s=n_out+"="+nv+";";
        return
      end 
    else
      s=n_out+"="+s_rhs+";";
    end
    return;
  end
  if s_rhs==[] then
    s_rhs=nv;
  end
  s_rhs="("+s_rhs+")";
  s=n_out+"="+s_type+s_rhs+";";
endfunction

function s=cod_affect(n_out,value,NB_BITS)
  [lhs,rhs]=argn(0);
  if (rhs<3) then
     NB_BITS=-1;
  end
  if (NB_BITS>0) then
    s_type="int_"+string(NB_BITS)+"_"+name_struct;
    s=n_out+"= ("+s_type+")"+string(value)+";"
  else
    s=n_out+"= "+string(value)+";"
  end
endfunction
function s=cod_multiply_acc(nout,ncoeffs,nstate)
  [lhs,rhs]=argn(0);
  if (rhs<4) then
    NB_BITS=-1;
  end
  if (NB_BITS==-1 ) then
    s=nout+"+="+ncoeffs+"*"+nstate+";"
  else
    s_type="int_"+string(NB_BITS)+"_"+name_struct;
    s_type="("+s_type+")";
    s=nout+"+="+ncoeffs+"* ( "+s_type+" "+nstate+");"
  end 
endfunction
function s=cod_multiply(nout,ncoeffs,nstate,NB_BITS)
  [lhs,rhs]=argn(0);
  if (rhs<4) then
    NB_BITS=-1;
  end
  if (NB_BITS==-1 ) then
    s=nout+"="+ncoeffs+"*"+nstate+";"
  else
    s_type="int_"+string(NB_BITS)+"_"+name_struct;
    s_type="("+s_type+")";
    s=nout+"="+ncoeffs+"* ( "+s_type+" "+nstate+");"
  end 
endfunction

function [lbd_out,l_ini,l_cod]=get_integer_df0_code(lbd_in,cel,name_struct,num_cel)
  switch_round=cel.switch_round;
  if switch_round=="round only at key points" then
    switch_round_std="floor";
    switch_round_key="round";
  else 
    switch_round_std=switch_round;
    switch_round_key=switch_round;
  end
  en="en_"+string(2*cel.NB_BITS);
  l_cod=list();i_cod=0; 
  l_ini=list();i_ini=0; 
  b0=cel.Bi_int(1);
  if (b0==0) then
  // very special case of gain equal to 0
    i_cod=i_cod+1;l_cod(i_cod)=en+"=0; /* gain b0 =0 */";
    lbd_out=-%inf;
    return
  end
  str_coeffs="coeffs";
  LB=cel.LB;
  lbd_out=2^(-LB);
  log2_in=round(log2(lbd_in));
  li=cod_decal_with_round(en,en,round(log2(lbd_in)),2*NB_BITS,switch_round_key);
  li(1)=li(1)+" /* en<-en .2^"+string(log2_in)+ " */";
  l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  i_ini=i_ini+1;l_ini(i_ini)=string(b0)+" /* cel +"+string(num_cel)+":  b0.2^"+string(LB)+" */";
  i_cod=i_cod+1;l_cod(i_cod)=cod_multiply(en,get_auto_inc_code(str_coeffs,b0),en,NB_BITS)+" /* en<-b0 . en */";
endfunction
function sy=get_auto_inc_code(s,cf)
 SWITCH_ARRAY_COEFF=%f;
 if (SWITCH_ARRAY_COEFF==%f) then
   sy=string(cf);
 else
   sy="( *("+s+"++) )";
 end
endfunction

function [lbd_out,l_ini,l_cod]=get_integer_df2_code(lbd_in,cel,name_struct,num_cel)
  switch_array_coeff=%f;
  dg=cel.degre
  if dg==0 then
    [lbd_out,l_ini,l_cod]=get_integer_df0_code(lbd_in,cel,name_struct,num_cel);
    return
  end
  en="en_"+string(2*cel.NB_BITS);
  Lin=round(log2(lbd_in));
  b0=cel.Bi_int(1);
  LA=cel.LA;
  LB=cel.LB;
  Lin_prog=Lin+LA;
  lbd_out=2^(-LB);
  switch_round=cel.switch_round;
  if switch_round=="round only at key points" then
    switch_round_std="floor";
    switch_round_key="round";
  else 
    switch_round_std=switch_round;
    switch_round_key=switch_round;
  end
  Lx=round(log2(1-abs(cel.a0x_de_z)));
  sign_a0=sign(cel.a0x_de_z);
  s_deg=string(cel.degre);
  l_cod=list();i_cod=length(l_cod);
  l_ini=list();i_ini=length(l_ini);
  en="en_"+string(2*cel.NB_BITS);
  vn="vn_"+string(cel.NB_BITS);;
  if (dg>0) then
    b1=cel.Bi_int(2);
    a1=cel.moins_Ai_int(1);
  end
  if (dg >1) then
    b2=cel.Bi_int(3);
    a2=cel.moins_Ai_int(2);
  end
  NB_BITS=cel.NB_BITS;
  str_coeffs="coeffs";
  states="states"
  vn="vn_"+string(NB_BITS);
  if (Lin_prog~=0) then
    li=cod_decal_with_round(en,en,Lin_prog,-1,switch_round_std);
    li(1)=li(1)+" /* en<-en<<L+LA ,L="+string(Lin)+",LA="+string(LA)+"*/";
    l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  end 
  name_x1="x1_"+string(NB_BITS);
  name_x2="x2_"+string(NB_BITS);;
  if (Lx==0) then
    i_cod=i_cod+1;l_cod(i_cod)=cod_affect(name_x1,"(* "+states+" )",NB_BITS)+" /* init x1 */";
  else
    li=cod_decal_with_round(name_x1,"(* "+states+" )",Lx,NB_BITS,switch_round_key);
    li(1)=li(1)+" /* init x1 */";
    l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  end
  if (dg>1) then
    if (Lx==0) then
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect(name_x2,"(* ("+states+"+1))",NB_BITS)+" /* init x2 */";
    else
      li=cod_decal_with_round(name_x2,"(* ("+states+"+1))",Lx,NB_BITS,switch_round_key);
      li(1)=li(1)+" /* init x2 */";
      l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
    end
  end
// AR part, denominator A
  i_ini=i_ini+1;l_ini(i_ini)=string(a1)+" /*  cel +"+string(num_cel)+":  -a1.2^"+string(LA)+" */";
  i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(en,get_auto_inc_code(str_coeffs,a1),name_x1)+" /* en<-en - a1 . x1 */";
  if (dg>1) then
    i_ini=i_ini+1;l_ini(i_ini)=string(a2)+" /*  cel +"+string(num_cel)+":  -a2.2^"+string(LA)+" */";
    i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(en,get_auto_inc_code(str_coeffs,a2),name_x2)+" /* en<-en - a2 . x2 */";
  end
  if (switch_saturate~="saturate") then
    li=cod_decal_with_round(vn,en,-cel.LA,NB_BITS,switch_round_key);
    li(1)=li(1)+" /* vn<-en >> LA */";
  else
    li=cod_decal_with_round(en,en,-cel.LA,-1,switch_round_key);
    li(1)=li(1)+" /* vn<-en >> LA */";
    l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
    li=cod_saturation(vn,en,NB_BITS,switch_saturate);
  end
  l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
// MA part, numerator B
  if (b0~=0) then 
    i_ini=i_ini+1;l_ini(i_ini)=string(b0)+" /*  cel +"+string(num_cel)+":  b0.2^"+string(LB)+" */";
    i_cod=i_cod+1;l_cod(i_cod)=cod_multiply(en,get_auto_inc_code(str_coeffs,b0),vn)+" /* en<-b0 . vn */";
    i_ini=i_ini+1;l_ini(i_ini)=string(b1)+" /*  cel +"+string(num_cel)+":  b1.2^"+string(LB)+" */";
    i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(en,get_auto_inc_code(str_coeffs,b1),name_x1)+" /* en<-en +b1 . x1  */";
  else 
    i_ini=i_ini+1;l_ini(i_ini)=string(b1)+" /*  cel +"+string(num_cel)+":  b1.2^"+string(LB)+", note that b0=0 */";
    i_cod=i_cod+1;l_cod(i_cod)=cod_multiply(en,get_auto_inc_code(str_coeffs,b1),name_x1)+" /* en<-b1 . x1 ,because b0=0 */";
  end
  if (dg>1) then
    i_ini=i_ini+1;l_ini(i_ini)=string(b2)+" /*  cel +"+string(num_cel)+":  b2.2^"+string(LB)+" */";
    i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(en,get_auto_inc_code(str_coeffs,b2),name_x2)+" /* en<-en +b2 . x2  */";
  end
  if (Lx==0) then
  // update states
    i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")",vn,2*NB_BITS)+" /* x1=vn  */";
    i_cod=i_cod+1;l_cod(i_cod)=states+"++;";
    if (dg>1) then
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")",name_x1,2*NB_BITS)+" /* x2=x1  */";
      i_cod=i_cod+1;l_cod(i_cod)=states+"++;";
    end
  else // Lx <0
    if (sign_a0<0) then
    // xn=x(n_1)+en-2_L.x(n_1)
    // 2^-L/(1-(1-2-L).q)
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+",vn)+" /* x1<-old_x1+vn  */";
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")-",name_x1)+" /* x1<-x1-[old_x1.2^"+string(Lx)+"] */";
      i_cod=i_cod+1;l_cod(i_cod)=states+"++;"
    else
    // xn=-x(n-1)+en+2_L.xn_1
    // 2^-L/(1+(1-2-L).q)
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(* "+states+" )","-"+"(* "+states+" )")+" /* x1<- [-old_x1]  */";
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+",vn)+" /* x1<- x1 + vn  */";
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+",name_x1)+" /* x1<-x1+[old_x1.2^"+string(Lx)+"] */";
      i_cod=i_cod+1;l_cod(i_cod)=states+"++;"
    end
    if (dg>1) then
      if (sign_a0<0) then
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+",name_x1)+" /* x2<-x2+old_x1  */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")-",name_x2)+" /* x2<-x2-[old_x2.2^"+string(Lx)+"] */";
        i_cod=i_cod+1;l_cod(i_cod)=states+"++;"
      else
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(* "+states+" )","-"+"(* "+states+" )")+" /* x2<- [-old_x2]  */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("*(" +state+")+",name_x1)+" /* x2<- x2 + old_x1  */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("*(" +state+")+",name_x2)+" /* x2<- x2 + [old_x2.2^"+string(Lx)+"] */";
        i_cod=i_cod+1;l_cod(i_cod)=states+"++;";

      end 
    end
  end


endfunction
function [lbd_out,l_ini,l_cod]=get_integer_ss_code(lbd_in,cel,name_struct,num_cel)
  dg=cel.degre
  if dg==0 then
    [lbd_out,l_ini,l_cod]=get_integer_df0_code(lbd_in,cel,name_struct);
    return
  end
  if (isfield(cel,"a0x_de_z")==MY_TRUE) then
    sign_a0=sign(cel.a0x_de_z);
    L_op=round(log2(1-abs(cel.a0x_de_z)));
  else
    L_op=0;
  end
  lbd_out=2^(-cel.L_s);
  NB_BITS=cel.NB_BITS;
  en="en_"+string(2*NB_BITS);
  accx="accx_"+string(2*NB_BITS);
  vn="vn_"+string(NB_BITS);
  Lin=round(log2(lbd_in));
  switch_round=cel.switch_round;
  if switch_round=="round only at key points" then
    switch_round_std="floor";
    switch_round_key="round";
  else 
    switch_round_std=switch_round;
    switch_round_key=switch_round;
  end
  s_deg=string(cel.degre);
  l_cod=list();i_cod=length(l_cod);
  l_ini=list();i_ini=length(l_ini);
  vn="vn_"+string(cel.NB_BITS);
  str_coeffs="coeffs";
  states="states"
  if (Lin~=0) then
    li=cod_decal_with_round(vn,en,Lin,NB_BITS,switch_round_std);
    li(1)=li(1)+" /* vn<-en<<L ,L="+string(Lin)+"*/";
    l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  else
    li=cod_affect(vn,en,NB_BITS);
    l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  end
  name_x=["x1_"+string(NB_BITS);
          "x2_"+string(NB_BITS)];
  A=cel.Aint;
  B=cel.Bint;
  C=cel.Cint;
  D=cel.Dint;

  if (D~=0) then
    i_ini=i_ini+1;l_ini(i_ini)=string(D)+" /*  cel +"+string(num_cel)+":  D.2^"+string(cel.L_s)+" */";
    i_cod=i_cod+1;l_cod(i_cod)=cod_multiply(en,get_auto_inc_code(str_coeffs,D),vn)+" /* sn<-D.vn */";
  else
    i_cod=i_cod+1;l_cod(i_cod)=cod_affect(en,0,-1)+" /* sn<-0,because D=0 */";
  end
// init states
  for i_x=1:cel.degre,
    i=i_x;
    ni=string(i);
    nxi=name_x(i_x);
    if (i-1)==0 then
      s_state_i="(*"+states+")";
    else
      s_state_i="(*("+states+" + "+string(i-1)+"))";
    end
    if (L_op==0) then
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect(nxi,s_state_i,NB_BITS)+" /* "+nxi+" <- previous value*/";
    else
      li=cod_decal_with_round(nxi,s_state_i,L_op,NB_BITS,switch_round_key);
      l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
    end
  end
  for i_x=1:cel.degre,
    i=i_x;
    Lxi=cel.L_x(i);
    ni=string(i);
    nxi=name_x(i_x);
    if cel.degre>1 then
      j=1+cel.degre-i_x;
      nj=string(j);
      nxj=name_x(j);
    end
    if (B(i)~=0) then
    // Xn+1=B.U
      i_ini=i_ini+1;l_ini(i_ini)=string(B(i))+" /*  cel +"+string(num_cel)+":  B"+ni+".2^"+string(Lxi)+" */";
      i_cod=i_cod+1;l_cod(i_cod)=cod_multiply(accx,get_auto_inc_code(str_coeffs,B(i)),vn)+" /* accx<-b"+ni+".vn */";
    end // if (Bi<>0 )
  // Xn+1=A.X
    if (A(i,i)~=0) then
      i_ini=i_ini+1;l_ini(i_ini)=string(A(i,i))+" /*  cel +"+string(num_cel)+":  A"+ni+ni+".2^"+string(Lxi)+" */";
      i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(accx,get_auto_inc_code(str_coeffs,A(i,i)),nxi)+" /* accx<-accx-a"+ni+ni+" . "+nxi+" */";
    else
      i_ini=i_ini+1;l_ini(i_ini)=" /*  cel +"+string(num_cel)+":  A"+ni+ni+"is zero, not coded in coeffs */";
    end
    if (dg>1) then
      if (A(i,j)~=0 ) then
        i_ini=i_ini+1;l_ini(i_ini)=string(A(i,j))+" /*  cel +"+string(num_cel)+":  A"+ni+nj+".2^"+string(Lxi)+" */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(accx,get_auto_inc_code(str_coeffs,A(i,j)),nxj)+" /* accx<-accx-a"+ni+nj+" . "+nxj+" */";
      else
        i_ini=i_ini+1;l_ini(i_ini)=" /*  cel +"+string(num_cel)+":  A"+ni+nj+"is zero, not coded in coeffs */";
      end
    end
    if (switch_saturate~="saturate") then
      li=cod_decal_with_round(accx,accx,-Lxi,-1,switch_round_key);
      li(1)=li(1)+" /* accx<-accx >> Lx"+string(i)+" */";
    else
      li=cod_decal_with_round(accx,accx,-Lxi,-1,switch_round_key);
      li(1)=li(1)+" /* accx<-accx >> Lx"+string(i)+" */";
      l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
      li=cod_saturation(accx,accx,NB_BITS,switch_saturate);
    end
    l_cod=lstcat(l_cod,li);i_cod=length(l_cod);
  // update state
    if (L_op==0) then
    // update states
      i_cod=i_cod+1;l_cod(i_cod)=cod_affect("*("+states+"++)",accx,2*NB_BITS)+" /* update state("+ni+") */";
    else // Lx <0
      if (sign_a0<0) then
      // xn=x(n_1)+en-2_L.x(n_1)
      // 2^-L/(1-(1-2-L).q)
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+",accx)+" /* update state("+ni+") */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")-",nxi)+" /* x"+string(i_x)+"<-x"+string(i_x)+"-[old_x"+string(i_x)+".2^"+string(L_op)+"] */";
        i_cod=i_cod+1;l_cod(i_cod)=states+"++;"
      else
      // xn=-x(n-1)+en+2_L.xn_1
      // 2^-L/(1+(1-2-L).q)
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(* "+states+" )","-"+"(* "+states+" )")+" /* x"+string(i_x)+"<- [-old_x"+string(i_x)+"]  */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+", accx)+" /* x"+string(i_x)+"<- x"+string(i_x)+" + vn  */";
        i_cod=i_cod+1;l_cod(i_cod)=cod_affect("(*"+states+")+",nxi)+" /* x"+string(i_x)+"<-x"+string(i_x)+"+[old_x"+string(i_x)+".2^"+string(L_op)+"] */";
        i_cod=i_cod+1;l_cod(i_cod)=states+"++;"
      end
    end
    if (C(i)~=0) then
    // Y=C.X use previously computed state
      i_ini=i_ini+1;l_ini(i_ini)=string(C(i))+" /*  cel +"+string(num_cel)+":  C"+ni+".2^"+string(cel.L_s)+" */";
      i_cod=i_cod+1;l_cod(i_cod)=cod_multiply_acc(en,get_auto_inc_code(str_coeffs,C(i)),nxi)+" /* sn<-sn+C"+ni+" . "+nxi+" */";
    end
  end // for i=1:degre

endfunction //get_integer_ss_code

function ld=get_real_test_code()
   ld=list();id=0;
   id=id+1;ld(id)= " void teste_real_"+name_struct+"(void) {";
    id=id+1;ld(id)= "    long int n=0,NB_ECHS=10; /* YOU CAN CHANGE THIS  */";
    id=id+1;ld(id)= "    double amp_en=1 ;  /* amplitude of input */";
    id=id+1;ld(id)= "    double f_ech=100 ; /* sampling frequency hz */";
    id=id+1;ld(id)= "    double f_reelle=2 ; /* real frequency hz */";
    id=id+1;ld(id)= "    double freq_en=0.1 ; /* f/fe */";
    id=id+1;ld(id)= "    double en ; ";
    id=id+1;ld(id)= "    const double PI=3.141592653589793115998 ; ";

    id=id+1;ld(id)= "    double phi_n=0 ; ";
    id=id+1;ld(id)= "    double sn ;";
    id=id+1;ld(id)= "    p_real_filter_"+name_struct+" f_real_"+name_struct+"=new_real_filter_"+name_struct+"();";
    id=id+1;ld(id)= "    for (n=0;n<NB_ECHS;n++) {";
    id=id+1;ld(id)= "      en=amp_en*cos(phi_n);";
    id=id+1;ld(id)= "      sn =  one_step_real_filter_"+name_struct+"(en,f_real_"+name_struct+") ;";
    id=id+1;ld(id)= "      phi_n+=2*PI*freq_en;";
    id=id+1;ld(id)= "      if (phi_n>2*PI) {";
    id=id+1;ld(id)= "        phi_n-=2*PI;";
    id=id+1;ld(id)= "      }";
    id=id+1;ld(id)= "    } /*for (n=0;n<NB_ECHS;n++) */";
    id=id+1;ld(id)= "    destroy_real_filter_"+name_struct+"(f_real_"+name_struct+") ;";
    id=id+1;ld(id)= "  } /* void teste_real_"+name_struct+"(void)  */";
endfunction
function lh=get_header_c_code(name_struct,NB_BITS)
  name_NB_BITS=string(NB_BITS);
  name_2NB_BITS=string(2*NB_BITS);
  caps_name_struct=convstr(name_struct,"u");
  ih=0;lh=list();
  ih= ih + 1 ; lh(ih) = "/*";
  ih= ih + 1 ; lh(ih) = "* File:   band_stop.h";
  ih= ih + 1 ; lh(ih) = "* Author: autogenerated";
  ih= ih + 1 ; lh(ih) = "*";
  ih= ih + 1 ; lh(ih) = "* Created on ";
  ih= ih + 1 ; lh(ih) = "*/";
  ih= ih + 1 ; lh(ih) = "";
  ih= ih + 1 ; lh(ih) = "#ifndef _"+caps_name_struct+"_H";
  ih= ih + 1 ; lh(ih) = "  #define	_"+caps_name_struct+"_H";
  ih= ih + 1 ; lh(ih) = "  #define int_"+name_NB_BITS+"_"+name_struct+" short int";
  ih= ih + 1 ; lh(ih) = "  #define int_"+name_2NB_BITS+"_"+name_struct+" long int";
  ih= ih + 1 ; lh(ih) = "  typedef struct {";
  ih= ih + 1 ; lh(ih) = "      int nb_coeffs;";
  ih= ih + 1 ; lh(ih) = "      int nb_states;";
  ih= ih + 1 ; lh(ih) = "      int_"+name_NB_BITS+"_"+name_struct+" *coeffs;";
  ih= ih + 1 ; lh(ih) = "      int_"+name_2NB_BITS+"_"+name_struct+" *states;";
  ih= ih + 1 ; lh(ih) = "  } s_"+name_NB_BITS+"bits_filter_"+name_struct+";";
  ih= ih + 1 ; lh(ih) = "  typedef s_"+name_NB_BITS+"bits_filter_"+name_struct+" *p_"+name_NB_BITS+"bits_filter_"+name_struct+";";
  ih= ih + 1 ; lh(ih) = "  /* creator of structure p_"+name_NB_BITS+"bits_filter_"+name_struct+" */";
  ih= ih + 1 ; lh(ih) = "  extern p_"+name_NB_BITS+"bits_filter_"+name_struct+" new_"+name_NB_BITS+"bits_filter_"+name_struct+"(void);";
  ih= ih + 1 ; lh(ih) = "  extern void destroy_"+name_NB_BITS+"bits_filter_"+name_struct+"(p_"+name_NB_BITS+"bits_filter_"+name_struct+" p_"+name_struct+");";
  ih= ih + 1 ; lh(ih) = "  extern int_"+name_2NB_BITS+"_"+name_struct+" one_step_"+name_NB_BITS+"bits_filter_"+name_struct+"(int_"+name_NB_BITS+"_"+name_struct+" en_"+name_NB_BITS+", p_"+name_NB_BITS+"bits_filter_"+name_struct+" p_"+name_struct+");";
  ih= ih + 1 ; lh(ih) = "  typedef struct {";
  ih= ih + 1 ; lh(ih) = "      int nb_cels;";
  ih= ih + 1 ; lh(ih) = "      int nb_coeffs;";
  ih= ih + 1 ; lh(ih) = "      int nb_states;";
  ih= ih + 1 ; lh(ih) = "      double *coeffs;";
  ih= ih + 1 ; lh(ih) = "      double *states;";
  ih= ih + 1 ; lh(ih) = "  } s_real_filter_"+name_struct+";";
  ih= ih + 1 ; lh(ih) = "  typedef s_real_filter_"+name_struct+" *p_real_filter_"+name_struct+";";
  ih= ih + 1 ; lh(ih) = "  extern double one_step_real_filter_"+name_struct+"(double en, p_real_filter_"+name_struct+" f);";
  ih= ih + 1 ; lh(ih) = "  extern void destroy_real_filter_"+name_struct+"(p_real_filter_"+name_struct+" f);";
  ih= ih + 1 ; lh(ih) = "  extern p_real_filter_"+name_struct+" new_real_filter_"+name_struct+"(void);";
  ih= ih + 1 ; lh(ih) = "#endif	/* _"+caps_name_struct+"_H */";


endfunction
function [l_specific,l_common]=get_ideal_c_code(Fz,name_struct,is_paralell)
    [lhs,rhs]=argn(0);
    if (rhs<3 ) then
      is_paralell=%f;
    end
    if (typeof(Fz)~="list") then
      l_F=list();l_Fz(1)=Fz;Fz=l_Fz;
    end
  // common include list

    nb_cels=length(Fz);
    SNB_F=string(nb_cels);
    lc=list();
    ic=0;
    ic=ic+1;lc(ic)="/* stdio.h contains printf declaration */";
    ic=ic+1;lc(ic)="#include <stdio.h>";
    ic=ic+1;lc(ic)="/* stdlib.h contains malloc declaration */";
    ic=ic+1;lc(ic)="#include <stdlib.h>";
    ic=ic+1;lc(ic)="/* math.h contains cos declaration */";
    ic=ic+1;lc(ic)="/* do not forget to link with -lm */";
    ic=ic+1;lc(ic)="#include <math.h>";
    ic=ic+1;lc(ic)="  typedef struct {";
    ic=ic+1;lc(ic)="    int nb_cels;";
    ic=ic+1;lc(ic)="    int nb_coeffs;";
    ic=ic+1;lc(ic)="    int nb_states;";
    ic=ic+1;lc(ic)="    double *coeffs;";
    ic=ic+1;lc(ic)="    double *states;";
    ic=ic+1;lc(ic)="  }s_real_filter_"+name_struct+";";
    ic=ic+1;lc(ic)="  typedef s_real_filter_"+name_struct+" *p_real_filter_"+name_struct+" ;";
    ic=ic+1;lc(ic)="  double one_step_real_filter_"+name_struct+"(double en,p_real_filter_"+name_struct+" f) {";
    ic=ic+1;lc(ic)="    int i;";
    ic=ic+1;lc(ic)="    double *ci=f->coeffs;";
    ic=ic+1;lc(ic)="    double *xi=f->states;"; 
    if (is_paralell==%f) then
    // case of cascade cels
      ic=ic+1;lc(ic)="    double sn;";
      ic=ic+1;lc(ic)="    for (i=f->nb_cels;i>0;i--) {";
      ic=ic+1;lc(ic)="      en+=  *(ci++)*(*xi);  /* en=en-a2.xn_2*/";
      ic=ic+1;lc(ic)="      sn=   *(ci++)*(*xi);  /* sn=b2.xn_2*/";
      ic=ic+1;lc(ic)="      *(xi)=*(xi+1);        /* xn_2=xn_1*/";
      ic=ic+1;lc(ic)="      xi++;                 /* xi is now xn_1*/";
      ic=ic+1;lc(ic)="      en+=  *(ci++)*(*xi) ; /* en=en-a1.xn_1*/";
      ic=ic+1;lc(ic)="      sn+=   *(ci++)*(*xi); /* sn=sn+b1.xn_1*/";
      ic=ic+1;lc(ic)="      *(xi++)=en;           /* xn_1=en */";
      ic=ic+1;lc(ic)="      en*=   *(ci++)   ;    /* en=b0.en*/";
      ic=ic+1;lc(ic)="      en+=   sn        ;    /* en=sn+en*/";
      ic=ic+1;lc(ic)="    }/*for (i=f->nb_cels;i>0;i--) */";
      ic=ic+1;lc(ic)="    return en; ";
    else
    // case of paralell cels
      ic=ic+1;lc(ic)="    double sn,vn;";
      ic=ic+1;lc(ic)="    sn=0;";
      ic=ic+1;lc(ic)="    for (i=f->nb_cels;i>0;i--) {";
      ic=ic+1;lc(ic)="      vn=  en;  /* vn=en*/";
      ic=ic+1;lc(ic)="      vn+=  *(ci++)*(*xi);  /* vn=vn-a2.xn_2*/";
      ic=ic+1;lc(ic)="      sn+=  *(ci++)*(*xi);  /* sn=sn+b2.xn_2*/";
      ic=ic+1;lc(ic)="      *(xi)=*(xi+1);        /* xn_2=xn_1*/";
      ic=ic+1;lc(ic)="      xi++;                 /* xi is now xn_1*/";
      ic=ic+1;lc(ic)="      vn+=  *(ci++)*(*xi) ; /* vn=vn-a1.xn_1*/";
      ic=ic+1;lc(ic)="      sn+=   *(ci++)*(*xi); /* sn=sn+b1.xn_1*/";
      ic=ic+1;lc(ic)="      *(xi++)=vn;           /* xn_1=vn */";
      ic=ic+1;lc(ic)="      sn+=   *(ci++)*vn   ;    /* sn=sn+b0.vn*/";
      ic=ic+1;lc(ic)="    }/*for (i=f->nb_cels;i>0;i--) */";
      ic=ic+1;lc(ic)="    return sn; ";
    end
    ic=ic+1;lc(ic)="  } /*double one_step_real_filter_"+name_struct+"(...)*/";
    ic=ic+1;lc(ic)="  p_real_filter_"+name_struct+" get_memory_real_filter_"+name_struct+"(int nb_cels,int nb_coeffs_by_cel,int nb_states_by_cel) {";
    ic=ic+1;lc(ic)="    p_real_filter_"+name_struct+" f=malloc(sizeof(s_real_filter_"+name_struct+"));/* get memory for filter structure*/";
    ic=ic+1;lc(ic)="    f->nb_cels=nb_cels;";
    ic=ic+1;lc(ic)="    f->nb_coeffs=nb_coeffs_by_cel * nb_cels;";
    ic=ic+1;lc(ic)="    f->nb_states=nb_states_by_cel*  nb_cels;";
    ic=ic+1;lc(ic)="  /* get memory for  coeffs and  states */";
    ic=ic+1;lc(ic)="    f->coeffs=malloc(f->nb_coeffs * sizeof(double));";
    ic=ic+1;lc(ic)="    f->states=malloc(f->nb_states * sizeof(double));";
    ic=ic+1;lc(ic)="    return(f);";
    ic=ic+1;lc(ic)="  } /* p_real_filter_"+name_struct+" new_real_filter_"+name_struct+"(int nb_cels,int nb_coeffs_by_cel,int nb_states_by_cel)*/";
    ic=ic+1;lc(ic)="  void destroy_real_filter_"+name_struct+"(p_real_filter_"+name_struct+" f) {";
    ic=ic+1;lc(ic)="    if (f->nb_coeffs >0) { ";
    ic=ic+1;lc(ic)="      free((void *)f->coeffs); /* release memory for coeffs */";
    ic=ic+1;lc(ic)="    } /* if (f->nb_coeffs >0) */ ";
    ic=ic+1;lc(ic)="    if (f->nb_states >0) { ";
    ic=ic+1;lc(ic)="      free((void *)f->states); /* release memory for states */";
    ic=ic+1;lc(ic)="    } /* if (f->nb_states >0) */ ";
    ic=ic+1;lc(ic)="    free((void *)f);         /* release memory of f */";
    ic=ic+1;lc(ic)="  } /* void destroy_real_filter_"+name_struct+"(p_real_filter_"+name_struct+" f) */";

  // declaration and init of coeffs
    ld=list();
    id=0;
    id=id+1;ld(id)="  p_real_filter_"+name_struct+" new_real_filter_"+name_struct+"() {";
    id=id+1;ld(id)="  /* "+SNB_F+" cels, 5 coeffs:-a2,b2,-a1,b1,b0,  2 states xn_2,xn_1*/";
    id=id+1;ld(id)="    p_real_filter_"+name_struct+" f =get_memory_real_filter_"+name_struct+"("+SNB_F+",5,2);";
    id=id+1;ld(id)="    double *coeffs=f->coeffs;";
    id=id+1;ld(id)="    double *states=f->states;";
    z_1=poly(0,"z_1");
    for i_f=1:nb_cels,
      Fzi=Fz(i_f); 
      Nzi=numer(Fzi);
      Dzi=denom(Fzi);
      simp_mode(%f); 
      [Fqi]=hornerij(Nzi/Dzi,1/z_1,"ld");
      Nqi=numer(Fqi);
      Dqi=denom(Fqi);
      order=degree(Dqi);
      b2=coeff(Nqi,2);
      b1=coeff(Nqi,1);
      b0=coeff(Nqi,0);
      a2=coeff(Dqi,2);
      a1=coeff(Dqi,1);
      a0=coeff(Dqi,0);
      Si=string(i_f-1);
    // declarations
      id=id+1;ld(id)="    *(coeffs++)="+string(-a2)+"; /* coeffs -a2["+string(i_f)+"] */";
      id=id+1;ld(id)="    *(coeffs++)="+string( b2)+"; /* coeffs +b2["+string(i_f)+"] */";
      id=id+1;ld(id)="    *(coeffs++)="+string(-a1)+"; /* coeffs -a1["+string(i_f)+"] */";
      id=id+1;ld(id)="    *(coeffs++)="+string( b1)+"; /* coeffs +b1["+string(i_f)+"] */";
      id=id+1;ld(id)="    *(coeffs++)="+string( b0)+"; /* coeffs +b0["+string(i_f)+"] */";
      id=id+1;ld(id)="    *(states++)=0;/* xn_2["+string(i_f)+"]=0 */";
      id=id+1;ld(id)="    *(states++)=0;/* xn_1["+string(i_f)+"]=0 */";
    end // for i_f
    id=id+1;ld(id)=  "    return f;";
    id=id+1;ld(id)=  "  }/* p_real_filter_"+name_struct+" new_real_filter_"+name_struct+"() */";
    l_test=get_real_test_code();
    ld=lstcat(ld,l_test);
    l_specific=ld;
    if (lhs>1) then
      l_common=lc;
    end
  endfunction
  function new_l=suppress_c_remarques(l)
    if SUPPRESS_REMARQUES==%f then
      new_l=l;
      return
    end
    k=0;new_l=list();
    for i=1:length(l),
      s=l(i);
      s=stripblanks(s,%t);
      index=strindex(s,"/*");
      do_not_suppress= min(index)~= 1 ;
      if do_not_suppress==%t then
        k=k+1;new_l(k)=l(i);
      end
    end // for =1:length(l),
  endfunction

  function l=get_list_array_coeffs(type_var,name_var,coeffs)
    nb_coeffs=max(size(coeffs));
    l=list();
    for i=1:nb_coeffs,
      l(i+1)=string(coeffs(i));
      if (i<nb_coeffs) then
       l(i+1)=l(i+1)+",";
      else
       l(i+1)=l(i+1)+"};"
      end
    end
    l=ident_list(l,"    ");
    l(1)="const "+type_var+" "+name_var+"["+string(nb_coeffs)+"]={";
  endfunction
