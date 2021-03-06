SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_JEUREGLE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_jer_idjeu : Identifiant
--			  @v_jer_libelle : Libelle
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des jeux de règles
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_JEUREGLE]
	@v_action smallint,
	@v_jer_idjeu int,
	@v_jer_libelle varchar(8000),
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
	@v_error int,
	@v_jeridjeu int,
	@v_jeridtraduction int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_jer_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			INSERT INTO JEU_REGLE (JER_IDJEU, JER_IDTRADUCTION, JER_SYSTEME) SELECT (SELECT CASE SIGN(MIN(JER_IDJEU)) WHEN -1 THEN MIN(JER_IDJEU) - 1 ELSE -1 END FROM JEU_REGLE),
				@v_tra_id, 0
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE LIBELLE SET LIB_LIBELLE = @v_jer_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM MODE_EXPLOITATION WHERE MOD_IDJEUREGLE = @v_jer_idjeu)
				UNION (SELECT 1 FROM COMBINAISON WHERE COB_IDJEU = @v_jer_idjeu))
		BEGIN
			DELETE JEU_REGLE WHERE JER_IDJEU = @v_jer_idjeu
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_jeu_regle CURSOR LOCAL FOR SELECT JER_IDJEU, JER_IDTRADUCTION FROM JEU_REGLE FOR UPDATE
		OPEN c_jeu_regle
		FETCH NEXT FROM c_jeu_regle INTO @v_jeridjeu, @v_jeridtraduction
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS ((SELECT 1 FROM MODE_EXPLOITATION WHERE MOD_IDJEUREGLE = @v_jeridjeu)
					UNION (SELECT 1 FROM COMBINAISON WHERE COB_IDJEU = @v_jeridjeu))
			BEGIN
				DELETE JEU_REGLE WHERE CURRENT OF c_jeu_regle
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_jeridtraduction out
			END
			FETCH NEXT FROM c_jeu_regle INTO @v_jeridjeu, @v_jeridtraduction
		END
		CLOSE c_jeu_regle
		DEALLOCATE c_jeu_regle
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

