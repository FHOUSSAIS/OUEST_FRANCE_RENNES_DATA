SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procedure		: SPV_EXECUTEREGLEEVALUATION
-- Paramètre d'entrée	: @v_iag_id : Identifiant de l'AGV
--			  @v_sql : chaîne SQL à exécuter
--			  @v_variable : Liste des variables fixes et calculées à évaluer
--			  dans la requête sql
--			  format : 'v1,v2,...,vn,'
-- Paramètre de sortie	: Valeur par défaut :
--			    - @CODE_OK : L'évaluation de la règle s'est exécutée correctement
--			    - @CODE_KO_INCONNU : Une des variables de la liste n'existe pas dans la table variable
--			    - @CODE_KO_PARAM : la règle d'évaluation ne contient aucune variable
--			  @v_valeurExpression:
--			    - 0 : l'expression est fausse
--			    - 1 : l'expression est vrai
-- Descriptif		: Cette procédure exécute une règle de type évaluation expression.
-----------------------------------------------------------------------------------------

CREATE  PROCEDURE [dbo].[SPV_EXECUTEREGLEEVALUATION] @v_iag_id tinyint, @v_sql varchar(8000), @v_variable varchar(4000)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des variables
declare @v_codeRetour integer
declare @v_charindex integer
declare @v_idVariable integer
declare @v_strVariable varchar(100)
declare @v_valueVariable varchar(4000)


--déclaration des constantes
declare @CODE_OK tinyint
declare @CODE_KO_INCONNU tinyint
declare @CODE_KO_PARAM tinyint

-- définition des constantes
set @CODE_OK = 0
set @CODE_KO_INCONNU = 7
set @CODE_KO_PARAM = 8

-- initialisation de la variable de retour
set @v_codeRetour = @CODE_OK

-- parcours de la liste des variables de la règle et remplacement de ces variables
if (@v_variable is NOT NULL)
begin
  select @v_charindex = CHARINDEX(',', @v_variable)
  while (@v_charindex <> 0)
  begin
    select @v_idVariable = SUBSTRING(@v_variable, 1, @v_charindex - 1)
    select @v_strVariable='VARIABLE' + REPLACE(CONVERT(varchar, @v_idvariable),'-', '_') + 'V'
    select @v_valueVariable = NULL
    select @v_valueVariable = isNull(VAR_VALUE,'NULL') FROM VARIABLE WHERE VAR_ID = @v_idVariable
    if (@v_valueVariable is not NULL)
    begin
      select @v_sql=REPLACE(@v_sql,@v_strVariable ,@v_valueVariable)
    end
    else
    begin
      -- la variable étudiée n'existe pas dans la table VARIABLE
      set @v_codeRetour=@CODE_KO_INCONNU
      break
    end 

    -- passage à la variable suivante
    select @v_variable = SUBSTRING(@v_variable, @v_charindex + 1, LEN(@v_variable) - @v_charindex)
    select @v_charindex = CHARINDEX(',', @v_variable)
  end
end
else
begin
  -- la règle d'évaluation est vide
  set @v_codeRetour=@CODE_KO_PARAM
end


if (@v_codeRetour = @CODE_OK)
begin
  select @v_sql = 'Select case when '+ @v_SQL +' then 1 else 0 end as RES_EVALUATION'
end
else
begin
  select @v_sql='Select 0 as RES_EVALUATION'
end

exec(@v_sql)


return @v_codeRetour


