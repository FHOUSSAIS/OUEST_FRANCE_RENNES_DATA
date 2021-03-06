SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_COLONNE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_col_id : Identifiant
--			  @v_col_tableau : Identifiant du tableau
--			  @v_col_ordre : Ordre d'affichage
--			  @v_col_taille : Taille
--			  @v_col_fixe : Fixe
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des colonnes des vues tableaux
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_COLONNE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_col_id varchar(32),
	@v_col_tableau int,
	@v_tra_id int out,
	@v_col_ordre tinyint,
	@v_col_taille int,
	@v_col_fixe	bit,
	@v_lan_id varchar(3),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_old_col_ordre tinyint,
	@v_old_col_classement tinyint,
	@v_old_col_sens tinyint,
	@v_col_filtre bit

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_tra_id = COL_TRADUCTION FROM COLONNE WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
		IF @v_tra_id IS NULL
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_col_id, @v_tra_id out
		IF @v_error = 0
		BEGIN
			UPDATE COLONNE SET COL_VISIBLE = 1, COL_TRADUCTION = @v_tra_id, COL_ORDRE = @v_col_ordre,
				COL_CLASSEMENT = (SELECT ISNULL(MAX(COL_CLASSEMENT), 0) + 1 FROM COLONNE WHERE COL_TABLEAU = @v_col_tableau),
				COL_SENS = 0 WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE COLONNE SET COL_ORDRE = COL_ORDRE + 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_col_tableau
					AND COL_ORDRE >= @v_col_ordre AND COL_VISIBLE = 1
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			SELECT @v_old_col_ordre = COL_ORDRE FROM COLONNE WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
			IF @v_col_ordre < @v_old_col_ordre
			BEGIN
				UPDATE COLONNE SET COL_ORDRE = COL_ORDRE + 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_col_tableau
					AND COL_ORDRE >= @v_col_ordre AND COL_ORDRE < @v_old_col_ordre AND COL_VISIBLE = 1
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_col_ordre > @v_old_col_ordre
			BEGIN
				UPDATE COLONNE SET COL_ORDRE = COL_ORDRE - 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_col_tableau
					AND COL_ORDRE > @v_old_col_ordre AND COL_ORDRE <= @v_col_ordre AND COL_VISIBLE = 1
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE COLONNE SET COL_ORDRE = @v_col_ordre WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			SELECT @v_old_col_classement = COL_CLASSEMENT, @v_old_col_sens = COL_SENS FROM COLONNE WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
			IF @v_old_col_classement = 1
			BEGIN
				IF @v_old_col_sens = 0
					UPDATE COLONNE SET COL_SENS = 1 WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
				ELSE
					UPDATE COLONNE SET COL_SENS = 0 WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
			BEGIN
				UPDATE COLONNE SET COL_CLASSEMENT = COL_CLASSEMENT + 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_col_tableau
					AND COL_CLASSEMENT < @v_old_col_classement AND COL_VISIBLE = 1
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE COLONNE SET COL_CLASSEMENT = 1 WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			UPDATE COLONNE SET COL_TAILLE = @v_col_taille WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE COLONNE SET COL_FIXE = @v_col_fixe WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		SELECT @v_old_col_classement = COL_CLASSEMENT,
			@v_col_filtre = CASE WHEN EXISTS (SELECT 1 FROM FILTRE WHERE FIL_ID = @v_col_id AND FIL_TABLEAU = @v_col_tableau) THEN 1 ELSE 0 END
			FROM COLONNE WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
		IF @v_col_filtre = 1
			UPDATE COLONNE SET COL_VISIBLE = 0, COL_ORDRE = NULL, COL_CLASSEMENT = NULL, COL_SENS = NULL
				WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
		ELSE
			UPDATE COLONNE SET COL_VISIBLE = 0, COL_TRADUCTION = NULL, COL_ORDRE = NULL, COL_CLASSEMENT = NULL, COL_SENS = NULL
				WHERE COL_ID = @v_col_id AND COL_TABLEAU = @v_col_tableau
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE COLONNE SET COL_ORDRE = COL_ORDRE - 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_col_tableau
				AND COL_ORDRE > @v_col_ordre AND COL_VISIBLE = 1
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE COLONNE SET COL_CLASSEMENT = COL_CLASSEMENT - 1 WHERE COL_ID <> @v_col_id AND COL_TABLEAU = @v_col_tableau
					AND COL_CLASSEMENT > @v_old_col_classement AND COL_VISIBLE = 1
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_COLONNE = @v_col_id AND ACU_TABLEAU = @v_col_tableau
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE ASSOCIATION_COLONNE_GROUPE WHERE ACG_COLONNE = @v_col_id AND ACG_TABLEAU = @v_col_tableau
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF @v_col_filtre = 0
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
								IF @v_error = 0
									SELECT @v_retour = 0
							END
							ELSE
								SELECT @v_retour = 0
						END
					END
				END
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

