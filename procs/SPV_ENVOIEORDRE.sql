SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procedure		: SPV_ENVOIEORDRE
-- Paramètre d'entrée	: @v_ord_idordre : Identifiant ordre
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Envoi de l'ordre suivant
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_ENVOIEORDRE]
	@v_ord_idordre int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de descriptions
DECLARE
	@DESC_ENVOYE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @DESC_ENVOYE = 13

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_OK

	BEGIN TRAN
	UPDATE ORDRE_AGV SET ORD_DSCETAT = @DESC_ENVOYE WHERE ORD_IDORDRE = @v_ord_idordre
	SET @v_error = @@ERROR
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = @CODE_KO_SQL
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour


