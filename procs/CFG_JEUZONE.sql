SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_JEUZONE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_jer_idjeu : Identifiant
--			  @v_jer_libelle : Libelle
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des jeux de règles
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_JEUZONE]
	@v_action smallint,
	@v_jez_idjeu int,
	@v_jez_libelle varchar(8000),
	@v_lan_id varchar(3),
	@v_tra_id int out,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_jez_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			INSERT INTO JEU_ZONE (JEZ_IDJEU, JEZ_IDTRADUCTION) SELECT (SELECT CASE SIGN(MIN(JEZ_IDJEU)) WHEN -1 THEN MIN(JEZ_IDJEU) - 1 ELSE -1 END FROM JEU_ZONE), @v_tra_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SELECT @v_jez_idjeu = MIN(JEZ_IDJEU) FROM JEU_ZONE
				INSERT INTO ASSOCIATION_ZONE_JEU_ZONE (AZJ_JEU_ZONE, AZJ_ZONE, AZJ_CAP_MIN, AZJ_CAP_MAX, AZJ_BOOKING) SELECT JEZ_IDJEU, ZNE_ID, ZNE_CAP_MIN, ZNE_CAP_MAX, ZNE_BOOKING FROM ZONE, JEU_ZONE WHERE JEZ_IDJEU = @v_jez_idjeu
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE LIBELLE SET LIB_LIBELLE = @v_jez_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_ZONE_JEU_ZONE WHERE AZJ_JEU_ZONE = @v_jez_idjeu
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE JEU_ZONE WHERE JEZ_IDJEU = @v_jez_idjeu
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

