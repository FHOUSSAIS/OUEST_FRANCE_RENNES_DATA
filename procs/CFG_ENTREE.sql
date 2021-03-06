SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ENTREE
-- Paramètre d'entrées	: @v_ent_id : Identifiant
--			  @v_ent_null : Null
--			  @v_ent_valeur : Valeur
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des paramètres d'entrées d'une opération
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 29/09/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------
-- Date			: 05/04/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Finalisation du synoptique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ENTREE]
	@v_ent_id int,
	@v_ent_null bit,
	@v_ent_valeur varchar(64),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	UPDATE ENTREE SET ENT_NULL = @v_ent_null, ENT_VALEUR = @v_ent_valeur WHERE ENT_ID = @v_ent_id
	SELECT @v_error = @@ERROR
	IF @v_error = 0
	BEGIN
		IF ((@v_ent_null = 0) AND (@v_ent_valeur IS NULL))
			INSERT INTO VALEUR (VAL_ENTREE, VAL_SOUS_MENU_CONTEXTUEL)
				SELECT @v_ent_id, SMC_ID FROM ENTREE, OPERATION, SOUS_MENU_CONTEXTUEL
				WHERE ENT_ID = @v_ent_id AND OPE_ID = ENT_OPERATION AND SMC_OPERATION = OPE_ID
		ELSE
			DELETE VALEUR WHERE VAL_ENTREE = @v_ent_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

