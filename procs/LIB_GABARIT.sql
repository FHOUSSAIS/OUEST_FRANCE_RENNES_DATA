SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: LIB_GABARIT
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_gbr_hauteur : Hauteur
--			  @v_gbr_largeur : Largeur
--			  @v_gbr_longueur : Longueur
--			  @v_tra_id : Identifiant traduction
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_gbr_id : Identifiant
--			  @v_retour : Code de retour
-- Descriptif		: Gestion des gabarits
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 05/02/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_GABARIT]
	@v_action smallint,
	@v_gbr_id tinyint out,
	@v_gbr_hauteur smallint,
	@v_gbr_largeur smallint,
	@v_gbr_longueur smallint,
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
			SELECT @v_gbr_id = ISNULL(MAX(GBR_ID), 0) + 1 FROM GABARIT
			INSERT INTO GABARIT (GBR_ID, GBR_TRADUCTION) VALUES (@v_gbr_id, @v_tra_id)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE GABARIT SET GBR_HAUTEUR = @v_gbr_hauteur, GBR_LARGEUR = @v_gbr_largeur, GBR_LONGUEUR = @v_gbr_longueur
			WHERE GBR_ID = @v_gbr_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CHARGE WHERE CHG_GABARIT = @v_gbr_id)
		BEGIN
			DELETE GABARIT WHERE GBR_ID = @v_gbr_id
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

