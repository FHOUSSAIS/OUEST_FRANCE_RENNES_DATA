SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON





-----------------------------------------------------------------------------------------
-- Procédure		: SPV_TRAITEMESS
-- Paramètre d'entrée	: @v_abo_id : Identifiant abonné
--			  @v_mes_id : Identifiant message
-- Paramètre de sortie	: @v_abn_procedure : Procédure
-- Descriptif		: Traitement des messages
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_TRAITEMESS]
	@v_abo_id int,
	@v_mes_id int,
	@v_abn_procedure varchar(32) out,
	@v_abn_timeout int out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int,
	@CODE_KO int,
	@CODE_KO_INEXISTANT int,
	@CODE_KO_INCONNU int

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INEXISTANT = 4
	SELECT @CODE_KO_INCONNU = 7

-- Initialisation de la variable de retour
	SELECT @v_retour = @CODE_KO

	IF EXISTS (SELECT 1 FROM ABONNEMENT WHERE ABN_ABONNE = @v_abo_id AND ABN_MESSAGE = @v_mes_id)
	BEGIN
		SELECT @v_abn_procedure = ABN_PROCEDURE, @v_abn_timeout = ABN_TIMEOUT FROM ABONNEMENT
			WHERE ABN_ABONNE = @v_abo_id AND ABN_MESSAGE = @v_mes_id
		IF @v_abn_procedure IS NOT NULL AND EXISTS (SELECT 1 FROM sysobjects WHERE xtype = 'P' AND name = PARSENAME(@v_abn_procedure, 1))
		BEGIN
			SELECT AMA_ATTRIBUT, AMA_PARAMETRE
				FROM ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
			SELECT @v_retour = @CODE_OK
		END
		ELSE
		BEGIN
			SELECT NULL
			SELECT @v_retour = @CODE_KO_INCONNU
		END
	END
	ELSE
	BEGIN
		SELECT NULL
		SELECT @v_retour = @CODE_KO_INEXISTANT
	END
	RETURN @v_retour


