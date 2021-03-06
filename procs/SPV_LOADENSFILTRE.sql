SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_LOADENSFILTRE
-- Paramètre d'entrée	: @v_idEnsFiltre : Identifiant de l'ensemble de filtre
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK : le formatage s'est bien passé
--			  @v_libFiltre : chaîne Ensemble filtre formatée
--			  @v_listParametre : Chaîne formatée constituée de tous les paramètres 
--			  de l'ensemble de filtres (format:'Par1,Par2,Par3,...,Parn,')  
-- Descriptif		: Cette procédure formate la chaîne where d'une requête SQL
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_LOADENSFILTRE]
	@v_idEnsFiltre integer,
	@v_libFiltre varchar(8000) out,
	@v_listParametre varchar(100)out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_typeFiltre tinyint
declare @v_idSsEnsFiltre integer
declare @v_idLieur tinyint
declare @v_libelleLieur varchar(50)
declare @v_codeRetour integer
declare @v_idCritere integer
declare @v_idVariable integer
declare @v_idOperateur tinyint
declare @v_valeurFiltre varchar(40)
declare @v_libelleOperateur varchar(40)
declare @v_champFiltre varchar(40)
declare @v_sqlWhere varchar(8000)
declare @v_charIndex integer
declare @v_parametre varchar(100)

-- déclaration des constantes
declare @TYPE_FILTRE bit
declare @TYPE_ENSFILTRE bit
declare @CODE_OK tinyint
declare @TYPE_CALCULE bit

-- définition des constantes
set @TYPE_FILTRE = 0
set @TYPE_ENSFILTRE = 1
set @CODE_OK = 0
set @TYPE_CALCULE = 1

-- initialisation de la variable de retour
set @v_codeRetour = @CODE_OK
set @v_sqlWhere = ''
set @v_listParametre = ''

-- récupération des filtres de l'ensemble de filtres
declare c_selectFiltre CURSOR LOCAL for
select LCN_TypeItem,LCN_IdSsLstCondition,LCN_IdLieur,LIR_Libelle,CDT_IdCritere,CDT_IdOperateur,CDT_Valeur,
OPR_Libelle,CRI_Champ,VAR_Id 
from LISTE_CONDITION left outer join LIEUR on LCN_IdLieur = LIR_IdLieur
                    left outer join CONDITION on LCN_IdCondition=CDT_IdCondition
                    left outer join CRITERE on CDT_IdCritere=CRI_IdCritere
                    left outer join VARIABLE on CDT_Variable=VAR_Id
                    left outer join OPERATEUR on CDT_IdOperateur = OPR_IdOperateur
where LCN_IdLstCondition = @v_idEnsFiltre
order by LCN_Position

-- ouverture du curseur de filtres
open c_selectFiltre

fetch next from  c_selectFiltre INTO @v_typeFiltre,@v_idSsEnsFiltre,@v_idLieur,@v_libelleLieur,@v_idCritere,
                                     @v_idOperateur,@v_valeurFiltre,@v_libelleOperateur,@v_champFiltre,@v_idVariable
while (@@FETCH_STATUS = 0)
begin
  set @v_libFiltre = ''
  set @v_parametre = ''

  if (@v_typeFiltre = @TYPE_FILTRE)
  begin
    --------------------------------------------------
    --                   FILTRE UNITAIRE
    --------------------------------------------------
    if (@v_idVariable is Not NULL)
    begin
      -- Il s'agit d'un filtre sur une variable
      set @v_champFiltre='VARIABLE'+REPLACE(cast(@v_idVariable as varchar), '-', '_')+'V'
    end
    else
    begin
      -- Il s'agit d'un filtre sur un critère
      if (@v_champFiltre is NULL)
      begin
        set @v_champFiltre='CRITERE'+REPLACE(cast(@v_idCritere as varchar), '-', '_')+'C'
      end
    end
    
    set @v_libFiltre = @v_champFiltre + ' ' + @v_libelleOperateur + ' ' + QUOTENAME(@v_valeurfiltre, '''')

    -- Récupération des éventuels paramètres dans les valeurs des filtres
    select @v_charIndex = CHARINDEX(':[', @v_valeurfiltre)
    if (@v_charIndex <> 0)
    begin
      select @v_parametre = SUBSTRING(@v_valeurfiltre, @v_charIndex + 2,LEN(@v_valeurfiltre) - @v_charindex -2)+','
    end
  end
  else
  begin
    --------------------------------------------------
    --                   ENSEMBLE de FILTRES
    --------------------------------------------------
    exec @v_codeRetour = SPV_LOADENSFILTRE @v_idSsEnsFiltre,@v_libFiltre out,@v_parametre out
  end

  if (@v_idLieur is NULL)
  begin
    set @v_sqlWhere='('+@v_libFiltre+')'   
  end
  else
  begin
    set @v_sqlWhere= @v_sqlWhere + ' ' + @v_libelleLieur + ' ('+@v_libFiltre+')'   
  end
  
  if (@v_parametre <> '')
  begin
    set @v_listParametre=@v_listParametre+@v_parametre
  end 

  if (@v_codeRetour <> @CODE_OK)
  begin
    break
  end 
  -- passage au filtre suivant
  fetch next from  c_selectFiltre INTO @v_typeFiltre,@v_idSsEnsFiltre,@v_idLieur,@v_libelleLieur,@v_idCritere,
                                       @v_idOperateur,@v_valeurFiltre,@v_libelleOperateur,@v_champFiltre,@v_idVariable
end

-- fermeture du curseur de filtres
close c_selectFiltre
deallocate c_selectFiltre


if (@v_codeRetour = @CODE_OK)
begin
  set @v_libFiltre = @v_sqlWhere
end
else
begin
  set @v_libFiltre =''
end

return @v_codeRetour



