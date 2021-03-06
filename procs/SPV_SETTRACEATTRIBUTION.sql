SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETTRACEATTRIBUTION
-- Paramètre d'entrée	: @v_typeTrace    : Type de la trace à écrire
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'operation s'est executée correctement
--			    - @CODE_KO_SQL : Une erreur SQL s'est produite lors de l'operation
--			    - @CODE_KO_PARAM : Le type de trace n'est pas connu
-- Descriptif           : Cette procédure permet d'ajouter une trace attribution
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 01/11/2004									
-- Auteur		: S.Loiseau									
-- Libellé		: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 07/06/2005									
-- Auteur		: S. Loiseau									
-- Libellé		: Modification de la procédure car les le trigramme TRA de la table
--                        TRACE_ATTRIBUTION était en doublon
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETTRACEATTRIBUTION]
	@v_typeTrace integer
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_codeRetour integer

-- déclaration des constantes de code retour 
declare @CODE_OK integer
declare @CODE_KO_SQL integer
declare @CODE_KO_PARAM integer

-- déclaration des constantes de type de trace attibution
declare @START tinyint    -- Start attribution
declare @STOP tinyint     -- Stop attribution

--définition des constantes de code retour 
set @CODE_OK = 0
set @CODE_KO_SQL = 13
set @CODE_KO_PARAM = 8

-- définition des constantes de type de trace attibution
set @START =14
set @STOP = 15

-- initialisation des variables
set @v_codeRetour = @CODE_OK

-- controle des types
if     (@v_typeTrace<>@START)
   and (@v_typeTrace<>@STOP)
begin
  set @v_codeRetour = @CODE_KO_PARAM
end

if @v_codeRetour = @CODE_OK
begin
  -- Ecriture des traces de start attribution
  if (@v_typeTrace = @START)
  begin
    insert into TRACE_ATTRIBUTION(TAT_Date,TAT_TypeTrc) values(getDate(),@START)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
  -- Ecriture des traces de start attribution
  else if (@v_typeTrace = @STOP)
  begin
    insert into TRACE_ATTRIBUTION(TAT_Date,TAT_TypeTrc) values(getDate(),@STOP)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
end


return @v_codeRetour 		








