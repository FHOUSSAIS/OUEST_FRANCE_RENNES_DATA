SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: LIB_EMBALLAGE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_emb_hauteur : Hauteur
--			  @v_emb_largeur : Largeur
--			  @v_emb_longueur : Longueur
--			  @v_emb_engagement : Offset engagement
--			  @v_tra_id : Identifiant traduction
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_emb_id : Identifiant
--			  @v_retour : Code de retour
-- Descriptif		: Gestion des emballages
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 05/02/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_EMBALLAGE]
	@v_action smallint,
	@v_emb_id tinyint out,
	@v_emb_hauteur smallint,
	@v_emb_largeur smallint,
	@v_emb_longueur smallint,
	@v_emb_engagement smallint,
	@v_tra_id int,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
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
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			SELECT @v_emb_id = ISNULL(MAX(EMB_ID), 0) + 1 FROM EMBALLAGE
			INSERT INTO EMBALLAGE (EMB_ID, EMB_TRADUCTION) VALUES (@v_emb_id, @v_tra_id)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE EMBALLAGE SET EMB_HAUTEUR = @v_emb_hauteur, EMB_LARGEUR = @v_emb_largeur, EMB_LONGUEUR = @v_emb_longueur, EMB_ENGAGEMENT = @v_emb_engagement
			WHERE EMB_ID = @v_emb_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CHARGE WHERE CHG_EMBALLAGE = @v_emb_id)
		BEGIN
			DELETE EMBALLAGE WHERE EMB_ID = @v_emb_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE
			SET @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

