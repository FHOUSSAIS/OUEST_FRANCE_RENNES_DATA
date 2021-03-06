SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_REGLE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_reg_idregle : Identifiant
--			  @v_reg_libelle : Libellé
--			  @v_reg_params : Paramètres
--			  @v_reg_memo : Commentaire
--			  @v_reg_famille : Famille
--			  @v_reg_type : Type
--			  @_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_idlibelle : Identifiant traduction libelle
--			  @v_tra_idmemo : Identifiant traduction memo
-- Descriptif		: Gestion des règles
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_REGLE]
	@v_action smallint,
	@v_reg_idregle int,
	@v_reg_libelle varchar(8000),
	@v_reg_params varchar(40),
	@v_reg_memo varchar(8000),
	@v_reg_famille tinyint,
	@v_reg_type bit,
	@v_lan_id varchar(3),
	@v_tra_idlibelle int out,
	@v_tra_idmemo int out,
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
	@v_regidregle int,
	@v_regidtraductionlibelle int,
	@v_regidtraductionmemo int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_reg_libelle, @v_tra_idlibelle out
		IF @v_error = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_reg_memo, @v_tra_idmemo out
			IF @v_error = 0
			BEGIN
				INSERT INTO REGLE (REG_IDREGLE, REG_IDTYPE, REG_IDTRADUCTIONLIBELLE, REG_PARAMS, REG_IDTRADUCTIONMEMO, REG_FAMILLE, REG_SYSTEME)
					SELECT (SELECT CASE SIGN(MIN(REG_IDREGLE)) WHEN -1 THEN MIN(REG_IDREGLE) - 1 ELSE -1 END FROM REGLE),					
					@v_reg_type, @v_tra_idlibelle, @v_reg_params, @v_tra_idmemo, @v_reg_famille, 0
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF (EXISTS (SELECT 1 FROM REGLE WHERE REG_IDREGLE = @v_reg_idregle AND REG_FAMILLE <> @v_reg_famille)
				AND NOT EXISTS (SELECT 1 FROM COMBINAISON_DE_REGLE WHERE CDR_IDREGLE = @v_reg_idregle))
				OR EXISTS (SELECT 1 FROM REGLE WHERE REG_IDREGLE = @v_reg_idregle AND REG_FAMILLE = @v_reg_famille)
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_reg_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idlibelle
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_reg_memo WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idmemo
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE REGLE SET REG_IDTYPE = @v_reg_type, REG_PARAMS = @v_reg_params, REG_FAMILLE = @v_reg_famille
						WHERE REG_IDREGLE = @v_reg_idregle
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM COMBINAISON_DE_REGLE WHERE CDR_IDREGLE = @v_reg_idregle)
		BEGIN
			DELETE LISTE_CONDITION WHERE 
				LCN_IDLSTCONDITION IN (SELECT ARC_IDLSTCONDITION FROM ASSOCIATION_REGLE_CONDITION WHERE ARC_IDREGLE = @v_reg_idregle)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_REGLE_CONDITION WHERE ARC_IDREGLE = @v_reg_idregle
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_REGLE_TRI WHERE ART_IDREGLE = @v_reg_idregle
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE REGLE WHERE REG_IDREGLE = @v_reg_idregle
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idlibelle out
							IF @v_error = 0
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idmemo out
								IF @v_error = 0
									SELECT @v_retour = 0
							END
						END
					END
				END
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_regle CURSOR LOCAL FOR SELECT REG_IDREGLE, REG_IDTRADUCTIONLIBELLE, REG_IDTRADUCTIONMEMO FROM REGLE WHERE REG_SYSTEME = 0
		OPEN c_regle
		FETCH NEXT FROM c_regle INTO @v_regidregle, @v_regidtraductionlibelle, @v_regidtraductionmemo
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM COMBINAISON_DE_REGLE WHERE CDR_IDREGLE = @v_regidregle)
			BEGIN
				DELETE LISTE_CONDITION WHERE 
					LCN_IDLSTCONDITION IN (SELECT ARC_IDLSTCONDITION FROM ASSOCIATION_REGLE_CONDITION WHERE ARC_IDREGLE = @v_regidregle)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ASSOCIATION_REGLE_CONDITION WHERE ARC_IDREGLE = @v_regidregle
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE ASSOCIATION_REGLE_TRI WHERE ART_IDREGLE = @v_regidregle
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE REGLE WHERE REG_IDREGLE = @v_regidregle
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_regidtraductionlibelle out
								IF @v_error = 0
									EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_regidtraductionmemo out
							END
						END
					END

				END
			END
			FETCH NEXT FROM c_regle INTO @v_regidregle, @v_regidtraductionlibelle, @v_regidtraductionmemo
		END
		CLOSE c_regle
		DEALLOCATE c_regle
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

