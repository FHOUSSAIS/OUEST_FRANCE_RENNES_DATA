SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF


----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETTRACEZONE
-- Paramètre d'entrée	: @v_idZone : Identifiant de la zone
--			  @vp_typeTrace : Type de la trace à écrire
--			  @v_dscTrace : Données complementaires de la trace
-- Paramètres de sortie : Code de retour par défaut
--			    - @CODE_OK : L'operation s'est executee correctement
--			    - @CODE_KO_SQL : Une erreur SQL s'est produite lors de l'operation
--			    - @CODE_KO_PARAM : Le type de trace n'est pas connu
-- Descriptif           : Cette procédure permet d'ajouter une trace de charge
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 17/03/2005
-- Auteur		: S.Loiseau
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETTRACEZONE]
	@v_idZone integer,
	@v_typeTrace int,
	@v_dscTrace varchar(50)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des constantes de code retour 
declare @CODE_OK integer
declare @CODE_KO_SQL integer
declare @CODE_KO_PARAM integer

--définition des constantes de code retour 
set @CODE_OK = 0
set @CODE_KO_SQL = 13
set @CODE_KO_PARAM = 8

-- déclaration des constantes de type de trace zone
declare @CHANGE_BOOKING tinyint
declare @CHANGE_CAPACITE_MIN tinyint
declare @CHANGE_CAPACITE_MAX tinyint

-- définition des constantes de type de trace zone
set @CHANGE_BOOKING = 16
set @CHANGE_CAPACITE_MIN = 17
set @CHANGE_CAPACITE_MAX = 18

--déclaration des variables
declare @v_codeRetour integer

-- initialisation des variables
set @v_codeRetour = @CODE_OK

-- controle des types
if      (@v_typeTrace<>@CHANGE_BOOKING)
    and (@v_typeTrace<>@CHANGE_CAPACITE_MIN)
    and (@v_typeTrace<>@CHANGE_CAPACITE_MAX)
begin
  set @v_codeRetour = @CODE_KO_PARAM
end


if @v_codeRetour = @CODE_OK
begin
  -- Ecriture des traces de changement de booking
  if (@v_typeTrace = @CHANGE_BOOKING)
  begin
    insert into TRACE_ZONE(TRZ_Date,TRZ_TypeTrc,TRZ_DscTrc,TRZ_IdZone)
    values (getDate(),@CHANGE_BOOKING,@v_dscTrace,@v_idZone)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
  
  -- Ecriture des traces de changement de capacité minimale
  else if (@v_typeTrace = @CHANGE_CAPACITE_MIN)
  begin
    insert into TRACE_ZONE(TRZ_Date,TRZ_TypeTrc,TRZ_DscTrc,TRZ_IdZone)
    values (getDate(),@CHANGE_CAPACITE_MIN,@v_dscTrace,@v_idZone)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end

  -- Ecriture des traces de changement de capacité maximale
  else if (@v_typeTrace = @CHANGE_CAPACITE_MAX)
  begin
    insert into TRACE_ZONE(TRZ_Date,TRZ_TypeTrc,TRZ_DscTrc,TRZ_IdZone)
    values (getDate(),@CHANGE_CAPACITE_MAX,@v_dscTrace,@v_idZone)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end 
end


return @v_codeRetour 		


