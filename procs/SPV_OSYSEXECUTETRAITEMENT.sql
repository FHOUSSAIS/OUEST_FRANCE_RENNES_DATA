SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEXECUTETRAITEMENT
-- Paramètre d'entrée	: @vp_idTerm : Identifiant du terminal concerné
--			  @vp_idTrait : Identifiant du traitement à effectuer
-- Paramètre de sortie	: Entier calculé par le traitement.
--			  - Soit un nouvel état (traitement de saisie, de fonction, de Cab)
--			  - Soit un identifiant de traduction (traitement de message)	
-- Descriptif		: Cette procédure appelle une procédure stockée spécifique permettant d'effectuer un calcul spécifique
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 29/06/2005
-- Auteur		: M. Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_OSYSEXECUTETRAITEMENT]
	@vp_idTerm tinyint,
	@vp_idTrait tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_resCalcul integer
declare @v_sp varchar(120)
declare @v_valueParam varchar(120)
declare @v_paramEntree varchar(120)
declare @v_sql varchar(256)
declare @v_idAutomate tinyint

-- initialisation de la variable code de retour
set @v_resCalcul=0

-- Récuperation du numéro d'automate
select @v_idAutomate = isNull(OTO_AUTOMATE, 0) from OSYS_TERMINAL where OTO_ID = @vp_idTerm

-- récupération du nom de la procédure stockée associée à la saisie ainsi que de ses paramètres
declare c_selectProcedure CURSOR LOCAL FOR
select OTR_PROCEDURE, OPT_PARAM
from OSYS_TRAITEMENT left outer join OSYS_PARAMETRE_TRAITEMENT on (OTR_ID = OPT_ID)
where (OTR_ID = @vp_idTrait)
order by OPT_POSITION

-- ouverture du curseur
open c_selectProcedure

fetch next from c_selectProcedure INTO @v_sp, @v_valueParam
while (@@FETCH_STATUS = 0)
begin
  -- construction de la chaîne des paramètres d'entrée
  if (@v_paramEntree is not NULL)
  begin
    set @v_paramEntree = @v_paramEntree + ',' + @v_valueParam
  end
  else
  begin
    set @v_paramEntree = @v_valueParam
  end
  -- passage au paramètre suivant
  fetch next from c_selectProcedure INTO @v_sp, @v_valueParam
end

-- fermeture du curseur
close c_selectProcedure
deallocate c_selectProcedure

if (@v_sp is NULL)
begin
  -- Pb de calcul d'état suivant
  set @v_resCalcul=0
end
else
begin
  if (@v_paramEntree is NULL)
  begin
    -- appel de la procédure stockée sans paramètres
    exec @v_resCalcul = @v_sp @vp_idTerm , @v_idAutomate, @vp_idTrait
  end
  else
  begin
    -- appel de la procédure stockée avec les paramètres
    set @v_sql = 'declare @v_resCalcul int exec @v_resCalcul = '+@v_sp+' '+CONVERT(varchar, @vp_idTerm )+','+CONVERT(varchar, @v_idAutomate )+','+CONVERT(varchar, @vp_idTrait )+', ' +@v_paramEntree+' update OSYS_TRAITEMENT set OTR_VALUE = @v_resCalcul where OTR_ID = '+CONVERT(varchar, @vp_idTrait )
    EXEC (@v_sql)
    select @v_resCalcul = OTR_VALUE from OSYS_TRAITEMENT where OTR_ID = @vp_idTrait
  end
end

return @v_resCalcul



