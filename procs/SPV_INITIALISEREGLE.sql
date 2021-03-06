SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procedure		: SPV_INITIALISEREGLE
-- Paramètre d'entrée	: @v_idRegle
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'initialisation s'est exécutée correctement
--			    - @CODE_KO_SQL : Une erreur s'est produite lors de l'initialisation
--			  @v_sql : Chaîne SQL servant à l'exécution de la règle
--			  @v_listCritereCalcule : Chaîne formatée constituée des identifiants des
--			  critères calculés de la règle (format : 'IdCrit1,IdCrit2,IdCrit3,...,IdCritn,') 
--			  @v_listVariableCalculee : Chaîne formatée constituée des identifiants des
--			  variables calculées de la règle (format : 'IdVar1,IdVar2,IdVar3,...,IdVarn,') 
--			  @v_listCritere : Chaîne formatée constituée des identifiants des
--			  critères (sans champ)de la règle (format : 'IdCrit1,IdCrit2,IdCrit3,...,IdCritn,') 
--			  @v_listVariable : Chaîne formatée constituée des identifiants des
--			  variables de la règle (variables fixes et calculées) (format : 'IdVar1,IdVar2,IdVar3,...,IdVarn,') 
--			  @v_listParametre : Chaîne formatée constituée de tous les paramètres de le règle
--			  (format : 'Par1,Par2,Par3,...,Parn,')  
-- Descriptif		: Cette procédure initialise une règle c'est à dire :
--			    - Construit la chaîne SQL qui sera utilisée pour l'exécution de la règle
--			    - Stocke les identifiants des critères calculés afin de pouvoir les exécuter
--			    au moment de l'exécution de la règle.
--			    - Stocke les identifiants des variables calculées afin de pouvoir les exécuter
--			    au moment de l'exécution de la règle.
--			    - Stocke les identifiants de tous les critères fixes et calculés de la règle
--			    (seuls ceux associés à aucun champ) en vue de l'exécution de la règle
--			    - Stocke les identifiants de toutes les variables fixes et calculées de la règle
--			    en vue de l'exécution de la règle
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_INITIALISEREGLE]
@v_idRegle integer,
@v_sql varchar(8000)out,
@v_listCritereCalcule varchar(1000)out,
@v_listVariableCalculee varchar(1000) out,
@v_listCritere varchar(1000)out,
@v_listVariable varchar(1000) out,
@v_listParametre varchar(1000) out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des variables
declare @v_idCritere integer
declare @v_idVariable integer
declare @v_champCritere varchar(40)
declare @v_libelleSens varchar(10)
declare @v_sqlOrderBy varchar(8000) 
declare @v_sqlWhere varchar(8000)
declare @v_codeRetour tinyint
declare @v_idEnsFiltre integer
declare @v_type tinyint

-- déclaration des constantes
declare @TYPE_FIXE tinyint
declare @TYPE_CALCULE tinyint
declare @CODE_OK tinyint
declare @CODE_KO_SQL tinyint

-- définition des constantes
set @TYPE_FIXE=0
set @TYPE_CALCULE=1
set @CODE_OK=0
set @CODE_KO_SQL=13

-- initialisation des variables
set @v_sqlOrderBy           = ''
set @v_sqlWhere             = ''
set @v_sql                  = '' 
set @v_listCritereCalcule   = ''
set @v_listVariableCalculee = ''
set @v_listCritere          = ''
set @v_listVariable         = ''
set @v_listParametre        = ''

-- initialisation de la variable de code retour
set @v_codeRetour = @CODE_OK

------------------------------------------------------------------------------------
--              CONSTRUCTION DE LA CHAÎNE ORDER BY
------------------------------------------------------------------------------------

-- récupération des tris de la règle
declare c_SelectTri CURSOR LOCAL for
select CRI_IdCritere,CRI_Champ,SEN_Libelle
from CRITERE,SENS,TRI,ASSOCIATION_REGLE_TRI
where (ART_IdTri=TRI_IdTri)and(TRI_IdSens=SEN_IdSens)and(TRI_IdCritere=CRI_IdCritere)and(ART_IdRegle=@v_idRegle)
order by ART_POSITION

-- ouverture du curseur de tri
open c_SelectTri

fetch next from  c_SelectTri INTO @v_idCritere,@v_champCritere,@v_libelleSens
while (@@FETCH_STATUS = 0)
begin
  if (@v_champCritere is NULL)
  begin
    set @v_champCritere='CRITERE'+REPLACE(cast(@v_idCritere as varchar), '-', '_')+'C'
  end

  -- construction de la chaîne order by
  if (@v_sqlOrderBy = '')
  begin
    -- 1ère élément de tri du order by
    set @v_sqlOrderBy ='order by '+@v_champCritere+ ' '+@v_libelleSens
  end
  else
  begin
    -- nième élément de tri du order by
    set @v_sqlOrderBy =@v_sqlOrderBy+','+@v_champCritere+ ' '+@v_libelleSens
  end

  fetch next from  c_SelectTri INTO @v_idCritere,@v_champCritere,@v_libelleSens
end

-- fermeture du curseur de tri
close c_SelectTri
deallocate c_SelectTri


------------------------------------------------------------------------------------
--              CONSTRUCTION DE LA CHAÎNE WHERE
------------------------------------------------------------------------------------

-- récupération de l'ensemble de filtres de la règle
select @v_idEnsFiltre=ARC_IdLstCondition 
from ASSOCIATION_REGLE_CONDITION
where (ARC_IdRegle=@v_idRegle)and(ARC_Type=1)

if (@v_idEnsFiltre is not NULL)
begin
  exec @v_codeRetour = SPV_LOADENSFILTRE @v_idEnsFiltre,@v_sqlWhere out,@v_listParametre out
  if (@v_codeRetour = @CODE_OK)
  begin  
    if (@v_sqlWhere <> '')
    begin
      set @v_sqlWhere = '(' + @v_sqlWhere +') ' 
    end
  end 
end

if (@v_codeRetour = @CODE_OK)
begin
  set @v_sql=@v_sqlWhere+@v_sqlOrderBy
end

if (@v_codeRetour = @CODE_OK)
begin
  ----------------------------------------------------------------------------------
  --              RECUPERATION DES IDENTIFIANTS DE CRITERES DE LA REGLE
  ----------------------------------------------------------------------------------
  declare c_SelectCritere CURSOR LOCAL for
  select  distinct CRI_IdCritere,CRI_IdType,CRI_Champ
  from  CRITERE 
  where ((CRI_IdCritere in (select TRI_IdCritere from TRI,ASSOCIATION_REGLE_TRI where (TRI_IdTRI=ART_IdTRI)and(ART_IdRegle = @v_idRegle)))
  or (CRI_IdCritere in (select CDT_IdCritere from CONDITION, LISTE_CONDITION, ASSOCIATION_REGLE_CONDITION
                        where (LCN_IdCondition = CDT_IdCondition)and(ARC_IdLstCondition = LCN_IdLstCondition)and(ARC_IdRegle = @v_idRegle))))                 
      
  -- ouverture du curseur des critères
  open c_SelectCritere

  fetch next from  c_SelectCritere INTO @v_idCritere,@v_type,@v_champCritere
  while (@@FETCH_STATUS = 0)
  begin
    if (@v_champCritere is NULL)
    begin
      set @v_listCritere=@v_listCritere+cast(@v_idCritere as varchar)+','
    end 
    if (@v_type = @TYPE_CALCULE)
    begin 
      set @v_listCritereCalcule=@v_listCritereCalcule+cast(@v_idCritere as varchar)+','
    end
    fetch next from  c_SelectCritere INTO @v_idCritere,@v_type,@v_champCritere
  end

  -- fermeture du curseur des critères 
  close c_SelectCritere
  deallocate c_SelectCritere


  ----------------------------------------------------------------------------------
  --              RECUPERATION DES IDENTIFIANTS DE VARIABLES DE LA REGLE
  ----------------------------------------------------------------------------------
  declare c_SelectVariable CURSOR LOCAL for
  select distinct VAR_Id,VAR_Type
  from VARIABLE,CONDITION, LISTE_CONDITION, ASSOCIATION_REGLE_CONDITION
  where (LCN_IdCondition = CDT_IdCondition)and(ARC_IdLstCondition = LCN_IdLstCondition)and(ARC_IdRegle = @v_idRegle)
  and (CDT_Variable = VAR_Id) 

  -- ouverture du curseur des variables
  open c_SelectVariable

  fetch next from  c_SelectVariable INTO @v_idVariable,@v_type
  while (@@FETCH_STATUS = 0)
  begin
    set @v_listVariable=@v_listVariable+cast(@v_idVariable as varchar)+','
    if (@v_type = @TYPE_CALCULE)
    begin
      set @v_listVariableCalculee=@v_listVariableCalculee+cast(@v_idVariable as varchar)+','
    end
    fetch next from  c_SelectVariable INTO @v_idVariable,@v_type
  end

  -- fermeture du curseur des variables
  close c_SelectVariable
  deallocate c_SelectVariable
end



if (@v_codeRetour <> @CODE_OK)
begin
  set @v_codeRetour = @CODE_KO_SQL
end

return @v_codeRetour





