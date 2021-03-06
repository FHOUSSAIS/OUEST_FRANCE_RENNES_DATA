SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ENERGIE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_cre_idagv : Identifiant AGV
--			  @v_cre_idobj : Identifiant poste
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion de l'affectation des postes d'énergie
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ENERGIE]
	@v_action smallint,
	@v_cre_idagv tinyint,
	@v_cre_idobj smallint,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int
	
-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME int

-- Définition des constantes
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME = 3

-- Initialisation des variables
	SET @v_retour = 113
	SET @v_error = 0

	BEGIN TRAN
	IF @v_action = 0
	BEGIN
		DELETE BATTERIE WHERE BAT_ID IN (2 * @v_cre_idagv - 1, 2 * @v_cre_idagv)
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDAGV = @v_cre_idagv AND CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_TYPE = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ = @v_cre_idobj AND CRE_IDAGV = @v_cre_idagv)
				BEGIN
					INSERT INTO CONFIG_RSV_ENERGIE(CRE_IDOBJ, CRE_IDAGV) VALUES (@v_cre_idobj, @v_cre_idagv)
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
				ELSE
					SET @v_retour = 0
			END
		END
	END 
	ELSE IF @v_action = 2
	BEGIN
		DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ = @v_cre_idobj AND CRE_IDAGV = @v_cre_idagv
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

